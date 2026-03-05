import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _currentPosition;
  LatLng? _draggedPosition;
  bool _isLoading = true;
  // Removed the unused _mapController to clear the warning

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError("يرجى تفعيل خدمات الموقع (GPS)");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError("تم رفض إذن الوصول للموقع");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _draggedPosition = _currentPosition;
      _isLoading = false;
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تحديد موقع المنزل", style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF0D1B36),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 17.5,
                  ),
                  // Logic: When moving, update the hidden coordinate
                  onCameraMove: (cameraPosition) {
                    _draggedPosition = cameraPosition.target;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),

                // FIX FOR ERRORS ON LINE 86:
                Center(
                  child: Padding(
                    // Corrected: used .only() instead of just EdgeInsets()
                    padding: const EdgeInsets.only(bottom: 35), 
                    child: Icon(
                      Icons.location_on,
                      color: Colors.red.shade700,
                      size: 50,
                    ),
                  ),
                ),

                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D1B36),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, _draggedPosition);
                    },
                    child: const Text(
                      "تأكيد هذا الموقع",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}