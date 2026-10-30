// lib/features/tracking/presentation/tracking_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/constants/api_endpoints.dart';

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
      ),
      body: Stack(
        children: [
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
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.home_mini,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),

                  // مارکر موقعیت لحظه‌ای راننده (در صورت دریافت پکت)
                  if (_driverLocation != null)
                    Marker(
                      point: _driverLocation!,
                      width: 44,
                      height: 44,
                      child: Transform.rotate(
                        angle: _driverBearing * (3.1415926535 / 180),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.green,
                          size: 40,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // پنل وضعیت بالای نقشه
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _orderStatus,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
