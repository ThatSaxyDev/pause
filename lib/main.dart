import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'src/app/pause_app.dart';
import 'src/features/home/pause_home.dart';
import 'src/theme/pause_theme_mode.dart';

Future<void> main() async {
  DartNativePluginRegistrant.registerAll();
  SystemChrome.defaultStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  );
  await restorePauseThemeMode();
  runApp(const PauseApp(home: PauseHome()));
}
