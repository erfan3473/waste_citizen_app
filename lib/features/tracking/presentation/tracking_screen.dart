// lib/features/tracking/presentation/tracking_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:waste_citizen_app/core/constants/api_endpoints.dart';
import 'package:waste_citizen_app/core/network/dio_client.dart';
import '../../navigation/presentation/main_navigation_screen.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  final int orderId;
  final LatLng citizenLocation;

  const TrackingScreen({
    super.key,
    required this.orderId,
    required this.citizenLocation,
  });

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  late final MapController _mapController;
  WebSocketChannel? _channel;

  LatLng? _driverLocation;
  double _driverBearing = 0.0;
  String _orderStatus = 'PENDING';
  String _statusText = 'در حال جستجوی نزدیک‌ترین ناوگان جمع‌آوری...';

  Map<String, dynamic>? _driverInfo;
  bool _isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchInitialOrderDetails();
    _connectWebSocket();
  }

  /// دریافت اولیه وضعیت و مشخصات راننده از REST API
  Future<void> _fetchInitialOrderDetails() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('citizen/requests/${widget.orderId}/');

      if (response.statusCode == 200 && response.data != null && mounted) {
        final data = response.data;
        setState(() {
          _orderStatus = data['status'] ?? 'PENDING';
          _driverInfo = data['driver'];
          _updateStatusDescription(_orderStatus);
          _isLoadingInitial = false;
        });

        if (data['latitude'] != null && data['longitude'] != null) {
          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();
          _mapController.move(LatLng(lat, lng), 15.0);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  /// اتصال به روم وب‌سوکت پایش زنده سفارش
  void _connectWebSocket() {
    final wsUrl = Uri.parse(ApiEndpoints.orderTrackingWs(widget.orderId));
    _channel = WebSocketChannel.connect(wsUrl);

    _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        final type = data['type'];

        if (type == 'connection_established') {
          if (data['driver'] != null && mounted) {
            setState(() {
              _driverInfo = data['driver'];
            });
          }
          if (data['order_status'] != null && mounted) {
            setState(() {
              _orderStatus = data['order_status'];
              _updateStatusDescription(_orderStatus);
            });
          }
        } else if (type == 'driver_assigned') {
          if (mounted) {
            setState(() {
              _driverInfo = data['driver'];
              _orderStatus = data['status'] ?? 'ACCEPTED';
              _updateStatusDescription(_orderStatus);
            });
          }
        } else if (type == 'driver_location') {
          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();
          final bearing = (data['bearing'] as num?)?.toDouble() ?? 0.0;

          if (mounted) {
            setState(() {
              _driverLocation = LatLng(lat, lng);
              _driverBearing = bearing;
              if (_orderStatus == 'ACCEPTED') {
                _orderStatus = 'ON_THE_WAY';
                _statusText = 'ناوگان در مسیر مراجعه به موقعیت شماست';
              }
            });
          }
        } else if (type == 'status_update') {
          final newStatus = data['status'] as String? ?? '';
          if (mounted) {
            setState(() {
              _orderStatus = newStatus;
              _updateStatusDescription(newStatus);
            });
          }
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _statusText = 'در حال تلاش برای برقراری مجدد ارتباط با سرور...';
          });
        }
      },
    );
  }

  void _updateStatusDescription(String status) {
    switch (status) {
      case 'PENDING':
      case 'SCHEDULED':
        _statusText = 'در انتظار تخصیص به نزدیک‌ترین ناوگان جمع‌آوری';
        break;
      case 'ACCEPTED':
        _statusText = 'سفارش توسط راننده پذیرفته شد؛ آماده‌باش ناوگان';
        break;
      case 'ON_THE_WAY':
        _statusText = 'خودروی جمع‌آوری در مسیر مراجعه به شماست';
        break;
      case 'ARRIVED':
        _statusText = 'خودروی ناوگان در محل حضور دارد';
        break;
      case 'COLLECTED':
        _statusText = 'پسماندها توزین و تسویه حساب با موفقیت انجام شد';
        break;
      default:
        _statusText = 'وضعیت سفارش: $status';
    }
  }

  /// برقراری تماس با راننده با استفاده از متد استاندارد launchUrl
  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(' ', '').trim();
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      final success = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'امکان شماره‌گیری خودکار برای $cleanNumber وجود ندارد',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در باز کردن شماره‌گیر تلفن')),
        );
      }
    }
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
    final vehicle = _driverInfo != null
        ? _driverInfo!['vehicle'] as Map<String, dynamic>?
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('پیگیری درخواست #${widget.orderId}'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'بازگشت',
          onPressed: _handleBackNavigation,
        ),
      ),
      body: Stack(
        children: [
          // ۱. لایه نقشه ایرانی پایدار (map.ir)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.citizenLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://map.ir/shiveh/xyz/1.0.0/Shiveh:Shiveh@EPSG:3857@png/{z}/{x}/{y}.png',
                tileProvider: NetworkTileProvider(
                  headers: {
                    'x-api-key':
                        'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6ImI4NzlhYmM3YzQ5MGUwOGEwMzM5MzgxZjIyZTRlNGM5ZDg4MGRkYjY0YzYwMDJmN2I1ZDNkYjBmMGVlYzhhMmYyZjU3ZTlmMWI0MDA2ZjNkIn0.eyJhdWQiOiIzODYxNyIsImp0aSI6ImI4NzlhYmM3YzQ5MGUwOGEwMzM5MzgxZjIyZTRlNGM5ZDg4MGRkYjY0YzYwMDJmN2I1ZDNkYjBmMGVlYzhhMmYyZjU3ZTlmMWI0MDA2ZjNkIiwiaWF0IjoxNzc1NzQzNDIxLCJuYmYiOjE3NzU3NDM0MjEsImV4cCI6MTc3ODMzNTQyMSwic3ViIjoiIiwic2NvcGVzIjpbImJhc2ljIl19.TfxCB8bvzvnGpmheKbNmALdGUk38fnYdojQmpaHbFm26ltPCY2AWpkruKoP1rzWrMh3jLnOl_U-QH8x2hZWO6l3ufk0u0bMJwc3IxsVgOSUycM1WNdH0mebNH92MvE0DFD6Iod4oPW6tzCwMBkMXI2LIycDzeT0sRBVTcxw7XDvaeofw2P3FhuiJBWFDqFauc3fecInOF6vK3cuI1t0yrQCPdKa2WXyb6VUG2xsexTLoW4Elayt2fVKvQdTk_ITVhkjiT6YtK_pgyYcFVAJZr2TvEzCyQZ35CRa3tDBpG6_FKcRMMNiDlMvJmeAO8P9q-ESwXXUzuvHLzjiSmijrUA',
                  },
                ),
              ),

              MarkerLayer(
                markers: [
                  // مارکر موقعیت تحویل پسماند شهروند (خانه)
                  Marker(
                    point: widget.citizenLocation,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.35),
                            blurRadius: 6,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.blue.shade700,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.home_rounded,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                  ),

                  // مارکر موقعیت خودروی ناوگان با چرخش جهت
                  if (_driverLocation != null)
                    Marker(
                      point: _driverLocation!,
                      width: 52,
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF2E7D32).withOpacity(0.2),
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Transform.rotate(
                              angle: _driverBearing * (3.1415926535 / 180),
                              child: const Icon(
                                Icons.local_shipping_rounded,
                                color: Color(0xFF2E7D32),
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ۲. نوار وضعیت سفارش در بالای صفحه
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _driverInfo != null
                            ? const Color(0xFF2E7D32)
                            : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ۳. پنل پایین: کارت مشخصات راننده و خودرو یا وضعیت انتظار
          Positioned(
            left: 16,
            right: 16,
            bottom: 22,
            child: _isLoadingInitial
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  )
                : _driverInfo != null
                ? Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // سطر مشخصات راننده و دکمه تماس
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFE8F5E9),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _driverInfo!['full_name'] ??
                                          'راننده ناوگان اکو',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _driverInfo!['phone'] ?? '',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_driverInfo!['phone'] != null)
                                IconButton.filled(
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(
                                    Icons.phone_in_talk_rounded,
                                    size: 20,
                                  ),
                                  tooltip: 'تماس با راننده',
                                  onPressed: () =>
                                      _makePhoneCall(_driverInfo!['phone']),
                                ),
                            ],
                          ),
                          const Divider(height: 20),

                          // سطر مشخصات خودرو و پلاک انتظامی
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.local_shipping_outlined,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    vehicle != null
                                        ? '${vehicle['vehicle_type_display'] ?? ""} ${vehicle['model_name'] ?? ""}'
                                        : 'خودروی تفکیک ناوگان',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              if (vehicle != null &&
                                  vehicle['plate_number'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    'پلاک: ${vehicle['plate_number']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: const [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'درخواست در صف پذیرش است؛ به محض قبول مأموریت توسط ناوگان، مشخصات و موقعیت راننده نمایان خواهد شد.',
                              style: TextStyle(fontSize: 12.5, height: 1.4),
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
