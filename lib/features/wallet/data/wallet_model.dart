// lib/features/wallet/data/wallet_model.dart

class WalletModel {
  final int id;
  final String userType;
  final String userTypeDisplay;
  final double balance;
  final bool isActive;

  WalletModel({
    required this.id,
    required this.userType,
    required this.userTypeDisplay,
    required this.balance,
    required this.isActive,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as int,
      userType: json['user_type'] as String? ?? 'CITIZEN',
      userTypeDisplay: json['user_type_display'] as String? ?? '',
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
