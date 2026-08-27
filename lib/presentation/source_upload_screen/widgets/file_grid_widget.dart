import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../source_upload_screen.dart' show CustomIconWidget;

class FileGridWidget extends StatelessWidget {
  final List<Map<String, dynamic>> files;
  final Function(int) onRemove;
  final int columns;

  const FileGridWidget({
    super.key,
    required this.files,
    required this.onRemove,
    this.columns = 3,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        return _FileCard(
          file: files[index],
          onRemove: () => onRemove(index),
          index: index,
        );
      },
    );
  }
}

class _FileCard extends StatefulWidget {
  final Map<String, dynamic> file;
  final VoidCallback onRemove;
  final int index;

  const _FileCard({
    required this.file,
    required this.onRemove,
    required this.index,
  });

  @override
  State<_FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<_FileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(_entranceController);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  bool _isImageFile(String ext) {
    return ['jpg', 'jpeg', 'png', 'heic', 'webp'].contains(ext.toLowerCase());
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    final ext = widget.file['extension'] as String? ?? 'file';
    final name = widget.file['name'] as String? ?? 'file';
    final size = widget.file['size'] as int? ?? 0;
    final bytes = widget.file['bytes'] as Uint8List?;
    final isImage = _isImageFile(ext);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview area
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (isImage && bytes != null)
                        Image.memory(
                          bytes,
                          fit: BoxFit.cover,
                          semanticLabel: 'Preview of $name',
                        )
                      else
                        Container(
                          color: AppTheme.surface,
                          child: Center(
                            child: CustomIconWidget(
                              iconName: ext == 'pdf'
                                  ? 'picture_as_pdf'
                                  : 'description',
                              color: ext == 'pdf'
                                  ? AppTheme.error
                                  : AppTheme.secondary,
                              size: 32,
                            ),
                          ),
                        ),
                      // Remove button
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: widget.onRemove,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(166),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CustomIconWidget(
                                iconName: 'close',
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // File info
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatSize(size),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
