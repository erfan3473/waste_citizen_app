// lib/features/wallet/presentation/wallet_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../data/transaction_model.dart';

final walletTransactionsProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.walletTransactions);
  final List data = response.data as List;
  return data
      .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
      .toList();
});
