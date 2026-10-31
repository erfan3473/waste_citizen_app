// lib/features/wallet/presentation/withdrawal_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _shabaController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _shabaController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // کارت موجودی فعلی
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFFF1F8E9),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                Text(
                  'موجودی قابل برداشت',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                SizedBox(height: 8),
                Text(
                  '۰ تومان',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'درخواست تسویه و واریز به حساب بانکی',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'مبلغ برداشت (تومان)',
            prefixIcon: Icon(Icons.money),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _shabaController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'شماره شبا (بدون IR)',
            prefixIcon: Icon(Icons.credit_card),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'نام و نام خانوادگی صاحب حساب',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'درخواست تسویه شما با موفقیت ثبت شد و در صف پایا قرار گرفت.',
                  ),
                ),
              );
            },
            child: const Text(
              'ثبت درخواست برداشت',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
