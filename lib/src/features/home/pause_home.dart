import 'package:dartnative/dartnative.dart';

import '../analysis/data/pause_api_client.dart';
import '../analysis/notifiers/pause_analysis_notifier.dart';
import '../../theme/pause_theme.dart';
import '../../theme/pause_theme_mode.dart';

class PauseHome extends StatefulWidget {
  const PauseHome({super.key});
  @override
  State<PauseHome> createState() => _PauseHomeState();
}

class _PauseHomeState extends State<PauseHome> with WidgetsBindingObserver {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncSystemBrightness();
    });
  }

  @override
  void didChangePlatformBrightness() {
    _syncSystemBrightness();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncSystemBrightness();
      });
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _syncSystemBrightness();
      });
    }
  }

  void _syncSystemBrightness() {
    updatePauseSystemBrightness(readPauseSystemBrightness());
  }

  Future<void> _submit() async {
    await pauseAnalysisNotifier.analyse(_controller.text);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedTheme = pauseThemeMode.watch(context);
    final analysisState = pauseAnalysisNotifier.state.watch(context);
    return Scaffold(
      brightness: Theme.of(context).brightness,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: false,
        title: Container(
          child: const Text(
            'pause',
            style: TextStyle(
              color: PauseColors.blue,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        actions: [
          BarButtonItem(
            title: selectedTheme.label,
            titleStyle: TextStyle(color: scheme.onSurface),
            menu: PauseThemeMode.values
                .map(
                  (mode) => MenuAction(
                    title: mode.label,
                    onTap: () {
                      setPauseThemeMode(mode);
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 24),
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
                      'Paste a link or message to inspect',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 116,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        textAlignVertical: TextAlignVertical.top,
                        minLines: 4,
                        maxLines: 6,
                        clearButtonMode: ClearButtonMode.whileEditing,
                        style: TextStyle(color: scheme.onSurface, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Paste a link, SMS, email, or chat message',
                          hintStyle: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Button(
                      title: analysisState.isLoading
                          ? 'Checking…'
                          : 'Check this',
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
              // const SizedBox(height: 16),
              // _InfoCard(
              //   color: scheme.surface,
              //   foreground: scheme.onSurface,
              //   title: 'Check before you act',
              //   body:
              //       'Pause inspects domains, link tricks, urgency, and known warnings without opening the link.',
              // ),
              if (analysisState.errorMessage != null) ...[
                const SizedBox(height: 16),
                _RetryCard(
                  message: analysisState.errorMessage!,
                  onRetry: _submit,
                ),
              ],
              if (analysisState.isLoading) ...[
                const SizedBox(height: 16),
                const _AnalysisResultShimmer(),
              ],
              if (analysisState.analysis != null) ...[
                const SizedBox(height: 16),
                _AnalysisResult(analysis: analysisState.analysis!),
              ],
              // const SizedBox(height: 28),
              // Text(
              //   'What Pause checks',
              //   style: TextStyle(
              //     color: scheme.onSurface,
              //     fontSize: 18,
              //     fontWeight: FontWeight.w800,
              //   ),
              // ),
              // const SizedBox(height: 12),
              // const _CheckItem(
              //   title: 'Lookalike domains',
              //   detail: 'Domains that resemble trusted organisations.',
              // ),
              // const _CheckItem(
              //   title: 'Hidden link tricks',
              //   detail: 'Redirects, shorteners, and unusual characters.',
              // ),
              // const _CheckItem(
              //   title: 'Pressure tactics',
              //   detail: 'Urgency, threats, and requests for money or codes.',
              // ),
            ],
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

class _AnalysisResultShimmer extends StatefulWidget {
  const _AnalysisResultShimmer();

  @override
  State<_AnalysisResultShimmer> createState() => _AnalysisResultShimmerState();
}

class _AnalysisResultShimmerState extends State<_AnalysisResultShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checking for warning signs',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _ShimmerBar(progress: _controller.value, height: 13),
            const SizedBox(height: 8),
            _ShimmerBar(progress: _controller.value, height: 13, width: 220),
            const SizedBox(height: 18),
            _ShimmerBar(progress: _controller.value, height: 11, width: 142),
            const SizedBox(height: 7),
            _ShimmerBar(progress: _controller.value, height: 11, width: 264),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({
    required this.progress,
    required this.height,
    this.width = double.infinity,
  });

  final double progress;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHigh;
    final highlight = Theme.of(context).brightness == Brightness.dark
        ? scheme.surfaceContainer
        : scheme.surface;
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Container(height: height, color: base),
            Positioned(
              left: (progress * 420) - 88,
              top: 0,
              bottom: 0,
              width: 88,
              child: Opacity(opacity: 0.78, child: Container(color: highlight)),
            ),
          ],
        ),
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

// ignore: unused_element
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

// ignore: unused_element
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
