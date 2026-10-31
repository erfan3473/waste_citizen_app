// lib/features/tracking/presentation/tracking_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../navigation/presentation/main_navigation_screen.dart';

class TrackingScreen extends StatefulWidget {
  final int orderId;
  final LatLng citizenLocation;

  const TrackingScreen({
    super.key,
    required this.orderId,
    required this.citizenLocation,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late final MapController _mapController;
  WebSocketChannel? _channel;
  LatLng? _driverLocation;
  double _driverBearing = 0.0;
  String _orderStatus = 'در حال جستجوی نزدیک‌ترین راننده...';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final wsUrl = Uri.parse(ApiEndpoints.orderTrackingWs(widget.orderId));
    _channel = WebSocketChannel.connect(wsUrl);

    _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);

        if (data['type'] == 'connection_established') {
          setState(() {
            _orderStatus = 'متصل به مرکز - در انتظار اعزام خودرو';
          });
        } else if (data['type'] == 'driver_location') {
          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();
          final bearing = (data['bearing'] as num?)?.toDouble() ?? 0.0;

          setState(() {
            _driverLocation = LatLng(lat, lng);
            _driverBearing = bearing;
            _orderStatus = 'خودروی جمع‌آوری در مسیر شماست';
          });
        }
      },
      onError: (err) {
        setState(() => _orderStatus = 'خطای اتصال به سرور رهگیری');
      },
    );
  }

  void _handleBackNavigation() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('پیگیری سفارش #${widget.orderId}'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'بازگشت',
          onPressed: _handleBackNavigation,
        ),
      ),
      body: Stack(
        children: [
          // ۱. لایه نقشه
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.citizenLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ariobonyantoos.waste_citizen_app',
              ),
              MarkerLayer(
                markers: [
                  // مارکر موقعیت شهروند
                  Marker(
                    point: widget.citizenLocation,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.home_mini,
                      color: Colors.blue,
                      size: 44,
                    ),
                  ),

                  // مارکر موقعیت راننده با زاویه چرخش (Bearing)
                  if (_driverLocation != null)
                    Marker(
                      point: _driverLocation!,
                      width: 46,
                      height: 46,
                      child: Transform.rotate(
                        angle: _driverBearing * (3.1415926535 / 180),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.green,
                          size: 44,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ۲. پنل وضعیت بالای نقشه
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _orderStatus,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ۳. دکمه میانبر بازگشت به خانه در پایین صفحه
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2E7D32),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(
                      color: Color(0xFF2E7D32),
                      width: 1.2,
                    ),
                  ),
                ),
                icon: const Icon(Icons.home_outlined),
                label: const Text(
                  'بازگشت به منوی اصلی',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: _handleBackNavigation,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
