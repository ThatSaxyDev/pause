import 'package:dartnative/dartnative.dart';

import '../../theme/pause_theme.dart';

class DetectedLinks extends StatelessWidget {
  const DetectedLinks({super.key, required this.urls, required this.onCheck});

  final List<String> urls;
  final ValueChanged<String> onCheck;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We found ${urls.length} links',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check the full message, or inspect one link on its own.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          for (final url in urls) ...[
            const SizedBox(height: 12),
            Text(
              url,
              style: const TextStyle(
                color: PauseColors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Button(
              title: 'Check this link',
              variant: ButtonVariant.bordered,
              color: scheme.surface,
              foregroundColor: scheme.onSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onPressed: () => onCheck(url),
            ),
          ],
        ],
      ),
    );
  }
}
