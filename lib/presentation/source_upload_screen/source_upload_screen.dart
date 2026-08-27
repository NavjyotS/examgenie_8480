
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './widgets/file_grid_widget.dart';
import './widgets/source_app_bar_widget.dart';
import './widgets/upload_zone_widget.dart';

// TODO: Replace with [Riverpod/Bloc] for production
class SourceUploadScreen extends StatefulWidget {
  const SourceUploadScreen({super.key});

  @override
  State<SourceUploadScreen> createState() => _SourceUploadScreenState();
}

class _SourceUploadScreenState extends State<SourceUploadScreen>
    with SingleTickerProviderStateMixin {
  // TODO: Replace with [Riverpod/Bloc] for production
  final List<Map<String, dynamic>> _uploadedFiles = [];
  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fabScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  void _onFilesAdded(List<Map<String, dynamic>> newFiles) {
    setState(() {
      _uploadedFiles.addAll(newFiles);
    });
    if (_uploadedFiles.isNotEmpty && !_fabAnimController.isCompleted) {
      _fabAnimController.forward();
    }
  }

  void _onFileRemoved(int index) {
    setState(() {
      _uploadedFiles.removeAt(index);
    });
    if (_uploadedFiles.isEmpty) {
      _fabAnimController.reverse();
    }
  }

  void _proceedToConfig() {
    if (_uploadedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please upload at least one study note file.'),
          backgroundColor: AppTheme.surfaceVariant,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    context.push(
      AppRoutes.questionTypeSelection,
      extra: {'uploadedFiles': _uploadedFiles},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const SourceAppBarWidget(),
            Expanded(
              child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(theme),
            ),
            _buildStickyFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneLayout(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildHeaderSection(theme),
          const SizedBox(height: 20),
          UploadZoneWidget(onFilesAdded: _onFilesAdded),
          const SizedBox(height: 20),
          if (_uploadedFiles.isNotEmpty) ...[
            _buildFilesHeader(theme),
            const SizedBox(height: 12),
            FileGridWidget(files: _uploadedFiles, onRemove: _onFileRemoved),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(Theme.of(context)),
                  const SizedBox(height: 20),
                  UploadZoneWidget(onFilesAdded: _onFilesAdded),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 5,
            child: _uploadedFiles.isNotEmpty
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilesHeader(Theme.of(context)),
                        const SizedBox(height: 12),
                        FileGridWidget(
                          files: _uploadedFiles,
                          onRemove: _onFileRemoved,
                          columns: 3,
                        ),
                      ],
                    ),
                  )
                : _buildEmptyPreviewHint(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryMuted,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withAlpha(77)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Step 1 of 3',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.primary,
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
          'Upload Study\nNotes',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(height: 1.2),
        ),
        const SizedBox(height: 8),
        Text(
          'Add images or PDFs of your notes. ExamGenie AI will analyse them to create your exam.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildFilesHeader(ThemeData theme) {
    return Row(
      children: [
        Text('Uploaded Files', style: theme.textTheme.titleLarge),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.secondaryMuted,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_uploadedFiles.length}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPreviewHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.folder_open_rounded,
            size: 56,
            color: AppTheme.textMuted.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'File previews will appear here',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.glassBorder, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_uploadedFiles.isNotEmpty) ...[
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: AppTheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_uploadedFiles.length} file${_uploadedFiles.length > 1 ? 's' : ''} ready for analysis',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _uploadedFiles.isNotEmpty ? _proceedToConfig : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: AppTheme.surfaceVariant,
                foregroundColor: Colors.white,
                disabledForegroundColor: AppTheme.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Next: Configure Exam',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _uploadedFiles.isNotEmpty
                          ? Colors.white
                          : AppTheme.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomIconWidget(
                    iconName: 'arrow_forward_rounded',
                    color: _uploadedFiles.isNotEmpty
                        ? Colors.white
                        : AppTheme.textMuted,
                    size: 18,
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

// Inline simple custom icon widget reference — uses core app_export
class CustomIconWidget extends StatelessWidget {
  final String iconName;
  final Color color;
  final double size;

  const CustomIconWidget({
    super.key,
    required this.iconName,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _resolveIcon(iconName);
    return Icon(iconData, color: color, size: size);
  }

  IconData _resolveIcon(String name) {
    const map = {
      'arrow_forward_rounded': Icons.arrow_forward_rounded,
      'check_circle': Icons.check_circle,
      'close': Icons.close,
      'add': Icons.add,
      'remove': Icons.remove,
      'upload_file': Icons.upload_file,
      'image': Icons.image,
      'picture_as_pdf': Icons.picture_as_pdf,
      'delete_outline': Icons.delete_outline,
      'auto_awesome': Icons.auto_awesome,
      'visibility': Icons.visibility,
      'visibility_off': Icons.visibility_off,
      'download': Icons.download,
      'save': Icons.save,
      'refresh': Icons.refresh,
      'expand_more': Icons.expand_more,
      'expand_less': Icons.expand_less,
      'quiz': Icons.quiz,
      'timer': Icons.timer,
      'star': Icons.star,
      'lightbulb': Icons.lightbulb,
      'check': Icons.check,
      'info_outline': Icons.info_outline,
      'folder_open_rounded': Icons.folder_open_rounded,
      'school': Icons.school,
      'bolt': Icons.bolt,
      'tune': Icons.tune,
      'add_photo_alternate': Icons.add_photo_alternate,
      'description': Icons.description,
      'content_copy': Icons.content_copy,
      'share': Icons.share,
      'print': Icons.print,
    };
    return map[name] ?? Icons.circle;
  }
}
