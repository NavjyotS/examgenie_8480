import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../source_upload_screen/source_upload_screen.dart'
    show CustomIconWidget;

class CountStepperWidget extends StatelessWidget {
  final String label;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final Color color;
  final Function(int) onChanged;

  const CountStepperWidget({
    super.key,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          // Stepper controls
          Row(
            children: [
              _StepperButton(
                icon: 'remove',
                color: color,
                enabled: value > min,
                onTap: () {
                  if (value > min) onChanged(value - 1);
                },
              ),
              SizedBox(
                width: 44,
                child: Center(
                  child: Text(
                    '$value',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              _StepperButton(
                icon: 'add',
                color: color,
                enabled: value < max,
                onTap: () {
                  if (value < max) onChanged(value + 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final String icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? color.withAlpha(38) : AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? color.withAlpha(102) : AppTheme.glassBorder,
          ),
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: icon,
            color: enabled ? color : AppTheme.textMuted,
            size: 16,
          ),
        ),
      ),
    );
  }
}
