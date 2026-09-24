import 'package:dartnative/dartnative.dart';

enum AttachmentSource { camera, gallery }

class AttachmentSourceSheet extends StatelessWidget {
  const AttachmentSourceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SourceOption(
            label: 'Take a photo',
            detail: 'Use your camera',
            onTap: () => Navigator.pop(context, AttachmentSource.camera),
          ),
          const Divider(height: 1),
          _SourceOption(
            label: 'Choose from gallery',
            detail: 'Select an existing image',
            onTap: () => Navigator.pop(context, AttachmentSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
