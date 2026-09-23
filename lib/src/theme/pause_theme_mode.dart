import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_android/dartnative_android.dart';
import 'package:dartnative_ios/dartnative_ios.dart';
import 'package:dartnative_shared_preferences/dartnative_shared_preferences.dart';

/// The user's explicit appearance preference. System is the default and
/// follows the device whenever its appearance changes.
enum PauseThemeMode { system, light, dark }

extension PauseThemeModePlatform on PauseThemeMode {
  ThemeMode get dartNativeValue => switch (this) {
    PauseThemeMode.system => ThemeMode.system,
    PauseThemeMode.light => ThemeMode.light,
    PauseThemeMode.dark => ThemeMode.dark,
  };

  Brightness? get platformBrightness => switch (this) {
    PauseThemeMode.system => null,
    PauseThemeMode.light => Brightness.light,
    PauseThemeMode.dark => Brightness.dark,
  };

  String get label => switch (this) {
    PauseThemeMode.system => 'System',
    PauseThemeMode.light => 'Light',
    PauseThemeMode.dark => 'Dark',
  };
}

const _themePreferenceKey = 'pause.appearance';
final pauseThemeMode = signal<PauseThemeMode>(PauseThemeMode.system);
final pauseSystemBrightness = signal<Brightness>(Brightness.light);

/// The root app cannot read MediaQuery directly. The active screen reports
/// the platform value here so System always resolves to the device palette.
void updatePauseSystemBrightness(Brightness brightness) {
  if (pauseSystemBrightness.value != brightness) {
    pauseSystemBrightness.value = brightness;
  }
}

/// Reads the operating system's appearance directly, rather than the app's
/// inherited theme. This remains accurate after returning from Settings.
Brightness readPauseSystemBrightness() {
  try {
    final isDark = Platform.isIOS
        ? IOSNativeBindings.instance.systemIsDark()
        : Platform.isAndroid
        ? AndroidNativeBindings.instance.systemIsDark()
        : false;
    return isDark ? Brightness.dark : Brightness.light;
  } catch (_) {
    return pauseSystemBrightness.value;
  }
}

/// Restores the last choice before the first frame. A missing or invalid
/// preference deliberately falls back to System.
Future<void> restorePauseThemeMode() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_themePreferenceKey);
    final mode = PauseThemeMode.values.where((value) => value.name == stored);
    if (mode.isNotEmpty) {
      _applyThemeMode(mode.first);
      return;
    }
  } catch (_) {
    // Appearance is a convenience preference; it must never block launch.
  }
  _applyThemeMode(PauseThemeMode.system);
}

/// Applies the selection to both Pause's widget tree and the native shell,
/// then persists it for the next launch.
Future<void> setPauseThemeMode(PauseThemeMode mode) async {
  _applyThemeMode(mode);
  if (mode == PauseThemeMode.system) {
    updatePauseSystemBrightness(readPauseSystemBrightness());
  }
  try {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themePreferenceKey, mode.name);
  } catch (_) {
    // Keep the selected appearance for this session if persistence is absent.
  }
}

void _applyThemeMode(PauseThemeMode mode) {
  pauseThemeMode.value = mode;
  setAppBrightness(mode.platformBrightness);
}
