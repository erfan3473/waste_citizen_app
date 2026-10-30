// lib/features/order/presentation/map_picker_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:waste_citizen_app/core/network/dio_client.dart';
import 'package:waste_citizen_app/features/tracking/presentation/tracking_screen.dart';
import 'order_state.dart';

class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({super.key});

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  late final MapController _mapController;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _plaqueController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _addressController.dispose();
    _plaqueController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = ref.watch(selectedLocationProvider);
    final draftItems = ref.watch(orderDraftProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('انتخاب موقعیت تحویل پسماند'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ۱. لایه نقشه FlutterMap v6
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: selectedLocation,
              initialZoom: 15.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  ref.read(selectedLocationProvider.notifier).state =
                      camera.center!;
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveStart) {
                  setState(() => _isMoving = true);
                } else if (event is MapEventMoveEnd) {
                  setState(() => _isMoving = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ariobonyantoos.waste_citizen_app',
              ),
            ],
          ),

          // ۲. مارکر ثابت در مرکز هندسی صفحه با افکت شناور
          Center(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: _isMoving ? 48.0 : 36.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'مبدأ جمع‌آوری',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  const Icon(
                    Icons.location_on_rounded,
                    size: 44,
                    color: Color(0xFFD32F2F),
                  ),
                ],
              ),
            ),
          ),

          // ۳. سایه زیر نوک پین روی نقشه
          Center(
            child: Container(
              width: 8,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // ۴. دکمه بازگشت به موقعیت پیش‌فرض
          Positioned(
            top: 16,
            left: 16,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              onPressed: () {
                _mapController.move(const LatLng(36.2972, 59.6067), 15.0);
                ref.read(selectedLocationProvider.notifier).state =
                    const LatLng(36.2972, 59.6067);
              },
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),

          // ۵. کارت دریافت جزئیات آدرس و تأیید نهایی
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'نشانی دقیق (خیابان، کوچه)',
                        prefixIcon: Icon(Icons.edit_road),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _plaqueController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'پلاک',
                              prefixIcon: Icon(Icons.home),
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _unitController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'واحد',
                              prefixIcon: Icon(Icons.door_front_door_outlined),
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isMoving
                            ? null
                            : () {
                                if (_addressController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'لطفاً آدرس متنی را وارد کنید.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final requestPayload = {
                                  'latitude': selectedLocation.latitude,
                                  'longitude': selectedLocation.longitude,
                                  'address_text': _addressController.text
                                      .trim(),
                                  'plaque': _plaqueController.text.trim(),
                                  'unit': _unitController.text.trim(),
                                  'items': draftItems
                                      .map((e) => e.toJson())
                                      .toList(),
                                };

                                // انتقال داده‌ها به متد ثبت درخواست
                                _submitOrder(context, ref, requestPayload);
                              },
                        child: const Text(
                          'تأیید موقعیت و ثبت درخواست',
                          style: TextStyle(fontSize: 16),
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

  Future<void> _submitOrder(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> payload,
  ) async {
    // نمایش لودینگ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('citizen/requests/', data: payload);

      // بستن دیالوگ لودینگ
      if (context.mounted) Navigator.of(context).pop();

      final orderId = response.data['id'];

      // پاک کردن سبد سفارش پس از ثبت موفق
      ref.read(orderDraftProvider.notifier).clear();

      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TrackingScreen(
              orderId: orderId,
              citizenLocation: LatLng(
                payload['latitude'],
                payload['longitude'],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ثبت سفارش: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
