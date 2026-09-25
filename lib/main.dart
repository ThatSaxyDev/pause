import 'package:dartnative/dartnative.dart';
import 'package:dartnative_notifications/dartnative_notifications.dart';

import 'dartnative_plugin_registrant.dart';
import 'src/app/pause_app.dart';
import 'src/app/pause_shell.dart';
import 'src/theme/pause_theme_mode.dart';

Future<void> main() async {
  DartNativePluginRegistrant.registerAll();
  DartNativeNotifications.setup();
  SystemChrome.defaultStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  );
  await restorePauseThemeMode();
  runApp(const PauseApp(home: PauseShell()));
}
