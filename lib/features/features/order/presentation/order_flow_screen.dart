// lib/features/order/presentation/order_flow_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_citizen_app/features/catalog/presentation/categories_provider.dart';
import 'package:waste_citizen_app/features/order/presentation/map_picker_screen.dart';
import 'package:waste_citizen_app/features/order/presentation/order_state.dart';

class OrderFlowScreen extends ConsumerWidget {
  const OrderFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(wasteCategoriesProvider);
    final draftItems = ref.watch(orderDraftProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('درخواست جمع‌آوری پسماند'),
        centerTitle: true,
      ),
      body: categoriesAsync.when(
        data: (categories) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final currentItem = draftItems.firstWhere(
              (item) => item.categoryId == cat.id,
              orElse: () => OrderItemDraft(
                categoryId: cat.id,
                title: cat.title,
                estimatedAmount: 0,
                unitPrice: cat.pricePerUnit,
              ),
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'نرخ هر ${cat.unit}: ${cat.pricePerUnit.toStringAsFixed(0)} تومان',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (currentItem.estimatedAmount > 0) {
                              ref
                                  .read(orderDraftProvider.notifier)
                                  .setAmount(
                                    cat.id,
                                    cat.title,
                                    currentItem.estimatedAmount - 1,
                                    cat.pricePerUnit,
                                  );
                            }
                          },
                        ),
                        Text(
                          '${currentItem.estimatedAmount.toStringAsFixed(0)} ${cat.unit}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            ref
                                .read(orderDraftProvider.notifier)
                                .setAmount(
                                  cat.id,
                                  cat.title,
                                  currentItem.estimatedAmount + 1,
                                  cat.pricePerUnit,
                                );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('خطا در دریافت اطلاعات: $err', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(wasteCategoriesProvider),
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: draftItems.isEmpty
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MapPickerScreen(),
                    ),
                  );
                },
          child: const Text(
            'ادامه و انتخاب آدرس روی نقشه',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
