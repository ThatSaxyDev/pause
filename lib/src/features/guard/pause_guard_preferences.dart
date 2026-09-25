import 'package:dartnative_shared_preferences/dartnative_shared_preferences.dart';

enum PauseGuardMode { off, localOnly }

extension PauseGuardModeCopy on PauseGuardMode {
  String get storedValue => switch (this) {
    PauseGuardMode.off => 'off',
    PauseGuardMode.localOnly => 'local_only',
  };
}

/// Preference keys are shared with the Android listener. Keep content out of
/// this store: it is for the user's choices and short-lived listener metadata.
abstract final class PauseGuardPreferences {
  static const modeKey = 'pause.guard.mode';
  static const sourcesKey = 'pause.guard.sources';
  static const warningPermissionRequestedKey =
      'pause.guard.warning_permission_requested';
  static const notificationAccessGrantedKey =
      'pause.guard.notification_access_granted';
  static const pendingIntakeKey = 'pause.guard.pending_intake';

  static const availableSources = <PauseGuardSource>[
    PauseGuardSource('com.google.android.apps.messaging', 'Messages'),
    PauseGuardSource('com.android.mms', 'SMS messages'),
    PauseGuardSource('com.whatsapp', 'WhatsApp'),
    PauseGuardSource('com.google.android.gm', 'Gmail'),
  ];

  static Future<PauseGuardSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final storedMode = preferences.getString(modeKey);
    final storedSources = preferences.getString(sourcesKey);
    final sourceIds = storedSources == null
        ? <String>{}
        : storedSources.split(',').where((value) => value.isNotEmpty).toSet();
    return PauseGuardSettings(
      mode: storedMode == PauseGuardMode.localOnly.storedValue
          ? PauseGuardMode.localOnly
          : PauseGuardMode.off,
      sourceIds: sourceIds,
      notificationAccessGranted:
          preferences.getString(notificationAccessGrantedKey) == 'true',
      warningPermissionRequested:
          preferences.getBool(warningPermissionRequestedKey) ?? false,
    );
  }

  static Future<void> save(PauseGuardSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(modeKey, settings.mode.storedValue);
    await preferences.setString(sourcesKey, settings.sourceIds.join(','));
    await preferences.setBool(
      warningPermissionRequestedKey,
      settings.warningPermissionRequested,
    );
  }

  /// Returns a redacted Guard handoff once, then removes it immediately.
  /// This is intentionally transient: source notification text is never kept
  /// as a history item by Guard.
  static Future<String?> takePendingIntake() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(pendingIntakeKey);
    if (value != null) await preferences.remove(pendingIntakeKey);
    return value;
  }
}

class PauseGuardSource {
  const PauseGuardSource(this.packageName, this.label);
  final String packageName;
  final String label;
}

class PauseGuardSettings {
  const PauseGuardSettings({
    required this.mode,
    required this.sourceIds,
    this.notificationAccessGranted = false,
    this.warningPermissionRequested = false,
  });

  final PauseGuardMode mode;
  final Set<String> sourceIds;
  final bool notificationAccessGranted;
  final bool warningPermissionRequested;

  PauseGuardSettings copyWith({
    PauseGuardMode? mode,
    Set<String>? sourceIds,
    bool? notificationAccessGranted,
    bool? warningPermissionRequested,
  }) => PauseGuardSettings(
    mode: mode ?? this.mode,
    sourceIds: sourceIds ?? this.sourceIds,
    notificationAccessGranted:
        notificationAccessGranted ?? this.notificationAccessGranted,
    warningPermissionRequested:
        warningPermissionRequested ?? this.warningPermissionRequested,
  );
}
