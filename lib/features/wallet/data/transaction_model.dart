// lib/features/wallet/data/transaction_model.dart

class TransactionModel {
  final int id;
  final int? wasteRequestId;
  final String transactionType;
  final String transactionTypeDisplay;
  final double amount;
  final double balanceAfter;
  final String status;
  final String statusDisplay;
  final String trackingCode;
  final String description;
  final String createdAt;

  TransactionModel({
    required this.id,
    this.wasteRequestId,
    required this.transactionType,
    required this.transactionTypeDisplay,
    required this.amount,
    required this.balanceAfter,
    required this.status,
    required this.statusDisplay,
    required this.trackingCode,
    required this.description,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int,
      wasteRequestId: json['waste_request'] as int?,
      transactionType: json['transaction_type'] as String? ?? '',
      transactionTypeDisplay: json['transaction_type_display'] as String? ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      balanceAfter:
          double.tryParse(json['balance_after']?.toString() ?? '0') ?? 0.0,
      status: json['status'] as String? ?? 'SUCCESS',
      statusDisplay: json['status_display'] as String? ?? '',
      trackingCode: json['tracking_code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  bool get isDeposit => amount > 0;
}
