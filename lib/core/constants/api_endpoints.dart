// lib/core/constants/api_endpoints.dart

class ApiEndpoints {
  static const String baseUrl = 'https://eco.ariobonyantoos.com/api/';
  static const String wsBaseUrl = 'wss://eco.ariobonyantoos.com/ws';

  // اندپوینت‌های احراز هویت شهروند (OTP پیامکی)
  static const String citizenSendOtp = 'citizen/auth/send-otp/';
  static const String citizenVerifyOtp = 'citizen/auth/verify-otp/';
  static const String citizenLogout = 'citizen/auth/logout/';

  // اندپوینت‌های عمومی و سفارش شهروند
  static const String categories = 'categories/';
  static const String citizenRequests = 'citizen/requests/';
  static const String wallet = 'wallet/me/';
  static const String walletTransactions = 'wallet/transactions/';
  static const String withdrawals = 'withdrawals/';

  // روت وب‌سوکت پایش زنده سفر
  static String orderTrackingWs(int orderId) =>
      '$wsBaseUrl/orders/$orderId/track/';
}
