import 'package:dartnative/dartnative.dart';

import '../../app/pause_app.dart';
import '../analysis/data/pause_api_client.dart';
import '../../theme/pause_theme.dart';

class PauseHome extends StatefulWidget {
  const PauseHome({super.key});
  @override
  State<PauseHome> createState() => _PauseHomeState();
}

class _PauseHomeState extends State<PauseHome> {
  final _controller = TextEditingController();
  final _api = const PauseApiClient();
  String _mode = 'Link';
  bool _isLoading = false;
  String? _error;
  PauseAnalysis? _analysis;

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty || _isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _analysis = null;
    });
    try {
      final result = await _api.analyse(
        type: _mode == 'Link' ? 'url' : 'text',
        value: value,
      );
      if (mounted) setState(() => _analysis = result);
    } on PauseApiUnavailable {
      if (mounted) {
        setState(
          () => _error =
              'Pause could not reach the checking service. Check your connection and try again.',
        );
      }
    } on PauseApiException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.statusCode == 429
              ? 'Too many checks were requested. Please wait a moment and try again.'
              : 'Pause could not analyse this item right now. Please try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'We could not analyse this item. Please check it and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onPressed: () => setState(() {
                                _mode = item;
                                _controller.clear();
                                _analysis = null;
                                _error = null;
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
                          // DartNative maps a link field to UITextField and a
                          // message field to UITextView. Changing the key
                          // forces that native control to be recreated when
                          // the user switches modes.
                          key: ValueKey('intake-$_mode'),
                          controller: _controller,
                          keyboardType: _mode == 'Link'
                              ? TextInputType.url
                              : TextInputType.multiline,
                          textInputAction: _mode == 'Link'
                              ? TextInputAction.go
                              : TextInputAction.newline,
                          textAlignVertical: _mode == 'Link'
                              ? TextAlignVertical.center
                              : TextAlignVertical.top,
                          minLines: _mode == 'Link' ? null : 4,
                          maxLines: _mode == 'Link' ? 1 : 6,
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
                        title: _isLoading
                            ? 'Checking…'
                            : 'Check this ${_mode.toLowerCase()}',
                        variant: ButtonVariant.filled,
                        color: PauseColors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onPressed: _submit,
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
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _RetryCard(message: _error!, onRetry: _submit),
                ],
                if (_analysis != null) ...[
                  const SizedBox(height: 16),
                  _AnalysisResult(analysis: _analysis!),
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

class _AnalysisResult extends StatelessWidget {
  const _AnalysisResult({required this.analysis});
  final PauseAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isHighRisk = analysis.riskLevel == 'high';
    final isUnableToVerify = analysis.riskLevel == 'unable_to_verify';
    final accent = isHighRisk
        ? PauseColors.red
        : isUnableToVerify
        ? PauseColors.muted
        : PauseColors.blue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: accent, width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHighRisk
                ? 'High risk — pause here'
                : isUnableToVerify
                ? 'Unable to verify'
                : analysis.riskLevel == 'no_known_warning_found'
                ? 'No known warning found'
                : 'Caution — verify independently',
            style: TextStyle(
              color: accent,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            analysis.summary,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            analysis.guidance,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          for (final item in analysis.evidence) ...[
            const SizedBox(height: 14),
            Text(
              item.title,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.detail,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
          for (final action in analysis.safeActions) ...[
            const SizedBox(height: 16),
            Text(
              action.label,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              action.url,
              style: const TextStyle(
                color: PauseColors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RetryCard extends StatelessWidget {
  const _RetryCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF4A2020)
            : PauseColors.redSoft,
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unable to check right now',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Button(
            title: 'Try again',
            variant: ButtonVariant.bordered,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onPressed: onRetry,
          ),
        ],
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
