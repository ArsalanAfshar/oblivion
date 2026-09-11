import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/app_providers.dart';

/// Compact EN / FA control used on the desktop home chrome.
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final code = ref.watch(appPreferencesProvider).localeCode;
    final isFa = code == 'fa';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.cardPressed,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.separator),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Chip(
              label: 'EN',
              selected: !isFa,
              onTap: () =>
                  ref.read(appPreferencesProvider.notifier).setLocale('en'),
            ),
            _Chip(
              label: 'فا',
              selected: isFa,
              onTap: () =>
                  ref.read(appPreferencesProvider.notifier).setLocale('fa'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0x00000000),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppText.caption(
            selected ? const Color(0xFF1C202C) : palette.labelSecondary,
          ).copyWith(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}
