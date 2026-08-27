import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/exam_models.dart';

class ExamStatsRowWidget extends StatelessWidget {
  final GeneratedExam exam;

  const ExamStatsRowWidget({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final mcqSection = exam.sections
        .where((s) => s.type == 'MCQ')
        .fold(0, (sum, s) => sum + s.questions.length);
    final shortSection = exam.sections
        .where((s) => s.type == 'SHORT')
        .fold(0, (sum, s) => sum + s.questions.length);
    final longSection = exam.sections
        .where((s) => s.type == 'LONG')
        .fold(0, (sum, s) => sum + s.questions.length);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'MCQ',
            value: '$mcqSection',
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Short',
            value: '$shortSection',
            color: AppTheme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Long',
            value: '$longSection',
            color: AppTheme.warning,
          ),
        ),
      ],
    );
  }
}

// Adapted from extracted ProgressCard anatomy:
// label + icon top row + large numeric value below
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.quiz_outlined, color: color, size: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text('questions', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
