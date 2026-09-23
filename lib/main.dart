import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'src/app/pause_app.dart';
import 'src/features/home/pause_home.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  SystemChrome.defaultStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  );
  runApp(const PauseApp(home: PauseHome()));
}
