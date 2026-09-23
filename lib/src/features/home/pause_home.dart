import 'package:dartnative/dartnative.dart';

import '../../app/pause_app.dart';
import '../../theme/pause_theme.dart';

class PauseHome extends StatefulWidget {
  const PauseHome({super.key});
  @override
  State<PauseHome> createState() => _PauseHomeState();
}

class _PauseHomeState extends State<PauseHome> {
  final _controller = TextEditingController();
  String _mode = 'Link';
  bool _showPreview = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      brightness: Theme.of(context).brightness,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'pause',
                      style: TextStyle(
                        color: PauseColors.blue,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Button(
                      title: isDark ? 'Light' : 'Dark',
                      variant: ButtonVariant.bordered,
                      onPressed: () => appTheme.value = isDark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    ),
                  ],
                ),
                const SizedBox(height: 42),
                Text(
                  'Pause before\nyou click.',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.04,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Check a suspicious link or message. We explain what to look out for and the safer next step.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: ['Link', 'Message']
                      .map(
                        (item) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: item == 'Link' ? 8 : 0,
                            ),
                            child: Button(
                              title: item,
                              variant: _mode == item
                                  ? ButtonVariant.filled
                                  : ButtonVariant.bordered,
                              color: _mode == item ? PauseColors.blue : null,
                              onPressed: () => setState(() {
                                _mode = item;
                                _showPreview = false;
                              }),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border.all(color: scheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mode == 'Link'
                            ? 'Paste a link to inspect'
                            : 'Paste the message you received',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: _mode == 'Link' ? 58 : 116,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: TextField(
                          controller: _controller,
                          keyboardType: _mode == 'Link'
                              ? TextInputType.url
                              : TextInputType.multiline,
                          maxLines: _mode == 'Link' ? 1 : 4,
                          clearButtonMode: ClearButtonMode.whileEditing,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: _mode == 'Link'
                                ? 'https://example.com'
                                : 'Paste an SMS, email, or chat message',
                            hintStyle: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Button(
                        title: 'Check this ${_mode.toLowerCase()}',
                        variant: ButtonVariant.filled,
                        color: PauseColors.blue,
                        onPressed: () {
                          if (_controller.text.trim().isNotEmpty) {
                            setState(() => _showPreview = true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  color: scheme.surface,
                  foreground: scheme.onSurface,
                  title: 'Check before you act',
                  body:
                      'Pause inspects domains, link tricks, urgency, and known warnings without opening the link.',
                ),
                if (_showPreview) ...[
                  const SizedBox(height: 16),
                  _InfoCard(
                    color: isDark
                        ? const Color(0xFF4A2020)
                        : PauseColors.redSoft,
                    foreground: scheme.onSurface,
                    title: 'Result preview',
                    body:
                        'The live risk engine will explain evidence, not just show a score. It connects to the TypeScript API next.',
                  ),
                ],
                const SizedBox(height: 28),
                Text(
                  'What Pause checks',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const _CheckItem(
                  title: 'Lookalike domains',
                  detail: 'Domains that resemble trusted organisations.',
                ),
                const _CheckItem(
                  title: 'Hidden link tricks',
                  detail: 'Redirects, shorteners, and unusual characters.',
                ),
                const _CheckItem(
                  title: 'Pressure tactics',
                  detail: 'Urgency, threats, and requests for money or codes.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.color,
    required this.foreground,
    required this.title,
    required this.body,
  });
  final Color color;
  final Color foreground;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: foreground,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          body,
          style: TextStyle(color: foreground, fontSize: 14, height: 1.4),
        ),
      ],
    ),
  );
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({required this.title, required this.detail});
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
