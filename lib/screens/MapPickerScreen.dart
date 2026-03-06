// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _currentPosition;
  LatLng? _draggedPosition;
  bool _isLoading = true;
  GoogleMapController? _mapController;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  /// 1. Gets user location and enables the "Blue Dot"
  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError("يرجى تفعيل خدمات الموقع (GPS)");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError("تم رفض إذن الوصول للموقع");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError("إذن الموقع مرفوض تماماً، يرجى تفعيله من إعدادات الهاتف");
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _draggedPosition = _currentPosition;
        _isLoading = false;
      });
      // Move camera to user's current location immediately
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 17.5),
      );
    }
  }

  /// 2. Search logic using Google Places API
  Future<void> _searchPlace(String input) async {
    if (input.isEmpty) return;

    const String apiKey = "AIzaSyARnCLe7aF1DOBNN9M7ahz9rTCMOgeO7kc";
    final String url =
        "https://maps.googleapis.com/maps/api/place/textsearch/json?query=$input&key=$apiKey";

    try {
      var response = await http.get(Uri.parse(url));
      var json = jsonDecode(response.body);

      if (json['status'] == 'OK') {
        var loc = json['results'][0]['geometry']['location'];
        var target = LatLng(loc['lat'], loc['lng']);
        
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(target, 16.5),
        );
        
        // FIXED: Guarding the async gap
        if (!mounted) return;
        FocusScope.of(context).unfocus();
      } else {
        _showError("لم يتم العثور على الموقع، حاول كتابة اسم الحي");
      }
    } catch (e) {
      _showError("حدث خطأ في الاتصال");
    }
  }

  void _recenterMap() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 17.5),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          "تحديد موقع المنزل",
          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0D1B36),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D1B36)))
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 17.5,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onCameraMove: (pos) {
                    _draggedPosition = pos.target;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  padding: const EdgeInsets.only(bottom: 100), // Avoid UI overlap
                ),

                // --- SEARCH BAR ---
                Positioned(
                  top: 15, left: 15, right: 15,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textDirection: TextDirection.rtl,
                      onSubmitted: _searchPlace,
                      decoration: InputDecoration(
                        hintText: "بحث عن حي أو شارع...",
                        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.search, color: Color(0xFF0D1B36)),
                          onPressed: () => _searchPlace(_searchController.text),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      ),
                    ),
                  ),
                ),

                // --- CENTRAL SELECTOR PIN ---
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: Colors.red.shade700, size: 50),
                      Container(
                        width: 10, height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 35),
                    ],
                  ),
                ),

                // --- RECENTER BUTTON ---
                Positioned(
                  bottom: 115, right: 20,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _recenterMap,
                    child: const Icon(Icons.my_location, color: Color(0xFF0D1B36)),
                  ),
                ),

                // --- CONFIRM BUTTON ---
                Positioned(
                  bottom: 40, left: 20, right: 20,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D1B36),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context, _draggedPosition),
                    child: const Text(
                      "تأكيد هذا الموقع",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}