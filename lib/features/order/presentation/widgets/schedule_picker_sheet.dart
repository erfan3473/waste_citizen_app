// lib/features/order/presentation/widgets/schedule_picker_sheet.dart

import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

class ScheduleResult {
  final String gregorianDate; // فرمت YYYY-MM-DD برای ارسال به دیتابیس
  final String jalaliDateTitle; // عنوان شمسی برای نمایش در UI
  final String timeSlot; // بازه زمانی انتخابی

  ScheduleResult({
    required this.gregorianDate,
    required this.jalaliDateTitle,
    required this.timeSlot,
  });
}

class SchedulePickerSheet extends StatefulWidget {
  const SchedulePickerSheet({super.key});

  @override
  State<SchedulePickerSheet> createState() => _SchedulePickerSheetState();
}

class _SchedulePickerSheetState extends State<SchedulePickerSheet> {
  int _selectedDayIndex = 0;
  String _selectedSlot = '10 الی 12';

  // لیست بازه‌های زمانی پیشنهادی جمع‌آوری
  final List<String> _timeSlots = const [
    '08 الی 10',
    '10 الی 12',
    '14 الی 16',
    '16 الی 18',
    '18 الی 20',
  ];

  late final List<Jalali> _upcomingDays;

  @override
  void initState() {
    super.initState();
    // تولید ۷ روز آینده بر مبنای تقویم جلالی
    final now = Jalali.now();
    _upcomingDays = List.generate(7, (index) => now.addDays(index));
  }

  String _formatDayLabel(int index, Jalali day) {
    if (index == 0) return 'امروز';
    if (index == 1) return 'فردا';
    return day.formatter.wN; // نام روز هفته (شنبه، یکشنبه، ...)
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // دستگیره بالا (Handle Bar)
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'زمان مراجعه ناوگان جمع‌آوری',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'لطفاً روز و بازه زمانی حضور خود در محل را مشخص کنید:',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          // ۱. اسکرول افقی روزهای شمسی
          const Text(
            'انتخاب روز:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _upcomingDays.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final day = _upcomingDays[index];
                final isSelected = _selectedDayIndex == index;

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _selectedDayIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 76,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2E7D32)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatDayLabel(index, day),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day} ${day.formatter.mN}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),

          // ۲. انتخاب بازه ساعتی
          const Text(
            'بازه ساعتی مراجعه:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeSlots.map((slot) {
              final isSelected = _selectedSlot == slot;
              return ChoiceChip(
                label: Text(slot),
                selected: isSelected,
                selectedColor: const Color(0xFFE8F5E9),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF1B5E20) : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : Colors.grey[300]!,
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _selectedSlot = slot);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // ۳. دکمه تأیید زمان و برگشت داده
          SizedBox(
            width: double.infinity,
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
                final selectedJalali = _upcomingDays[_selectedDayIndex];
                final gregorian = selectedJalali.toDateTime();
                final formattedGregorian =
                    "${gregorian.year}-${gregorian.month.toString().padLeft(2, '0')}-${gregorian.day.toString().padLeft(2, '0')}";

                final jalaliTitle =
                    "${_formatDayLabel(_selectedDayIndex, selectedJalali)} (${selectedJalali.day} ${selectedJalali.formatter.mN})";

                Navigator.of(context).pop(
                  ScheduleResult(
                    gregorianDate: formattedGregorian,
                    jalaliDateTitle: jalaliTitle,
                    timeSlot: _selectedSlot,
                  ),
                );
              },
              child: const Text(
                'تأیید زمان و ثبت نهایی',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
