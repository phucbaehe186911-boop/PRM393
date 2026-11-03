import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../services/location_service.dart';
import '../../viewmodels/court_viewmodel.dart';

/// Màn hình bản đồ hiển thị sân thể thao với markers
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _loadingLocation = true;
  bool _permissionDenied = false;

  // Hà Nội làm điểm khởi đầu
  static const _defaultPosition = LatLng(21.028, 105.804);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final pos = await LocationService().getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = pos;
        _loadingLocation = false;
        _permissionDenied = pos == null;
      });
      if (pos != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
        );
      }
    }
  }

  Set<Marker> _buildMarkers(CourtViewModel vm) {
    final markers = <Marker>{};

    // Marker cho từng sân
    for (final court in vm.courts) {
      markers.add(
        Marker(
          markerId: MarkerId(court.id.toString()),
          position: LatLng(court.lat, court.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: court.name,
            snippet:
                'Từ ${_priceShort(court.pricePerHour)}k/giờ • ${court.typeLabel}',
            onTap: () => context.push('/court/${court.id}'),
          ),
        ),
      );
    }

    // Marker vị trí người dùng
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CourtViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        title: const Text(
          AppStrings.mapTitle,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        actions: [
          if (_currentPosition != null)
            IconButton(
              icon: const Icon(Icons.my_location,
                  color: AppColors.primary, size: 20),
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_currentPosition!.latitude,
                        _currentPosition!.longitude),
                    14,
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_permissionDenied)
            Container(
              padding: const EdgeInsets.all(10),
              color: AppColors.warning.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.location_off,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      AppStrings.locationPermissionDenied,
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _loadingLocation = true;
                        _permissionDenied = false;
                      });
                      _initLocation();
                    },
                    child: const Text('Thử lại',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loadingLocation
                ? const Center(
                    child: CircularProgressIndicator.adaptive(
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  )
                : GoogleMap(
                    onMapCreated: (ctrl) => _mapController = ctrl,
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition != null
                          ? LatLng(_currentPosition!.latitude,
                              _currentPosition!.longitude)
                          : _defaultPosition,
                      zoom: 12,
                    ),
                    markers: _buildMarkers(vm),
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                  ),
          ),
        ],
      ),
    );
  }

  String _priceShort(double price) {
    return (price / 1000).toStringAsFixed(0);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
