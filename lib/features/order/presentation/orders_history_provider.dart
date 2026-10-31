// lib/features/order/presentation/orders_history_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/order_history_model.dart';

final citizenOrdersHistoryProvider = FutureProvider<List<OrderHistoryModel>>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('citizen/requests/');
  final List data = response.data;
  return data.map((item) => OrderHistoryModel.fromJson(item)).toList();
});
