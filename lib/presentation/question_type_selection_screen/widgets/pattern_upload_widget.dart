import 'dart:io' if (dart.library.io) 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../theme/app_theme.dart';
import '../../source_upload_screen/source_upload_screen.dart'
    show CustomIconWidget;

class PatternUploadWidget extends StatelessWidget {
  final Map<String, dynamic>? patternFile;
  final Function(Map<String, dynamic>) onPatternSelected;
  final VoidCallback onPatternRemoved;

  const PatternUploadWidget({
    super.key,
    required this.patternFile,
    required this.onPatternSelected,
    required this.onPatternRemoved,
  });

  Future<void> _pickPattern(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: kIsWeb,
      );
      if (result != null && result.files.isNotEmpty) {
        final f = result.files.first;
        Uint8List? bytes;
        if (kIsWeb) {
          bytes = f.bytes;
        } else {
          if (f.path != null) bytes = await File(f.path!).readAsBytes();
        }
        onPatternSelected({
          'name': f.name,
          'bytes': bytes,
          'path': kIsWeb ? null : f.path,
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (patternFile != null) {
      return _buildPreview(context);
    }
    return _buildUploadZone(context);
  }

  Widget _buildUploadZone(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickPattern(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.glassBorder,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.secondaryMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'add_photo_alternate',
                  color: AppTheme.secondary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Upload past exam / marking scheme',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Optional — helps AI match the exam format',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final bytes = patternFile!['bytes'] as Uint8List?;
    final name = patternFile!['name'] as String? ?? 'Pattern';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.secondaryMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withAlpha(77)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: bytes != null
                ? Image.memory(
                    bytes,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    semanticLabel: 'Pattern reference image: $name',
                  )
                : Container(
                    width: 52,
                    height: 52,
                    color: AppTheme.surfaceVariant,
                    child: const Center(
                      child: CustomIconWidget(
                        iconName: 'image',
                        color: AppTheme.secondary,
                        size: 24,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pattern reference uploaded',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppTheme.secondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onPatternRemoved,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.glassBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'close',
                  color: AppTheme.textSecondary,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
