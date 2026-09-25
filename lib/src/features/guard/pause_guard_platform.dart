import 'dart:ffi';
import 'dart:io' show Platform;

/// Narrow Android FFI bridge for the Notification Access system settings.
/// It intentionally exposes no notification content or listener callbacks.
abstract final class PauseGuardPlatform {
  static final DynamicLibrary? _library = Platform.isAndroid
      ? _openLibrary()
      : null;

  static DynamicLibrary? _openLibrary() {
    try {
      return DynamicLibrary.open('libpause_guard_bridge.so');
    } catch (_) {
      return null;
    }
  }

  static bool openNotificationAccess() =>
      _call('pause_guard_open_notification_access');

  static bool get isNotificationAccessGranted =>
      _call('pause_guard_is_notification_access_granted');

  static bool _call(String name) {
    final library = _library;
    if (library == null) return false;
    try {
      return library.lookupFunction<Bool Function(), bool Function()>(name)();
    } catch (_) {
      return false;
    }
  }
}
