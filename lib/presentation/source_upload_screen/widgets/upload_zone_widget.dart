import 'dart:io' if (dart.library.io) 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_theme.dart';
import '../source_upload_screen.dart' show CustomIconWidget;

class UploadZoneWidget extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onFilesAdded;

  const UploadZoneWidget({super.key, required this.onFilesAdded});

  @override
  State<UploadZoneWidget> createState() => _UploadZoneWidgetState();
}

class _UploadZoneWidgetState extends State<UploadZoneWidget>
    with SingleTickerProviderStateMixin {
  final bool _isDragging = false;
  bool _isPickingFiles = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    if (_isPickingFiles) return;
    setState(() => _isPickingFiles = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'heic', 'webp'],
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        final files = <Map<String, dynamic>>[];
        for (final f in result.files) {
          Uint8List? bytes;
          if (kIsWeb) {
            bytes = f.bytes;
          } else {
            if (f.path != null) {
              bytes = await File(f.path!).readAsBytes();
            }
          }
          files.add({
            'name': f.name,
            'extension': f.extension ?? 'file',
            'size': f.size,
            'bytes': bytes,
            'path': kIsWeb ? null : f.path,
          });
        }
        widget.onFilesAdded(files);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick files. Please try again.'),
            backgroundColor: AppTheme.error.withAlpha(230),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingFiles = false);
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      if (kIsWeb) {
        // On web, use file picker with image type
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result != null && result.files.isNotEmpty) {
          final f = result.files.first;
          widget.onFilesAdded([
            {
              'name': f.name,
              'extension': f.extension ?? 'jpg',
              'size': f.size,
              'bytes': f.bytes,
              'path': null,
            },
          ]);
        }
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 90,
        );
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          final name = picked.name;
          widget.onFilesAdded([
            {
              'name': name,
              'extension': 'jpg',
              'size': bytes.length,
              'bytes': bytes,
              'path': kIsWeb ? null : picked.path,
            },
          ]);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Camera unavailable. Please pick from gallery.',
            ),
            backgroundColor: AppTheme.surfaceVariant,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main upload zone
        GestureDetector(
          onTap: _pickFiles,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) =>
                Transform.scale(scale: _isDragging ? 1.02 : 1.0, child: child),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: _isDragging
                    ? AppTheme.primaryMuted
                    : AppTheme.glassBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isDragging ? AppTheme.primary : AppTheme.glassBorder,
                  width: _isDragging ? 2 : 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: _isPickingFiles
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryMuted,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CustomIconWidget(
                              iconName: 'upload_file',
                              color: AppTheme.primary,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Tap to upload files',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'JPG, PNG, PDF, HEIC supported',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary action row
        Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                icon: 'image',
                label: 'From Gallery',
                onTap: _pickFiles,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSecondaryButton(
                icon: 'add_photo_alternate',
                label: 'Camera',
                onTap: _pickFromCamera,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: AppTheme.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
