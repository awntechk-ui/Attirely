
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../API_Routes/location_api_routes.dart';

class LocationPickerPage extends StatefulWidget {
  final bool returnLocationOnly;

  const LocationPickerPage({
    super.key,
    this.returnLocationOnly = false,
  });

  @override
  State<LocationPickerPage> createState() =>
      _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  GoogleMapController? _mapController;

  LatLng _selectedLocation = const LatLng(15.8281, 78.0373);

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<Position?> _getPosition() async {
    final serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Please enable your device location service.',
      );
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. '
            'Enable it in app settings.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    );
  }

  Future<void> _loadCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final position = await _getPosition();

      if (position != null) {
        _selectedLocation = LatLng(
          position.latitude,
          position.longitude,
        );

        await _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            _selectedLocation,
            16,
          ),
        );
      }
    } catch (e) {
      _error = e.toString().replaceFirst(
        'Exception: ',
        '',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveLocation() async {
    if (_saving) return;

    // Address selection mode:
    // Return coordinates without saving account-level location.
    if (widget.returnLocationOnly) {
      Navigator.of(context).pop(_selectedLocation);
      return;
    }

    // First-time account location setup mode.
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await LocationApiRoutes.saveLocation(
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.returnLocationOnly
              ? 'Choose Address Location'
              : 'Choose Your Location',
        ),
        backgroundColor: const Color(0xFF800020),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 16,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;

                    if (!_loading) {
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          _selectedLocation,
                          16,
                        ),
                      );
                    }
                  },
                  onCameraMove: (position) {
                    _selectedLocation = position.target;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                ),

                const IgnorePointer(
                  child: Icon(
                    Icons.location_pin,
                    color: Color(0xFF800020),
                    size: 48,
                  ),
                ),

                if (_loading)
                  const Positioned(
                    top: 16,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Getting your current location...',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  right: 16,
                  bottom: 20,
                  child: FloatingActionButton(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF800020),
                    onPressed:
                    _loading ? null : _loadCurrentLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                0,
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Move the map until the pin is at your preferred location.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 14),

                ElevatedButton(
                  onPressed: _saving || _loading
                      ? null
                      : _saveLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF800020),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Confirm location'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
