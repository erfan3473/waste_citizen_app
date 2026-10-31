// lib/features/home/presentation/home_tab_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_citizen_app/features/order/presentation/map_picker_screen.dart';
import '../../catalog/presentation/categories_provider.dart';

class HomeTabScreen extends ConsumerWidget {
  const HomeTabScreen({super.key});

  // پالت طیف‌های رنگی سبز برای پس‌زمینه کارت‌ها
  static const List<Color> _greenBgPalette = [
    Color(0xFFE8F5E9),
    Color(0xFFF1F8E9),
    Color(0xFFE0F2F1),
    Color(0xFFDCEDC8),
    Color(0xFFE8F8F5),
    Color(0xFFEAFAF1),
  ];

  // پالت رنگ‌های مکمل سبز تیره برای آیکون و حاشیه
  static const List<Color> _greenAccentPalette = [
    Color(0xFF2E7D32),
    Color(0xFF388E3C),
    Color(0xFF00796B),
    Color(0xFF558B2F),
    Color(0xFF1B5E20),
    Color(0xFF239B56),
  ];

  // لیست آیکون‌های متناظر با پسماند و بازیافت
  static const List<IconData> _ecoIcons = [
    Icons.recycling_rounded,
    Icons.eco_rounded,
    Icons.inventory_2_outlined,
    Icons.auto_delete_outlined,
    Icons.delete_sweep_outlined,
    Icons.compost_rounded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(wasteCategoriesProvider);

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: () async => ref.refresh(wasteCategoriesProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // ۱. بنر خوش‌آمدگویی و هدایت به نقشه ثبت درخواست
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B5E20).withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تفکیک هوشمند پسماند، درآمد پایدار',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'پسماندهای خشک خود را تحویل دهید و وجه آن را نقداً در کیف پول دریافت کنید.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1B5E20),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add_location_alt_outlined, size: 20),
                  label: const Text(
                    'ثبت درخواست جمع‌آوری',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MapPickerScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ۲. سربرگ بخش تعرفه‌ها
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تعرفه روز خرید پسماند خشک',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                'نرخ مصوب (تومان)',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ۳. بدنه تعرفه‌ها به صورت ۴ ستون در ردیف
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 40,
                        color: Colors.black26,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'در حال حاضر هیچ نوع پسماندی در سامانه ثبت نشده است.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 👈 دقیقاً ۴ آیتم در هر ردیف
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.73, // نسبت ابعاد بهینه‌سازی‌شده ضد سرریز
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final bgColor =
                      _greenBgPalette[index % _greenBgPalette.length];
                  final accentColor =
                      _greenAccentPalette[index % _greenAccentPalette.length];
                  final iconData = _ecoIcons[index % _ecoIcons.length];

                  return Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withOpacity(0.22),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // آیکون کوچک با کانتینر دایره‌ای
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData, size: 19, color: accentColor),
                        ),

                        // عنوان دسته‌بندی پسماند (تا ۲ خط و با محافظت از سرریز)
                        Text(
                          cat.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: Colors.black87,
                          ),
                        ),

                        // قیمت به تومان و واحد سنجش
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${cat.pricePerUnit.toStringAsFixed(0)} ت',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(
                  color: Color(0xFF2E7D32),
                  strokeWidth: 2.2,
                ),
              ),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'خطا در برقراری ارتباط با سرور و دریافت لیست تعرفه‌ها',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'لطفاً از اتصال اینترنت خود اطمینان حاصل فرمایید.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text(
                      'تلاش مجدد',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () => ref.refresh(wasteCategoriesProvider),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
