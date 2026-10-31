// lib/core/services/auth_storage.dart

import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _keyToken = 'citizen_auth_token';
  static const String _keyPhone = 'citizen_auth_phone';
  static const String _keyUserId = 'citizen_auth_user_id';

  /// ذخیره توکن احراز هویت و مشخصات کاربر پس از تایید OTP
  static Future<void> saveAuthData({
    required String token,
    required String phone,
    required int userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyPhone, phone);
    await prefs.setInt(_keyUserId, userId);
  }

  /// دریافت توکن برای ارسال در هدر درخواست‌ها
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// بررسی لاگین بودن کاربر
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// شماره موبایل کاربر جاری
  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhone);
  }

  /// پاک‌سازی کامل اطلاعات هنگام خروج از حساب (Logout)
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyUserId);
  }
}
