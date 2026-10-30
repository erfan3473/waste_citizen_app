// lib/features/order/presentation/order_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class OrderItemDraft {
  final int categoryId;
  final String title;
  final double estimatedAmount;
  final double unitPrice;

  OrderItemDraft({
    required this.categoryId,
    required this.title,
    required this.estimatedAmount,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() => {
    'category_id': categoryId,
    'estimated_amount': estimatedAmount,
  };
}

// لوکیشن انتخاب‌شده روی نقشه
final selectedLocationProvider = StateProvider<LatLng>((ref) {
  // پیش‌فرض: مرکز مشهد (یا شهر مدنظر)
  return const LatLng(36.2972, 59.6067);
});

// سبد اقلام پسماند
class OrderDraftNotifier extends StateNotifier<List<OrderItemDraft>> {
  OrderDraftNotifier() : super([]);

  void setAmount(int categoryId, String title, double amount, double price) {
    if (amount <= 0) {
      state = state.where((item) => item.categoryId != categoryId).toList();
    } else {
      final index = state.indexWhere((item) => item.categoryId != categoryId);
      if (index >= 0) {
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == index)
              OrderItemDraft(
                categoryId: categoryId,
                title: title,
                estimatedAmount: amount,
                unitPrice: price,
              )
            else
              state[i],
        ];
      } else {
        state = [
          ...state,
          OrderItemDraft(
            categoryId: categoryId,
            title: title,
            estimatedAmount: amount,
            unitPrice: price,
          ),
        ];
      }
    }
  }

  void clear() => state = [];
}

final orderDraftProvider =
    StateNotifierProvider<OrderDraftNotifier, List<OrderItemDraft>>((ref) {
      return OrderDraftNotifier();
    });
