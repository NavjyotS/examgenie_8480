import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

import '../../models/exam_models.dart';
import '../../providers/chat_notifier.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../source_upload_screen/source_upload_screen.dart'
    show CustomIconWidget;
import './widgets/count_stepper_widget.dart';
import './widgets/generating_overlay_widget.dart';
import './widgets/pattern_upload_widget.dart';
import './widgets/question_type_chip_widget.dart';

class QuestionTypeSelectionScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> uploadedFiles;

  const QuestionTypeSelectionScreen({super.key, required this.uploadedFiles});

  @override
  ConsumerState<QuestionTypeSelectionScreen> createState() =>
      _QuestionTypeSelectionScreenState();
}

class _QuestionTypeSelectionScreenState
    extends ConsumerState<QuestionTypeSelectionScreen> {
  bool _mcqEnabled = true;
  bool _shortEnabled = true;
  bool _longEnabled = false;

  int _mcqCount = 5;
  int _shortCount = 3;
  int _longCount = 2;

  Map<String, dynamic>? _patternFile;
  final TextEditingController _instructionsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isGenerating = false;

  static const _config = ChatConfig(
    provider: 'GEMINI',
    model: 'gemini/gemini-2.5-flash',
    streaming: false,
  );

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  int get _totalQuestions {
    int total = 0;
    if (_mcqEnabled) total += _mcqCount;
    if (_shortEnabled) total += _shortCount;
    if (_longEnabled) total += _longCount;
    return total;
  }

  int get _estimatedMarks {
    int marks = 0;
    if (_mcqEnabled) marks += _mcqCount * 2;
    if (_shortEnabled) marks += _shortCount * 4;
    if (_longEnabled) marks += _longCount * 6;
    return marks;
  }

  String _buildExamPrompt() {
    final parts = <String>[];
    if (_mcqEnabled) {
      parts.add('$_mcqCount Multiple Choice Questions (2 marks each)');
    }
    if (_shortEnabled) {
      parts.add('$_shortCount Short Answer Questions (4 marks each)');
    }
    if (_longEnabled) {
      parts.add('$_longCount Long Answer Questions (6 marks each)');
    }

    final customInstructions = _instructionsController.text.trim();

    return '''You are an expert exam paper generator. Analyse the provided study notes and generate a structured practice exam paper.

Generate the following question types:
${parts.join('\n')}

Total marks: $_estimatedMarks

${customInstructions.isNotEmpty ? 'Custom instructions: $customInstructions\n' : ''}
Return ONLY valid JSON matching this exact schema (no markdown, no explanation):
{
  "title": "string - descriptive exam title based on the notes content",
  "totalMarks": number,
  "timeAllowed": "string - e.g. '60 minutes'",
  "instructions": ["string array of general exam instructions"],
  "sections": [
    {
      "type": "MCQ" | "SHORT" | "LONG",
      "title": "string - section title",
      "instructions": "string - section-specific instructions",
      "questions": [
        {
          "id": "string - unique id like mcq_1",
          "questionText": "string",
          "options": ["A. ...", "B. ...", "C. ...", "D. ..."] (only for MCQ, null otherwise),
          "answerKey": "string - correct answer or model answer",
          "explanation": "string - brief explanation",
          "marks": number
        }
      ]
    }
  ]
}''';
  }

  List<Map<String, dynamic>> _buildMessages() {
    final contentParts = <Map<String, dynamic>>[];

    // Add all uploaded note files as images
    for (final file in widget.uploadedFiles) {
      final bytes = file['bytes'] as List<int>?;
      final mimeType = file['mimeType'] as String? ?? 'image/jpeg';
      if (bytes != null) {
        final base64String = base64Encode(bytes);
        final dataUri = 'data:$mimeType;base64,$base64String';
        contentParts.add({
          'type': 'image_url',
          'image_url': {'url': dataUri},
        });
      }
    }

    // Add pattern file if provided
    if (_patternFile != null) {
      final bytes = _patternFile!['bytes'] as List<int>?;
      final mimeType = _patternFile!['mimeType'] as String? ?? 'image/jpeg';
      if (bytes != null) {
        final base64String = base64Encode(bytes);
        final dataUri = 'data:$mimeType;base64,$base64String';
        contentParts.add({
          'type': 'image_url',
          'image_url': {'url': dataUri},
        });
      }
    }

    // Add the prompt text
    contentParts.add({'type': 'text', 'text': _buildExamPrompt()});

    return [
      {'role': 'user', 'content': contentParts},
    ];
  }

  Future<void> _generateExam() async {
    if (!_mcqEnabled && !_shortEnabled && !_longEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enable at least one question type.'),
          backgroundColor: AppTheme.warning.withAlpha(230),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      await ref
          .read(chatNotifierProvider(_config).notifier)
          .sendMessage(
            _buildMessages(),
            parameters: {
              'temperature': 0.4,
              'max_tokens': 4096,
              'response_format': {'type': 'json_object'},
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Generation failed. Please check your connection and try again.',
            ),
            backgroundColor: AppTheme.error.withAlpha(230),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider(_config));

    ref.listen<ChatState>(chatNotifierProvider(_config), (previous, next) {
      if (next.error != null) {
        if (_isGenerating) setState(() => _isGenerating = false);
        Fluttertoast.showToast(
          msg: next.error.toString(),
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
      if (previous?.isLoading == true &&
          !next.isLoading &&
          next.response.isNotEmpty) {
        setState(() => _isGenerating = false);
        try {
          final jsonStr = next.response.trim();
          final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;
          final exam = GeneratedExam.fromJson(jsonData);
          if (mounted) {
            context.push(
              AppRoutes.examViewer,
              extra: {'examData': exam.toJson()},
            );
          }
        } catch (e) {
          Fluttertoast.showToast(
            msg: 'Failed to parse exam response. Please try again.',
            backgroundColor: Colors.red,
            toastLength: Toast.LENGTH_LONG,
          );
        }
      }
    });

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStepHeader(context),
                          const SizedBox(height: 24),
                          _buildSummaryBar(context),
                          const SizedBox(height: 24),
                          _buildSectionLabel(context, 'Question Types'),
                          const SizedBox(height: 12),
                          _buildTypeSection(context),
                          const SizedBox(height: 24),
                          _buildSectionLabel(context, 'Question Distribution'),
                          const SizedBox(height: 12),
                          _buildCountSection(context),
                          const SizedBox(height: 24),
                          _buildSectionLabel(
                            context,
                            'Pattern Reference (Optional)',
                          ),
                          const SizedBox(height: 12),
                          PatternUploadWidget(
                            patternFile: _patternFile,
                            onPatternSelected: (file) =>
                                setState(() => _patternFile = file),
                            onPatternRemoved: () =>
                                setState(() => _patternFile = null),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionLabel(
                            context,
                            'Custom Instructions (Optional)',
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionsField(context),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildGenerateButton(context, chatState.isLoading),
              ],
            ),
          ),
        ),
        if (_isGenerating || chatState.isLoading)
          GeneratingOverlayWidget(
            fileCount: widget.uploadedFiles.length,
            totalQuestions: _totalQuestions,
          ),
      ],
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
              'Configure Exam',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryMuted,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withAlpha(77)),
            ),
            child: Text(
              '${widget.uploadedFiles.length} file${widget.uploadedFiles.length > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.secondaryMuted,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.secondary.withAlpha(77)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Step 2 of 3',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Configure\nYour Exam',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(height: 1.2),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose question types, set counts, and add optional instructions for Gemini AI.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSummaryBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              context,
              icon: 'quiz',
              label: 'Questions',
              value: '$_totalQuestions',
              color: AppTheme.primary,
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.glassBorder),
          Expanded(
            child: _buildSummaryItem(
              context,
              icon: 'grade',
              label: 'Total Marks',
              value: '$_estimatedMarks',
              color: AppTheme.secondary,
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.glassBorder),
          Expanded(
            child: _buildSummaryItem(
              context,
              icon: 'attach_file',
              label: 'Files',
              value: '${widget.uploadedFiles.length}',
              color: AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        CustomIconWidget(iconName: icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildTypeSection(BuildContext context) {
    return Column(
      children: [
        QuestionTypeChipWidget(
          label: '2 marks each • 4 options',
          shortLabel: 'Multiple Choice (MCQ)',
          icon: 'radio_button_checked',
          isEnabled: _mcqEnabled,
          onToggle: (val) => setState(() => _mcqEnabled = val),
          color: AppTheme.primary,
        ),
        const SizedBox(height: 8),
        QuestionTypeChipWidget(
          label: '4 marks each • 2–3 sentences',
          shortLabel: 'Short Answer',
          icon: 'short_text',
          isEnabled: _shortEnabled,
          onToggle: (val) => setState(() => _shortEnabled = val),
          color: AppTheme.secondary,
        ),
        const SizedBox(height: 8),
        QuestionTypeChipWidget(
          label: '6 marks each • Detailed response',
          shortLabel: 'Long Answer',
          icon: 'subject',
          isEnabled: _longEnabled,
          onToggle: (val) => setState(() => _longEnabled = val),
          color: AppTheme.warning,
        ),
      ],
    );
  }

  Widget _buildCountSection(BuildContext context) {
    return Column(
      children: [
        if (_mcqEnabled)
          CountStepperWidget(
            label: 'MCQ Questions',
            subtitle: '2 marks each',
            value: _mcqCount,
            min: 1,
            max: 20,
            onChanged: (val) => setState(() => _mcqCount = val),
            color: AppTheme.primary,
          ),
        if (_mcqEnabled) const SizedBox(height: 8),
        if (_shortEnabled)
          CountStepperWidget(
            label: 'Short Answer Questions',
            subtitle: '4 marks each',
            value: _shortCount,
            min: 1,
            max: 10,
            onChanged: (val) => setState(() => _shortCount = val),
            color: AppTheme.secondary,
          ),
        if (_shortEnabled) const SizedBox(height: 8),
        if (_longEnabled)
          CountStepperWidget(
            label: 'Long Answer Questions',
            subtitle: '6 marks each',
            value: _longCount,
            min: 1,
            max: 5,
            onChanged: (val) => setState(() => _longCount = val),
            color: AppTheme.warning,
          ),
        if (!_mcqEnabled && !_shortEnabled && !_longEnabled)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.glassBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Row(
              children: [
                const CustomIconWidget(
                  iconName: 'info_outline',
                  color: AppTheme.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Enable at least one question type above.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInstructionsField(BuildContext context) {
    return TextFormField(
      controller: _instructionsController,
      maxLines: 3,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText:
            'e.g. "Follow Grade 10 CBSE pattern", "Focus on Chapter 4", "Include diagram-based questions"',
        hintStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
        filled: true,
        fillColor: AppTheme.glassBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildGenerateButton(BuildContext context, bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.glassBorder)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: (isLoading || _isGenerating) ? null : _generateExam,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            disabledBackgroundColor: AppTheme.primaryMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CustomIconWidget(
                iconName: 'auto_awesome',
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                (isLoading || _isGenerating)
                    ? 'Generating with Gemini AI...'
                    : 'Generate Exam with Gemini AI',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}