// lib/features/catalog/presentation/categories_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../data/category_model.dart';

final wasteCategoriesProvider = FutureProvider<List<WasteCategory>>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/categories/');
  final List data = response.data;
  return data.map((item) => WasteCategory.fromJson(item)).toList();
});
