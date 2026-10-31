// lib/features/navigation/presentation/main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../order/presentation/map_picker_screen.dart';
import '../../wallet/presentation/withdrawal_screen.dart';
import '../../home/presentation/home_tab_screen.dart';
import '../../transactions/presentation/transactions_history_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  // صفحات سه بخش ناوبری
  final List<Widget> _pages = const [
    HomeTabScreen(), // خانه (تعرفه پسماندها و آمار)
    MapPickerScreen(), // جمع‌آوری (انتخاب موقعیت و زمان‌بندی)
    WithdrawalScreen(), // برداشت (کیف پول و ثبت شبا)
  ];

  final List<String> _titles = const [
    'سامانه اکو',
    'ثبت درخواست جمع‌آوری',
    'کیف پول و تسویه حساب',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          // دکمه دراپ‌داون در اپ‌بار برای دسترسی سریع به تراکنش‌ها و تاریخچه‌ها
          PopupMenuButton<String>(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'تراکنش‌ها و تاریخچه',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'wallet_transactions') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const TransactionsHistoryScreen(initialTab: 0),
                  ),
                );
              } else if (value == 'orders_history') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const TransactionsHistoryScreen(initialTab: 1),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'wallet_transactions',
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text('تراکنش‌های کیف پول'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'orders_history',
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: Colors.blue, size: 20),
                    SizedBox(width: 10),
                    Text('تاریخچه درخواست‌های پسماند'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            // باز شدن صفحه نقشه به صورت تمام‌صفحه و پوشش کامل نوبار
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MapPickerScreen()));
          } else {
            setState(() => _currentIndex = index);
          }
        },
        elevation: 3,
        indicatorColor: const Color(0xFFE8F5E9),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF2E7D32)),
            label: 'خانه',
          ),
          NavigationDestination(
            icon: Icon(Icons.recycling_outlined),
            selectedIcon: Icon(Icons.recycling, color: Color(0xFF2E7D32)),
            label: 'جمع‌آوری',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF2E7D32),
            ),
            label: 'برداشت',
          ),
        ],
      ),
    );
  }
}
