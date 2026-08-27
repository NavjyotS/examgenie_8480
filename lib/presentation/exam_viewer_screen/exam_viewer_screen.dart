import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/exam_models.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../source_upload_screen/source_upload_screen.dart'
    show CustomIconWidget;
import './widgets/exam_action_bar_widget.dart';
import './widgets/exam_header_card_widget.dart';
import './widgets/exam_section_widget.dart';
import './widgets/exam_stats_row_widget.dart';

// TODO: Replace with [Riverpod/Bloc] for production
class ExamViewerScreen extends StatefulWidget {
  final Map<String, dynamic>? examData;

  const ExamViewerScreen({super.key, this.examData});

  @override
  State<ExamViewerScreen> createState() => _ExamViewerScreenState();
}

class _ExamViewerScreenState extends State<ExamViewerScreen> {
  // TODO: Replace with [Riverpod/Bloc] for production
  late GeneratedExam _exam;
  bool _showAnswerKeys = false;

  @override
  void initState() {
    super.initState();
    if (widget.examData != null) {
      _exam = GeneratedExam.fromJson(widget.examData!);
    } else {
      _exam = GeneratedExam.mockExam;
    }
  }

  void _onGenerateAnother() {
    context.go(AppRoutes.sourceUpload);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: isTablet
                  ? _buildTabletLayout(context)
                  : _buildPhoneLayout(context),
            ),
            ExamActionBarWidget(
              exam: _exam,
              onGenerateAnother: _onGenerateAnother,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'arrow_forward_rounded',
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Exam Paper',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          // Answer key toggle
          GestureDetector(
            onTap: () => setState(() => _showAnswerKeys = !_showAnswerKeys),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _showAnswerKeys
                    ? AppTheme.primaryMuted
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _showAnswerKeys
                      ? AppTheme.primary.withAlpha(128)
                      : AppTheme.glassBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: _showAnswerKeys ? 'visibility' : 'visibility_off',
                    color: _showAnswerKeys
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Answers',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _showAnswerKeys
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
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

  Widget _buildPhoneLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExamHeaderCardWidget(exam: _exam),
          const SizedBox(height: 16),
          ExamStatsRowWidget(exam: _exam),
          const SizedBox(height: 20),
          ..._exam.sections.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ExamSectionWidget(
                section: entry.value,
                sectionIndex: entry.key,
                showAnswerKeys: _showAnswerKeys,
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left sidebar: header + stats
        SizedBox(
          width: 280,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 20),
            child: Column(
              children: [
                ExamHeaderCardWidget(exam: _exam),
                const SizedBox(height: 16),
                ExamStatsRowWidget(exam: _exam),
              ],
            ),
          ),
        ),
        // Right: questions
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 0, 20, 20),
            child: Column(
              children: _exam.sections.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ExamSectionWidget(
                    section: entry.value,
                    sectionIndex: entry.key,
                    showAnswerKeys: _showAnswerKeys,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
