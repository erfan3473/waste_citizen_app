// lib/features/order/data/order_history_model.dart

class OrderHistoryModel {
  final int id;
  final String status;
  final double latitude;
  final double longitude;
  final String addressText;
  final String? plaque;
  final String? unit;
  final String? scheduledDate;
  final String? scheduledTimeSlot;
  final double totalPrice;
  final String createdAt;

  OrderHistoryModel({
    required this.id,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.addressText,
    this.plaque,
    this.unit,
    this.scheduledDate,
    this.scheduledTimeSlot,
    required this.totalPrice,
    required this.createdAt,
  });

  factory OrderHistoryModel.fromJson(Map<String, dynamic> json) {
    return OrderHistoryModel(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'PENDING',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      addressText: json['address_text'] as String? ?? '',
      plaque: json['plaque'] as String?,
      unit: json['unit'] as String?,
      scheduledDate: json['scheduled_date'] as String?,
      scheduledTimeSlot: json['scheduled_time_slot'] as String?,
      totalPrice:
          double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  // بررسی فعال بودن سفارش جهت امکان پیگیری زنده
  bool get isActive =>
      status == 'PENDING' ||
      status == 'SCHEDULED' ||
      status == 'ACCEPTED' ||
      status == 'ON_THE_WAY' ||
      status == 'ARRIVED';

  String get statusFa {
    switch (status) {
      case 'PENDING':
        return 'در انتظار راننده';
      case 'SCHEDULED':
        return 'رزرو شده';
      case 'ACCEPTED':
        return 'پذیرفته شده';
      case 'ON_THE_WAY':
        return 'در مسیر شما';
      case 'ARRIVED':
        return 'حضور در محل';
      case 'COLLECTED':
        return 'تسویه شده';
      case 'CANCELLED':
        return 'لغو شده';
      default:
        return status;
    }
  }
}
