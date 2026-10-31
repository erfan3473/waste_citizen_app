// lib/features/order/presentation/map_picker_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

import 'package:waste_citizen_app/core/network/dio_client.dart';
import 'package:waste_citizen_app/features/tracking/presentation/tracking_screen.dart';
import '../../transactions/presentation/transactions_history_screen.dart';
import 'order_state.dart';
import 'widgets/schedule_picker_sheet.dart';

class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({super.key});

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fullAddressController = TextEditingController();

  bool _isMoving = false;
  bool _isLocating = false;
  bool _isSearching = false;
  bool _isReverseGeocoding = false;

  List _searchResults = [];
  final Dio _geoDio = Dio();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialLoc = ref.read(selectedLocationProvider);
      _reverseGeocode(initialLoc);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _fullAddressController.dispose();
    super.dispose();
  }

  /// استخراج خودکار آدرس کامل از مختصات پین‌شده روی نقشه
  Future<void> _reverseGeocode(LatLng point) async {
    if (!mounted) return;
    setState(() => _isReverseGeocoding = true);

    try {
      final response = await _geoDio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': point.latitude,
          'lon': point.longitude,
          'format': 'json',
          'accept-language': 'fa',
        },
        options: Options(
          headers: {'User-Agent': 'com.ariobonyantoos.waste_citizen_app'},
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final address = response.data['address'];
        if (address != null && mounted) {
          final city =
              address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              address['state'] ??
              '';

          final road = address['road'] ?? address['pedestrian'] ?? '';
          final suburb =
              address['suburb'] ??
              address['neighbourhood'] ??
              address['city_district'] ??
              '';

          final parts = [
            city,
            suburb,
            road,
          ].where((p) => p.toString().trim().isNotEmpty).toList();

          setState(() {
            _fullAddressController.text = parts.isNotEmpty
                ? parts.join('، ')
                : (address['display_name'] ?? '');
          });
        }
      }
    } catch (_) {
      // در صورت کندی شبکه، فیلد توسط کاربر به صورت دستی تکمیل می‌شود
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  /// جستجوی آدرس و معابر با هندلینگ نتیجه خالی
  Future<void> _searchAddress(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final response = await _geoDio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': trimmed,
          'format': 'json',
          'accept-language': 'fa',
          'countrycodes': 'ir',
          'limit': 5,
        },
        options: Options(
          headers: {'User-Agent': 'com.ariobonyantoos.waste_citizen_app'},
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );

      if (response.statusCode == 200 && response.data is Iterable && mounted) {
        final rawList = response.data as Iterable;
        final results = rawList
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        setState(() {
          _searchResults = results;
        });

        if (results.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'موقعیت یا آدرسی با این عنوان یافت نشد. لطفاً نام دقیق‌تری وارد کنید.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _searchResults = []);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در برقراری ارتباط با سرور جستجوی آدرس.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  /// انتقال دوربین نقشه به نقطه انتخاب‌شده از نتایج جستجو
  void _selectSearchResult(Map<String, dynamic> item) {
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lon = double.tryParse(item['lon']?.toString() ?? '');

    if (lat != null && lon != null) {
      final target = LatLng(lat, lon);
      _mapController.move(target, 16.5);
      ref.read(selectedLocationProvider.notifier).state = target;

      setState(() {
        _searchResults = [];
        _searchController.clear();
      });
      FocusScope.of(context).unfocus();

      _reverseGeocode(target);
    }
  }

  /// دریافت موقعیت زنده GPS سخت‌افزاری دیوایس با تایم‌اوت و خطای فارسی
  Future<void> _getCurrentLocationAndAddress() async {
    setState(() => _isLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'مکان‌یاب (GPS) گوشی خاموش است. لطفاً آن را روشن فرمایید.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('مجوز دسترسی به موقعیت مکانی صادر نشد.'),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'دسترسی موقعیت مکانی مسدود است؛ لطفاً از تنظیمات گوشی دسترسی را فعال فرمایید.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 112),
      );

      final userLatLng = LatLng(position.latitude, position.longitude);
      _mapController.move(userLatLng, 16.5);
      ref.read(selectedLocationProvider.notifier).state = userLatLng;

      await _reverseGeocode(userLatLng);
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'زمان دریافت سیگنال GPS به پایان رسید. لطفاً در محیط باز بررسی کنید.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در دریافت مختصات مکانی: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// باز شدن باتم‌شیت بررسی و ویرایش نشانی تجمیع‌شده قبل از انتخاب زمان
  Future<bool?> _showAddressDetailsSheet() {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'تأیید نشانی تحویل پسماند',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'نشانی کامل بر اساس نقطه انتخابی تنظیم شده است؛ در صورت نیاز پلاک و واحد را در ادامه بنویسید:',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                // فیلد تجمیع‌شده و یکپارچه نشانی کامل
                TextField(
                  controller: _fullAddressController,
                  maxLines: 3,
                  minLines: 2,
                  decoration: InputDecoration(
                    labelText: 'نشانی دقیق و کامل (شهر، معبر، پلاک، واحد)',
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                      size: 22,
                      color: Color(0xFF2E7D32),
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // دکمه مرحله بعد
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (_fullAddressController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('لطفاً نشانی را تکمیل کنید.'),
                          ),
                        );
                        return;
                      }
                      Navigator.of(ctx).pop(true);
                    },
                    child: const Text(
                      'تأیید نشانی و انتخاب زمان مراجعه',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = ref.watch(selectedLocationProvider);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;
    final bottomOffset = bottomSafePadding > 0 ? bottomSafePadding + 16 : 28.0;

    return Scaffold(
      body: Stack(
        children: [
          // ۱. نقشه تمام‌صفحه
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: selectedLocation,
                initialZoom: 15.0,
                minZoom: 5.0,
                maxZoom: 18.0,
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture && camera.center != null) {
                    ref.read(selectedLocationProvider.notifier).state =
                        camera.center!;
                  }
                },
                onMapEvent: (event) {
                  if (event is MapEventMoveStart) {
                    setState(() => _isMoving = true);
                  } else if (event is MapEventMoveEnd) {
                    setState(() => _isMoving = false);
                    _reverseGeocode(event.camera.center);
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
          ),

          // ۲. پین مرکزی سبز رنگ با شفافیت ملایم (تمیز و بدون خط اضافه)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 44.0),
              child: Icon(
                Icons.location_on_rounded,
                size: 50,
                color: const Color(0xFF2E7D32).withOpacity(0.82),
              ),
            ),
          ),

          // ۳. دکمه بازگشت و منوی بالای صفحه
          Positioned(
            top: topPadding + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 19,
                      color: Colors.black87,
                    ),
                    tooltip: 'بازگشت',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF2E7D32),
                      size: 22,
                    ),
                    tooltip: 'تراکنش‌ها و سوابق',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: (value) {
                      if (value == 'wallet') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const TransactionsHistoryScreen(initialTab: 0),
                          ),
                        );
                      } else if (value == 'orders') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const TransactionsHistoryScreen(initialTab: 1),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'wallet',
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.green,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text('تراکنش‌های کیف پول'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'orders',
                        child: Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              color: Colors.blue,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text('سوابق سفارش‌ها'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ۴. دکمه موقعیت‌یاب سخت‌افزاری GPS
          Positioned(
            right: 16,
            bottom: bottomOffset + 124,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              tooltip: 'موقعیت فعلی من',
              onPressed: _isLocating ? null : _getCurrentLocationAndAddress,
              child: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2E7D32),
                      ),
                    )
                  : const Icon(Icons.my_location, color: Color(0xFF2E7D32)),
            ),
          ),

          // ۵. بخش پایینی: سرچ‌بار متنی با دکمه اختصاصی + دکمه تأیید موقعیت با فاصله استاندارد
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomOffset,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // لیست نتایج جستجو
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 190),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF2E7D32),
                            size: 20,
                          ),
                          title: Text(
                            item['display_name'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                          onTap: () => _selectSearchResult(item),
                        );
                      },
                    ),
                  ),

                // ردیف کادر جستجو و دکمه اختصاصی سرچ
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: _searchAddress,
                          decoration: InputDecoration(
                            hintText: 'جستجوی نام خیابان، محله یا آدرس...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                            prefixIcon: const Icon(
                              Icons.location_searching,
                              color: Color(0xFF2E7D32),
                              size: 20,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchResults = []);
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // دکمه اختصاصی سرچ در صفحه
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: _isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search, color: Colors.white),
                        tooltip: 'جستجو',
                        onPressed: _isSearching
                            ? null
                            : () => _searchAddress(_searchController.text),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // دکمه تأیید موقعیت مکانی با حاشیه مناسب از پایین
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _isReverseGeocoding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline, size: 22),
                    label: Text(
                      _isMoving
                          ? 'در حال تنظیم نقطه...'
                          : 'تأیید این موقعیت مکانی',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _isMoving
                        ? null
                        : () async {
                            final addressConfirmed =
                                await _showAddressDetailsSheet();
                            if (addressConfirmed != true) return;

                            if (!context.mounted) return;
                            final scheduleResult =
                                await showModalBottomSheet<ScheduleResult>(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                  ),
                                  builder: (_) => const SchedulePickerSheet(),
                                );

                            if (scheduleResult == null) return;

                            final combinedAddress = _fullAddressController.text
                                .trim();

                            final requestPayload = {
                              'latitude': selectedLocation.latitude,
                              'longitude': selectedLocation.longitude,
                              'address_text': combinedAddress,
                              'plaque': '',
                              'unit': '',
                              'scheduled_date': scheduleResult.gregorianDate,
                              'scheduled_time_slot': scheduleResult.timeSlot,
                              'items': [],
                            };

                            if (context.mounted) {
                              _submitOrder(context, ref, requestPayload);
                            }
                          },
                  ),
                ),
              ],
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('citizen/requests/', data: payload);

      if (context.mounted) Navigator.of(context).pop();

      final orderId = response.data['id'];

      ref.read(orderDraftProvider.notifier).clear();
      _fullAddressController.clear();

      if (context.mounted) {
        Navigator.of(context).push(
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
