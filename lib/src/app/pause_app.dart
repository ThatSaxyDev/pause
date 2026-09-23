import 'package:dartnative/dartnative.dart';

import '../theme/pause_theme.dart';
import '../theme/pause_theme_mode.dart';

class PauseApp extends StatelessWidget {
  const PauseApp({super.key, required this.home});
  final Widget home;

  @override
  Widget build(BuildContext context) {
    final selectedTheme = pauseThemeMode.watch(context);
    final systemBrightness = pauseSystemBrightness.watch(context);
    final useDarkTheme =
        selectedTheme == PauseThemeMode.dark ||
        (selectedTheme == PauseThemeMode.system &&
            systemBrightness == Brightness.dark);
    final activeTheme = useDarkTheme ? PauseTheme.dark : PauseTheme.light;
    return App(
      // App retains theme state internally. Re-key it when the preference
      // changes so ThemeData and the native appearance update as one unit.
      key: ValueKey(
        'pause-app-theme-${selectedTheme.name}-${activeTheme.brightness.name}',
      ),
      title: 'Pause',
      debugShowCheckedModeBanner: false,
      // Resolve System ourselves from MediaQuery. This avoids a DartNative
      // ThemeMode.system issue where the native shell changes but Theme.of
      // retains the previous palette.
      theme: activeTheme,
      darkTheme: activeTheme,
      themeMode: ThemeMode.light,
      home: home,
    );
  }
}
