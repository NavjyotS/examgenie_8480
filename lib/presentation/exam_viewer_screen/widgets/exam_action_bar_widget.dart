import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/exam_models.dart';
import '../../source_upload_screen/source_upload_screen.dart'
    show CustomIconWidget;

class ExamActionBarWidget extends StatelessWidget {
  final GeneratedExam exam;
  final VoidCallback onGenerateAnother;

  const ExamActionBarWidget({
    super.key,
    required this.exam,
    required this.onGenerateAnother,
  });

  void _onExportPdf(BuildContext context) {
    // TODO: Integrate PDF export via printing package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'PDF export — connect printing package for production.',
        ),
        backgroundColor: AppTheme.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onSave(BuildContext context) {
    // TODO: Integrate shared_preferences / hive for local storage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            CustomIconWidget(
              iconName: 'check',
              color: AppTheme.primary,
              size: 16,
            ),
            SizedBox(width: 8),
            Text('Exam saved to your library.'),
          ],
        ),
        backgroundColor: AppTheme.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.glassBorder, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Export + Save
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: 'print',
                  label: 'Export PDF',
                  color: AppTheme.secondary,
                  onTap: () => _onExportPdf(context),
                  outlined: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: 'save',
                  label: 'Save Exam',
                  color: AppTheme.primary,
                  onTap: () => _onSave(context),
                  outlined: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Generate Another — full width
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onGenerateAnother,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceVariant,
                foregroundColor: AppTheme.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.glassBorder),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CustomIconWidget(
                    iconName: 'refresh',
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Generate Another Exam',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
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

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: outlined ? color.withAlpha(26) : color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: outlined ? color.withAlpha(102) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: outlined ? color : Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: outlined ? color : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
