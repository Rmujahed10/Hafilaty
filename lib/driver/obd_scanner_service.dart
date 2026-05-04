import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ObdScannerService {
  final String busId;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;

  StreamSubscription? _lastSubscription;
  Timer? _pollingTimer;
  String _dataBuffer = '';

  ObdScannerService({required this.busId});

  /// 1. البحث والاتصال التلقائي بجهاز OBD2
  Future<bool> autoConnect() async {
    try {
      print('🔎 Starting Scan for OBD2...');

      // التأكد من أن البلوتوث يعمل
      if (await FlutterBluePlus.adapterState.first !=
          BluetoothAdapterState.on) {
        print("❌ Bluetooth is turned off.");
        return false;
      }

      // البحث عن الأجهزة القريبة
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      // الحصول على النتائج
      var results = await FlutterBluePlus.scanResults.first;
      for (ScanResult r in results) {
        String name = r.device.platformName;
        if (name.contains("OBD") ||
            name.contains("Edasion") ||
            name.contains("ELM")) {
          _device = r.device;
          break;
        }
      }

      if (_device == null) {
        print("❌ No OBD2 device found nearby.");
        return false;
      }

      print('🔗 Connecting to: ${_device!.platformName}...');
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
        // لاحظ: لا تضع أي شيء هنا اسمه license
      );
      // اكتشاف الخدمات
      List<BluetoothService> services = await _device!.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          // خاصية الكتابة
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
          }
          // خاصية القراءة والإشعارات
          if (characteristic.properties.notify ||
              characteristic.properties.read) {
            _readCharacteristic = characteristic;
          }
        }
      }

      if (_writeCharacteristic != null && _readCharacteristic != null) {
        await _readCharacteristic!.setNotifyValue(true);

        // تنظيف أي اشتراك سابق لتجنب تداخل البيانات
        await _lastSubscription?.cancel();

        _lastSubscription = _readCharacteristic!.lastValueStream.listen((
          value,
        ) {
          _dataBuffer += ascii.decode(value);
        });

        print('✅ Connected and Configured!');
        await _initializeElm327();
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Connection Error: $e');
      return false;
    }
  }

  /// 2. تهيئة شريحة ELM327
  Future<void> _initializeElm327() async {
    await _sendCommand("ATZ\r"); // Reset
    await Future.delayed(const Duration(seconds: 1));
    await _sendCommand("ATE0\r"); // Echo Off
    await _sendCommand("ATL0\r"); // Linefeeds Off
    await _sendCommand("ATSP0\r"); // Auto Protocol
  }

  /// 3. بدء جلب البيانات بشكل دوري
  void startPolling() {
    print('🚀 Starting OBD2 Polling...');
    _pollingTimer?.cancel(); // إلغاء أي تايمر قديم
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (_device == null || !(_device!.isConnected)) {
        print("📡 Device disconnected, stopping poll.");
        stopPolling();
        return;
      }
      await _readAndPushData();
    });
  }

  /// 4. جلب البيانات وإرسالها لـ Firestore
  Future<void> _readAndPushData() async {
    try {
      String fuelResponse = await _sendCommandAndWait("012F\r");
      int fuelLevel = _parseFuelLevel(fuelResponse);

      String voltageResponse = await _sendCommandAndWait("ATRV\r");
      int batteryPercent = _parseBatteryVoltage(voltageResponse);

      String distanceResponse = await _sendCommandAndWait("0131\r");
      int distanceTraveled = _parseDistance(distanceResponse);

      await FirebaseFirestore.instance.collection('Buses').doc(busId).set({
        'fuelLevel': fuelLevel,
        'batteryLevel': batteryPercent,
        'mileage': distanceTraveled,
        'engineOil': "متبقي 1756 كم",
        'obdLastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print(
        '📶 Pushed: Fuel $fuelLevel%, Battery $batteryPercent%, Dist $distanceTraveled km',
      );
    } catch (e) {
      print('⚠️ OBD Read/Push Error: $e');
    }
  }

  /* --- أدوات التواصل --- */

  Future<void> _sendCommand(String command) async {
    if (_writeCharacteristic != null) {
      await _writeCharacteristic!.write(
        ascii.encode(command),
        withoutResponse: false,
      );
    }
  }

  Future<String> _sendCommandAndWait(String command) async {
    _dataBuffer = '';
    await _sendCommand(command);

    int attempts = 0;
    while (!_dataBuffer.contains('>') && attempts < 15) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }

    String response = _dataBuffer.replaceAll('>', '').trim();
    return response;
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _lastSubscription?.cancel();
    _device?.disconnect();
    print('🛑 OBD Stopped.');
  }

  /* --- معادلات التحليل --- */

  int _parseFuelLevel(String hex) {
    hex = hex.replaceAll(' ', '').toUpperCase();
    if (hex.contains('412F')) {
      int start = hex.indexOf('412F') + 4;
      if (hex.length >= start + 2) {
        String val = hex.substring(start, start + 2);
        return ((int.parse(val, radix: 16) * 100) / 255).round();
      }
    }
    return 0;
  }

  int _parseBatteryVoltage(String response) {
    final regExp = RegExp(r"(\d+\.\d+)");
    final match = regExp.firstMatch(response);
    if (match != null) {
      double voltage = double.parse(match.group(1)!);
      double percent = ((voltage - 11.8) / (12.6 - 11.8)) * 100;
      return percent.clamp(0, 100).round();
    }
    return 0;
  }

  int _parseDistance(String hex) {
    hex = hex.replaceAll(' ', '').toUpperCase();
    if (hex.contains('4131')) {
      int idx = hex.indexOf('4131') + 4;
      if (hex.length >= idx + 4) {
        int a = int.parse(hex.substring(idx, idx + 2), radix: 16);
        int b = int.parse(hex.substring(idx + 2, idx + 4), radix: 16);
        return (a * 256) + b;
      }
    }
    return 0;
  }
}
