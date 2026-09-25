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
  List<PauseGuardActivity> _activity = const [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final settings = await PauseGuardPreferences.load();
      final activity = await PauseGuardPreferences.loadActivity();
      if (mounted) {
        setState(() {
          _settings = settings;
          _activity = activity;
        });
      }
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

  Future<void> _openAppSettings() async {
    await Navigator.push<void>(
      context,
      PageRoute(builder: (_) => const _GuardAppsPage()),
    );
    _load();
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
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 34, 24, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      const SizedBox(height: 36),
                      Text(
                        'Recent activity',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActivityList(activity: _activity),
                      const SizedBox(height: 32),
                      _SettingsRow(
                        title: 'Apps Guard checks',
                        value: '${settings.sourceIds.length} selected',
                        onTap: _openAppSettings,
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
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (ready)
                Button(
                  title: 'Turn off',
                  variant: ButtonVariant.bordered,
                  foregroundColor: PauseColors.blue,
                  height: 40,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onPressed: isSaving ? null : onDisable,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
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
            const SizedBox.shrink(),
        ],
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

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.activity});
  final List<PauseGuardActivity> activity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (activity.isEmpty) {
      return Text(
        'No warnings yet. Guard records warning signals here, never message text.',
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.4),
      );
    }
    return Column(
      children: activity.take(5).map((entry) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(top: 6, right: 12),
              decoration: const BoxDecoration(color: PauseColors.blue, shape: BoxShape.circle),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.outcome} · ${entry.source}',
                    style: TextStyle(color: scheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${entry.signal ?? 'Suspicious link'} · ${_formatActivityTime(entry.timestamp)}',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

String _formatActivityTime(int timestamp) {
  final value = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.title, required this.value, required this.onTap});
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Button(
      title: '$title · $value',
      width: double.infinity,
      height: 58,
      variant: ButtonVariant.bordered,
      foregroundColor: PauseColors.blue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      onPressed: onTap,
    );
  }
}

class _GuardAppsPage extends StatefulWidget {
  const _GuardAppsPage();
  @override
  State<_GuardAppsPage> createState() => _GuardAppsPageState();
}

class _GuardAppsPageState extends State<_GuardAppsPage> {
  PauseGuardSettings? _settings;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final settings = await PauseGuardPreferences.load();
    if (mounted) setState(() => _settings = settings);
  }
  Future<void> _toggle(String packageName) async {
    final current = _settings;
    if (current == null) return;
    final sources = Set<String>.from(current.sourceIds);
    if (!sources.add(packageName)) sources.remove(packageName);
    final updated = current.copyWith(sourceIds: sources);
    await PauseGuardPreferences.save(updated);
    if (mounted) setState(() => _settings = updated);
  }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = _settings;
    return Scaffold(
      brightness: Theme.of(context).brightness,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Apps Guard checks', style: TextStyle(color: scheme.onSurface))),
      body: settings == null ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Text('Choose the apps whose notification previews Guard can check.', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.4)),
          const SizedBox(height: 18),
          ...PauseGuardPreferences.availableSources.map((source) {
            final included = settings.sourceIds.contains(source.packageName);
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: scheme.outline))),
              child: Row(children: [
                Expanded(child: Text(source.label, style: TextStyle(color: scheme.onSurface, fontSize: 17, fontWeight: FontWeight.w700))),
                Button(title: included ? 'Included' : 'Excluded', variant: ButtonVariant.bordered, foregroundColor: included ? PauseColors.blue : scheme.onSurfaceVariant, height: 38, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), onPressed: () => _toggle(source.packageName)),
              ]),
            );
          }),
        ],
      ),
    );
  }
}
