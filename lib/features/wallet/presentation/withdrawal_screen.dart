// lib/features/wallet/presentation/withdrawal_screen.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import 'wallet_provider.dart';

class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _shabaController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _shabaController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// ثبت درخواست تسویه پایا در سرور
  Future<void> _submitWithdrawal(double currentBalance) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('مبلغ درخواستی باید بیشتر از صفر باشد.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount > currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('مبلغ درخواستی از موجودی قابل برداشت شما بیشتر است.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // نرمال‌سازی شماره شبا به فرمت ۲۶ کاراکتری استاندارد ایران (IR + 24 رقم)
    var rawShaba = _shabaController.text.trim().toUpperCase();
    if (!rawShaba.startsWith('IR')) {
      rawShaba = 'IR$rawShaba';
    }

    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();

    try {
      final dio = ref.read(dioProvider);
      final payload = {
        'amount': amount.toInt(),
        'shaba_number': rawShaba,
        'account_owner_name': _nameController.text.trim(),
      };

      await dio.post(ApiEndpoints.withdrawals, data: payload);

      // به‌روزرسانی آنی موجودی و تاریخچه تراکنش‌ها در استیت
      ref.invalidate(walletInfoProvider);
      ref.invalidate(walletTransactionsProvider);

      _amountController.clear();
      _shabaController.clear();
      _nameController.clear();

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32),
                  size: 26,
                ),
                SizedBox(width: 8),
                Text(
                  'ثبت موفق درخواست',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              'درخواست تسویه شما با موفقیت ثبت شد و پس از بررسی واحد مالی، از طریق حواله پایا به حساب شما واریز خواهد شد.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('متوجه شدم'),
              ),
            ],
          ),
        );
      }
    } on DioException catch (e) {
      final msg = e.error?.toString() ?? 'خطا در ثبت درخواست برداشت.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletInfoProvider);

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: () async {
        ref.invalidate(walletInfoProvider);
        ref.invalidate(walletTransactionsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // کارت موجودی فعلی زنده
          walletAsync.when(
            data: (wallet) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color(0xFFF1F8E9),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'موجودی قابل برداشت',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${wallet.balance.toStringAsFixed(0)} تومان',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      if (wallet.balance > 0) ...[
                        const SizedBox(height: 10),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(
                            Icons.all_inclusive_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'برداشت کل موجودی',
                            style: TextStyle(fontSize: 12),
                          ),
                          onPressed: () {
                            _amountController.text = wallet.balance
                                .toInt()
                                .toString();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
            loading: () => Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: const Color(0xFFF1F8E9),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2E7D32),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
            error: (err, _) => Card(
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'خطا در دریافت موجودی: $err',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () => ref.refresh(walletInfoProvider),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),

          const Text(
            'درخواست تسویه و واریز به حساب بانکی (پایا)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
          ),
          const SizedBox(height: 14),

          Form(
            key: _formKey,
            child: Column(
              children: [
                // فیلد مبلغ برداشت
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'مبلغ برداشت (تومان)',
                    prefixIcon: const Icon(
                      Icons.payments_outlined,
                      color: Color(0xFF2E7D32),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'لطفاً مبلغ مورد نظر را وارد کنید.';
                    }
                    final val = double.tryParse(value.trim());
                    if (val == null || val <= 0) {
                      return 'مبلغ باید عددی بزرگتر از صفر باشد.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // فیلد شماره شبا
                TextFormField(
                  controller: _shabaController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  maxLength: 24,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'شماره شبا (۲۴ رقم بدون IR)',
                    prefixText: 'IR - ',
                    prefixStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    prefixIcon: const Icon(
                      Icons.account_balance_outlined,
                      color: Color(0xFF2E7D32),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'شماره شبا الزامی است.';
                    }
                    final cleaned = value.trim();
                    if (cleaned.length != 24) {
                      return 'شماره شبا باید دقیقاً ۲۴ رقم باشد.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // فیلد نام صاحب حساب
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'نام و نام خانوادگی صاحب حساب',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF2E7D32),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'نام صاحب حساب الزامی است.';
                    }
                    if (value.trim().length < 3) {
                      return 'نام نامعتبر است.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // دکمه ثبت نهایی درخواست
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            final currentBal =
                                walletAsync.value?.balance ?? 0.0;
                            _submitWithdrawal(currentBal);
                          },
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'ثبت درخواست برداشت وجه',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
