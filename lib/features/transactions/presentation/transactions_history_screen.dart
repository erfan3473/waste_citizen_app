// lib/features/transactions/presentation/transactions_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../order/data/order_history_model.dart';
import '../../order/presentation/orders_history_provider.dart';
import '../../tracking/presentation/tracking_screen.dart';
import '../../wallet/data/transaction_model.dart';
import '../../wallet/presentation/wallet_provider.dart';

class TransactionsHistoryScreen extends ConsumerWidget {
  final int initialTab;
  const TransactionsHistoryScreen({super.key, this.initialTab = 0});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange.shade700;
      case 'SCHEDULED':
        return Colors.blue.shade700;
      case 'ACCEPTED':
      case 'ON_THE_WAY':
        return Colors.teal.shade700;
      case 'ARRIVED':
        return Colors.purple.shade700;
      case 'COLLECTED':
        return const Color(0xFF2E7D32);
      case 'CANCELLED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(citizenOrdersHistoryProvider);
    final transactionsAsync = ref.watch(walletTransactionsProvider);

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'سوابق و تراکنش‌ها',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Color(0xFF2E7D32),
            indicatorWeight: 3,
            labelColor: Color(0xFF2E7D32),
            unselectedLabelColor: Colors.black54,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            unselectedLabelStyle: TextStyle(fontSize: 13),
            tabs: [
              Tab(
                text: 'گردش مالی کیف پول',
                icon: Icon(Icons.account_balance_wallet_outlined, size: 22),
              ),
              Tab(
                text: 'درخواست‌های پسماند',
                icon: Icon(Icons.local_shipping_outlined, size: 22),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ════════════════════════════════════════════════════════
            // تب ۱: گردش مالی کیف پول (داینامیک و ضد سرریز)
            // ════════════════════════════════════════════════════════
            RefreshIndicator(
              color: const Color(0xFF2E7D32),
              onRefresh: () async => ref.refresh(walletTransactionsProvider),
              child: transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 54,
                                color: Colors.black26,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'هنوز تراکنش مالی برای حساب شما ثبت نشده است.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final isPositive = tx.isDeposit;

                      return Card(
                        elevation: 1.5,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // سطر سربرگ: عنوان تراکنش با آیکون وضعیت + مبلغ
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: isPositive
                                          ? const Color(0xFFE8F5E9)
                                          : const Color(0xFFFFEBEE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPositive
                                          ? Icons.south_west_rounded
                                          : Icons.north_east_rounded,
                                      color: isPositive
                                          ? const Color(0xFF2E7D32)
                                          : Colors.red.shade700,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      tx.transactionTypeDisplay.isNotEmpty
                                          ? tx.transactionTypeDisplay
                                          : 'تراکنش مالی',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${isPositive ? "+" : ""}${tx.amount.toStringAsFixed(0)} تومان',
                                    style: TextStyle(
                                      color: isPositive
                                          ? const Color(0xFF2E7D32)
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              if (tx.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  tx.description,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12.5,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const Divider(height: 20),
                              // سطر پایینی: شناسه پیگیری + نشان وضعیت
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'شناسه: ${tx.trackingCode.length > 12 ? tx.trackingCode.substring(0, 12) : tx.trackingCode}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tx.status == 'SUCCESS'
                                          ? const Color(0xFFE8F5E9)
                                          : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: tx.status == 'SUCCESS'
                                            ? const Color(0xFFA5D6A7)
                                            : Colors.orange.shade200,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      tx.statusDisplay,
                                      style: TextStyle(
                                        color: tx.status == 'SUCCESS'
                                            ? const Color(0xFF1B5E20)
                                            : Colors.orange.shade900,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('خطا در دریافت گردش حساب: $err'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            ref.refresh(walletTransactionsProvider),
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ════════════════════════════════════════════════════════
            // تب ۲: تاریخچه سفارش‌های پسماند (داینامیک و ضد سرریز)
            // ════════════════════════════════════════════════════════
            RefreshIndicator(
              color: const Color(0xFF2E7D32),
              onRefresh: () async => ref.refresh(citizenOrdersHistoryProvider),
              child: ordersAsync.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 54,
                                color: Colors.black26,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'هنوز درخواستی برای جمع‌آوری پسماند ثبت نکرده‌اید.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final statusColor = _getStatusColor(order.status);

                      return Card(
                        elevation: 1.5,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // سطر سربرگ سفارش
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'درخواست جمع‌آوری #${order.id}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: statusColor.withOpacity(0.35),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      order.statusFa,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              // نشانی متنی
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${order.addressText} ${order.plaque != null && order.plaque!.isNotEmpty ? "پلاک ${order.plaque}" : ""}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.black87,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
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
                                      size: 17,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'زمان مراجعه: ${order.scheduledDate ?? ""} (${order.scheduledTimeSlot ?? ""})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 14),
                              // مبلغ و دکمه رهگیری زنده
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      order.totalPrice > 0
                                          ? 'مبلغ نهایی: ${order.totalPrice.toStringAsFixed(0)} تومان'
                                          : 'تخلیه و وزن‌کشی در محل',
                                      style: TextStyle(
                                        color: order.totalPrice > 0
                                            ? const Color(0xFF1B5E20)
                                            : Colors.grey[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (order.isActive) ...[
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF2E7D32,
                                        ),
                                        foregroundColor: Colors.white,
                                        visualDensity: VisualDensity.compact,
                                        elevation: 1,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.navigation_outlined,
                                        size: 15,
                                      ),
                                      label: const Text(
                                        'رهگیری زنده',
                                        style: TextStyle(fontSize: 11.5),
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
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('خطا در دریافت سوابق: $err'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
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
