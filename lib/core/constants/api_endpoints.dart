// lib/core/constants/api_endpoints.dart

class ApiEndpoints {
  static const String baseUrl = 'https://eco.ariobonyantoos.com/api/';
  static const String wsBaseUrl = 'wss://eco.ariobonyantoos.com/ws';

  // اندپوینت‌های عمومی و شهروند
  static const String categories = '$baseUrl/categories/';
  static const String citizenRequests = '$baseUrl/citizen/requests/';

  // روت وب‌سوکت پایش زنده سفر
  static String orderTrackingWs(int orderId) =>
      '$wsBaseUrl/orders/$orderId/track/';
}
