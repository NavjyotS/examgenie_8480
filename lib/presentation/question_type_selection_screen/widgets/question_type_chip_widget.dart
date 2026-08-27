import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../source_upload_screen/source_upload_screen.dart'
    show CustomIconWidget;

class QuestionTypeChipWidget extends StatelessWidget {
  final String label;
  final String shortLabel;
  final String icon;
  final bool isEnabled;
  final Color color;
  final Function(bool) onToggle;

  const QuestionTypeChipWidget({
    super.key,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.isEnabled,
    required this.color,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!isEnabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isEnabled ? color.withAlpha(31) : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled ? color.withAlpha(128) : AppTheme.glassBorder,
            width: isEnabled ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isEnabled
                    ? color.withAlpha(51)
                    : AppTheme.glassBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: icon,
                  color: isEnabled ? color : AppTheme.textMuted,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              shortLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isEnabled ? color : AppTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isEnabled ? AppTheme.textSecondary : AppTheme.textMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isEnabled ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isEnabled ? color : AppTheme.textMuted,
                  width: 1.5,
                ),
              ),
              child: isEnabled
                  ? const Center(
                      child: CustomIconWidget(
                        iconName: 'check',
                        color: Colors.white,
                        size: 12,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
