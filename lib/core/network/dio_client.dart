// lib/core/network/dio_client.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/citizen_login_screen.dart';
import '../constants/api_endpoints.dart';
import '../constants/nav_keys.dart';
import '../services/auth_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await AuthStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Token $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        String userFriendlyMessage = 'خطای نامشخص در ارتباط با سامانه رخ داد.';

        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError) {
          userFriendlyMessage = 'خطا در برقراری ارتباط با اینترنت یا سرور اکو.';
        } else if (error.response != null) {
          final statusCode = error.response?.statusCode;
          final dynamic data = error.response?.data;

          // استخراج پیام خطای بک‌اند جنگو
          if (data is Map && data.containsKey('detail')) {
            userFriendlyMessage = data['detail'].toString();
          }

          // مدیریت انقضا یا عدم وجود نشست (۴۰۱)
          if (statusCode == 401) {
            await AuthStorage.clearAuthData();

            final currentContext = rootNavigatorKey.currentContext;
            if (currentContext != null) {
              rootNavigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CitizenLoginScreen()),
                (route) => false,
              );

              ScaffoldMessenger.of(currentContext).showSnackBar(
                const SnackBar(
                  content: Text(
                    'نشست کاربری شما پایان یافته است. لطفاً مجدداً وارد شوید.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }

        return handler.next(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: userFriendlyMessage,
          ),
        );
      },
    ),
  );

  return dio;
});
