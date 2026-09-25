import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_notifications/dartnative_notifications.dart';

import '../../theme/pause_theme.dart';
import 'pause_guard_platform.dart';
import 'pause_guard_preferences.dart';

class PauseGuardPage extends StatefulWidget {
  const PauseGuardPage({super.key});

  @override
  State<PauseGuardPage> createState() => _PauseGuardPageState();
}

class _PauseGuardPageState extends State<PauseGuardPage>
    with WidgetsBindingObserver {
  PauseGuardSettings? _settings;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final settings = await PauseGuardPreferences.load();
      if (mounted) setState(() => _settings = settings);
    } catch (_) {
      if (mounted) {
        setState(
          () => _settings = const PauseGuardSettings(
            mode: PauseGuardMode.off,
            sourceIds: <String>{},
          ),
        );
      }
    }
  }

  Future<void> _enable() async {
    final current = _settings;
    if (current == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      var updated = current.copyWith(
        mode: PauseGuardMode.localOnly,
        sourceIds: current.sourceIds.isEmpty
            ? PauseGuardPreferences.availableSources
                  .map((source) => source.packageName)
                  .toSet()
            : current.sourceIds,
      );
      await PauseGuardPreferences.save(updated);
      if (mounted) setState(() => _settings = updated);
      if (!updated.warningPermissionRequested) {
        updated = updated.copyWith(warningPermissionRequested: true);
        await PauseGuardPreferences.save(updated);
        if (mounted) setState(() => _settings = updated);
        if (!await DartNativeNotifications.requestPermission()) {
          _showMessage(
            'Allow Pause notifications in app settings to receive warnings.',
          );
        }
      }
      _openNotificationAccess();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _disable() async {
    final current = _settings;
    if (current == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final updated = current.copyWith(mode: PauseGuardMode.off);
      await PauseGuardPreferences.save(updated);
      if (mounted) setState(() => _settings = updated);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleSource(String packageName) async {
    final current = _settings;
    if (current == null || _isSaving) return;
    final sources = Set<String>.from(current.sourceIds);
    if (!sources.add(packageName)) sources.remove(packageName);
    final updated = current.copyWith(sourceIds: sources);
    setState(() => _isSaving = true);
    try {
      await PauseGuardPreferences.save(updated);
      if (mounted) setState(() => _settings = updated);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openNotificationAccess() {
    if (!PauseGuardPlatform.openNotificationAccess()) {
      _showMessage(
        'We could not open Android Settings. Try again in a moment.',
      );
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = _settings;
    final isAndroid = Platform.isAndroid;
    final enabled = settings?.mode == PauseGuardMode.localOnly;
    // MainActivity refreshes this value directly from Android each time the
    // app resumes, so this reflects an external revoke as well as a grant.
    final accessGranted = isAndroid && (settings?.notificationAccessGranted ?? false);
    return Scaffold(
      brightness: Theme.of(context).brightness,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Pause Guard', style: TextStyle(color: scheme.onSurface)),
      ),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Screen notification previews for clear warning signs.',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _GuardStatusPanel(
                      enabled: enabled,
                      accessGranted: accessGranted,
                      isSaving: _isSaving,
                      isAndroid: isAndroid,
                      onEnable: _enable,
                      onOpenAccess: _openNotificationAccess,
                      onDisable: _disable,
                    ),
                    if (isAndroid && enabled && accessGranted) ...[
                      const SizedBox(height: 32),
                      Text(
                        'Checked apps',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Only selected apps are checked. Exclude an app at any time.',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...PauseGuardPreferences.availableSources.map(
                        (source) => _SourceRow(
                          source: source,
                          isAllowed: settings.sourceIds.contains(
                            source.packageName,
                          ),
                          enabled: !_isSaving,
                          onTap: () => _toggleSource(source.packageName),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _GuardStatusPanel extends StatelessWidget {
  const _GuardStatusPanel({
    required this.enabled,
    required this.accessGranted,
    required this.isSaving,
    required this.isAndroid,
    required this.onEnable,
    required this.onOpenAccess,
    required this.onDisable,
  });

  final bool enabled;
  final bool accessGranted;
  final bool isSaving;
  final bool isAndroid;
  final VoidCallback onEnable;
  final VoidCallback onOpenAccess;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ready = enabled && accessGranted;
    final needsAccess = enabled && !accessGranted;
    final title = ready
        ? 'Guard is on'
        : needsAccess
        ? 'Finish setup'
        : 'Guard is off';
    final detail = ready
        ? 'Selected previews are redacted before Pause checks them. Pause does not retain the notification text.'
        : needsAccess
        ? 'Allow Notification Access to start checking previews.'
        : 'Pause redacts selected previews before checking them for warning signs.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ready ? scheme.primaryContainer : scheme.surface,
        border: Border.all(color: ready ? PauseColors.blue : scheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: ready ? PauseColors.blue : scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  MaterialSymbolsRounded.shield,
                  color: ready ? Colors.white : PauseColors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            detail,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          if (!isAndroid)
            _PrimaryButton(title: 'Available on Android', onPressed: null)
          else if (needsAccess)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PrimaryButton(
                  title: 'Open notification access',
                  onPressed: isSaving ? null : onOpenAccess,
                ),
                const SizedBox(height: 10),
                Text(
                  'Can’t open it? Settings → Apps → Special app access → Notification access → Pause.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            )
          else if (!enabled)
            _PrimaryButton(
              title: 'Turn on Pause Guard',
              onPressed: isSaving ? null : onEnable,
            )
          else
            Button(
              title: 'Turn Guard off',
              variant: ButtonVariant.bordered,
              foregroundColor: PauseColors.blue,
              height: 44,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              onPressed: isSaving ? null : onDisable,
            ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.title, required this.onPressed});
  final String title;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Button(
    title: title,
    variant: ButtonVariant.filled,
    color: PauseColors.blue,
    foregroundColor: Colors.white,
    width: double.infinity,
    height: 46,
    fontWeight: FontWeight.w700,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    onPressed: onPressed,
  );
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.source,
    required this.isAllowed,
    required this.enabled,
    required this.onTap,
  });
  final PauseGuardSource source;
  final bool isAllowed;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              source.label,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Button(
            title: isAllowed ? 'Exclude' : 'Include',
            variant: ButtonVariant.bordered,
            foregroundColor: PauseColors.blue,
            height: 40,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            onPressed: enabled ? onTap : null,
          ),
        ],
      ),
    );
  }
}
