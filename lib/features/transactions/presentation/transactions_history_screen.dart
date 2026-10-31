// lib/features/transactions/presentation/transactions_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../order/presentation/orders_history_provider.dart';
import '../../order/data/order_history_model.dart';
import '../../tracking/presentation/tracking_screen.dart';

class TransactionsHistoryScreen extends ConsumerWidget {
  final int initialTab;
  const TransactionsHistoryScreen({super.key, this.initialTab = 0});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'SCHEDULED':
        return Colors.blue;
      case 'ACCEPTED':
      case 'ON_THE_WAY':
        return Colors.teal;
      case 'ARRIVED':
        return Colors.purple;
      case 'COLLECTED':
        return const Color(0xFF2E7D32);
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(citizenOrdersHistoryProvider);

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سوابق و تراکنش‌ها'),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Color(0xFF2E7D32),
            labelColor: Color(0xFF2E7D32),
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(
                text: 'گردش مالی کیف پول',
                icon: Icon(Icons.account_balance_wallet_outlined),
              ),
              Tab(
                text: 'درخواست‌های پسماند',
                icon: Icon(Icons.local_shipping_outlined),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // تب ۱: کیف پول
            ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Text(
                      'هنوز تراکنش مالی برای حساب شما ثبت نشده است.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),

            // تب ۲: تاریخچه سفارش‌های پسماند
            RefreshIndicator(
              onRefresh: () async => ref.refresh(citizenOrdersHistoryProvider),
              child: ordersAsync.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return ListView(
                      children: const [
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 80),
                            child: Text(
                              'هنوز درخواستی برای جمع‌آوری پسماند ثبت نکرده‌اید.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final statusColor = _getStatusColor(order.status);

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'درخواست جمع‌آوری #${order.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      order.statusFa,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${order.addressText} ${order.plaque != null ? "پلاک ${order.plaque}" : ""}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (order.scheduledDate != null ||
                                  order.scheduledTimeSlot != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'زمان مراجعه: ${order.scheduledDate ?? ""} (${order.scheduledTimeSlot ?? ""})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order.totalPrice > 0
                                        ? 'مبلغ نهایی: ${order.totalPrice.toStringAsFixed(0)} تومان'
                                        : 'تخلیه و وزن‌کشی در محل',
                                    style: TextStyle(
                                      color: order.totalPrice > 0
                                          ? const Color(0xFF1B5E20)
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (order.isActive)
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF2E7D32,
                                        ),
                                        foregroundColor: Colors.white,
                                        visualDensity: VisualDensity.compact,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.navigation_outlined,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'رهگیری زنده',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => TrackingScreen(
                                              orderId: order.id,
                                              citizenLocation: LatLng(
                                                order.latitude,
                                                order.longitude,
                                              ),
                                            ),
                                          ),
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
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('خطا در دریافت سوابق: $err'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () =>
                            ref.refresh(citizenOrdersHistoryProvider),
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
