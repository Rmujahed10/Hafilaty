import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bluetooth_serial_android/bluetooth_serial_android.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart'; // Added import

class ObdScannerService {
  final String busId;
  String _dataBuffer = '';
  Timer? _pollingTimer;
  bool _isConnected = false;

  ObdScannerService({required this.busId});

  Future<bool> autoConnect() async {
    try {
      debugPrint('🔵 Requesting Bluetooth permissions explicitly...');
      
      // Request Bluetooth permissions explicitly using permission_handler
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();

      if (statuses[Permission.bluetoothConnect] != PermissionStatus.granted) {
        debugPrint('❌ BLUETOOTH_CONNECT permission denied');
        return false;
      }

      debugPrint('🔎 Searching paired devices for OBD2...');
      final List<Map<String, dynamic>> paired =
          await FlutterBluetoothSerial.getPairedDevices();

      Map<String, dynamic>? obdDevice;
      for (final device in paired) {
        final name = (device['name'] ?? '').toString();
        debugPrint('📱 Paired: $name (${device['address']})');
        if (name.contains('OBD') ||
            name.contains('Edasion') ||
            name.contains('ELM') ||
            name.contains('OBDII') ||
            name.contains('obd')) {
          obdDevice = device;
          break;
        }
      }

      if (obdDevice == null) {
        debugPrint('❌ No OBD2 device found in paired devices.');
        debugPrint('👉 Pair the Edasion OBD2 in Android Bluetooth settings first.');
        return false;
      }

      debugPrint('🔗 Connecting to: ${obdDevice['name']} (${obdDevice['address']})');

      // Standard SPP UUID used by all ELM327/OBD2 devices
      final bool connected = await FlutterBluetoothSerial.connect(
        obdDevice['address'],
        uuid: '00001101-0000-1000-8000-00805F9B34FB',
        timeoutMs: 5000,
      );

      if (!connected) {
        debugPrint('❌ Connection failed.');
        return false;
      }

      _isConnected = true;
      debugPrint('✅ Connected to OBD2 via Classic Bluetooth SPP!');

      await _initializeElm327();
      return true;
    } catch (e) {
      debugPrint('❌ autoConnect error: $e');
      return false;
    }
  }

  Future<void> _initializeElm327() async {
    debugPrint('⚙️ Initializing ELM327...');
    await _sendCommand('ATZ\r');
    await Future.delayed(const Duration(seconds: 1));
    await _sendCommand('ATE0\r');  // Echo off
    await _sendCommand('ATL0\r');  // Linefeeds off
    await _sendCommand('ATS0\r');  // Spaces off
    await _sendCommand('ATSP0\r'); // Auto protocol
    debugPrint('✅ ELM327 initialized.');
  }

  void startPolling() {
    debugPrint('🚀 Starting OBD2 polling every 15 seconds...');
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!_isConnected) {
        debugPrint('📡 OBD disconnected, stopping polling.');
        stopPolling();
        return;
      }
      await _readAndPushData();
    });
  }

  Future<void> _readAndPushData() async {
    try {
      final fuelResponse = await _sendCommandAndWait('012F\r');
      final int fuelLevel = _parseFuelLevel(fuelResponse);

      final voltageResponse = await _sendCommandAndWait('ATRV\r');
      final int batteryPercent = _parseBatteryVoltage(voltageResponse);

      final distanceResponse = await _sendCommandAndWait('0131\r');
      final int distanceTraveled = _parseDistance(distanceResponse);

      await FirebaseFirestore.instance
          .collection('Buses')
          .doc(busId)
          .set({
            'fuelLevel': fuelLevel,
            'batteryLevel': batteryPercent,
            'mileage': distanceTraveled,
            'engineOil': 'متبقي 1756 كم',
            'obdLastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      debugPrint('📶 Pushed: Fuel $fuelLevel%, Battery $batteryPercent%, Dist $distanceTraveled km');
    } catch (e) {
      debugPrint('⚠️ OBD read/push error: $e');
    }
  }

  Future<void> _sendCommand(String command) async {
    try {
      await FlutterBluetoothSerial.write(command);
    } catch (e) {
      debugPrint('⚠️ Send error: $e');
    }
  }

  Future<String> _sendCommandAndWait(String command) async {
    _dataBuffer = '';
    await _sendCommand(command);

    // Poll read() until we get the '>' prompt or timeout
    int attempts = 0;
    while (!_dataBuffer.contains('>') && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 200));
      final chunk = await FlutterBluetoothSerial.read();
      if (chunk != null) _dataBuffer += chunk;
      attempts++;
    }

    return _dataBuffer.replaceAll('>', '').trim();
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _isConnected = false;
    debugPrint('🛑 OBD stopped.');
  }

  /* --- Parsers --- */

  int _parseFuelLevel(String hex) {
    hex = hex.replaceAll(' ', '').toUpperCase();
    if (hex.contains('412F')) {
      int start = hex.indexOf('412F') + 4;
      if (hex.length >= start + 2) {
        return ((int.parse(hex.substring(start, start + 2), radix: 16) * 100) / 255).round();
      }
    }
    return 0;
  }

  int _parseBatteryVoltage(String response) {
    final match = RegExp(r'(\d+\.\d+)').firstMatch(response);
    if (match != null) {
      double voltage = double.parse(match.group(1)!);
      return ((voltage - 11.8) / (12.6 - 11.8) * 100).clamp(0, 100).round();
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