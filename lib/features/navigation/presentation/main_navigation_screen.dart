// lib/features/navigation/presentation/main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/auth_storage.dart';
import '../../home/presentation/home_tab_screen.dart';
import '../../order/presentation/map_picker_screen.dart';
import '../../transactions/presentation/transactions_history_screen.dart';
import '../../wallet/presentation/withdrawal_screen.dart';
import '../../auth/presentation/citizen_login_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeTabScreen(),
    SizedBox.shrink(),
    WithdrawalScreen(),
  ];

  final List<String> _titles = const [
    'سامانه اکو',
    'ثبت درخواست جمع‌آوری',
    'کیف پول و تسویه حساب',
  ];

  /// دیالوگ تایید و اجرای خروج از حساب
  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text(
              'خروج از حساب کاربری',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'آیا از خروج از حساب کاربری خود در سامانه اکو اطمینان دارید؟',
          style: TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('انصراف', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('خروج قطعی'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    // نمایش لودینگ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      ),
    );

    try {
      final dio = ref.read(dioProvider);
      // فراخوانی اندپوینت ابطال توکن در سرور
      await dio.post(ApiEndpoints.citizenLogout);
    } catch (_) {
      // در صورت خطای شبکه یا قطعی، پاک‌سازی محلی انجام می‌شود
    } finally {
      // ۱. پاک‌سازی کامل توکن و شماره موبایل از حافظه پایدار گوشی
      await AuthStorage.clearAuthData();

      if (mounted) {
        Navigator.of(context).pop(); // بستن دیالوگ لودینگ

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('شما با موفقیت از حساب کاربری خارج شدید.'),
            backgroundColor: Colors.black87,
            duration: Duration(seconds: 2),
          ),
        );

        // هدایت قطعی به صفحه ورود و حذف تمام صفحات قبلی از حافظه
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CitizenLoginScreen()),
          (route) => false,
        );
      }
    }
  }

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
          PopupMenuButton<String>(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'تراکنش‌ها و حساب کاربری',
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
              } else if (value == 'logout') {
                _handleLogout(context);
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
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'خروج از حساب کاربری',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
