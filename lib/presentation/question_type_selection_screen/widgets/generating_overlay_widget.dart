import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../source_upload_screen/source_upload_screen.dart'
    show CustomIconWidget;

class GeneratingOverlayWidget extends StatefulWidget {
  final int fileCount;
  final int totalQuestions;

  const GeneratingOverlayWidget({
    super.key,
    required this.fileCount,
    required this.totalQuestions,
  });

  @override
  State<GeneratingOverlayWidget> createState() =>
      _GeneratingOverlayWidgetState();
}

class _GeneratingOverlayWidgetState extends State<GeneratingOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _stepController;
  late Animation<double> _pulseAnim;

  int _currentStep = 0;
  final List<String> _steps = [
    'Reading your study notes...',
    'Identifying key concepts...',
    'Structuring question types...',
    'Generating answer keys...',
    'Finalising exam paper...',
  ];

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _cycleSteps();
  }

  void _cycleSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      setState(() => _currentStep = i);
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background.withAlpha(235),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              ScaleTransition(
                scale: _pulseAnim,
                child: RotationTransition(
                  turns: _rotateController,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(102),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: CustomIconWidget(
                        iconName: 'auto_awesome',
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Generating Your Exam',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Analysing ${widget.fileCount} file${widget.fileCount > 1 ? 's' : ''} • ${widget.totalQuestions} questions',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Steps
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Column(
                  children: List.generate(_steps.length, (index) {
                    final isPast = index < _currentStep;
                    final isCurrent = index == _currentStep;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isPast
                                  ? AppTheme.primary
                                  : isCurrent
                                  ? AppTheme.primaryMuted
                                  : AppTheme.glassBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrent
                                    ? AppTheme.primary
                                    : AppTheme.glassBorder,
                              ),
                            ),
                            child: Center(
                              child: isPast
                                  ? const CustomIconWidget(
                                      iconName: 'check',
                                      color: Colors.white,
                                      size: 12,
                                    )
                                  : isCurrent
                                  ? SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: AppTheme.primary,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _steps[index],
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: isPast
                                        ? AppTheme.primary
                                        : isCurrent
                                        ? AppTheme.textPrimary
                                        : AppTheme.textMuted,
                                    fontWeight: isCurrent
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'This may take 10–30 seconds',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
