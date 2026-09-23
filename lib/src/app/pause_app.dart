import 'package:dartnative/dartnative.dart';

import '../theme/pause_theme.dart';

final appTheme = signal<ThemeMode>(ThemeMode.system);

class PauseApp extends StatelessWidget {
  const PauseApp({super.key, required this.home});
  final Widget home;
  @override
  Widget build(BuildContext context) => App(
    title: 'Pause',
    debugShowCheckedModeBanner: false,
    theme: PauseTheme.light,
    darkTheme: PauseTheme.dark,
    themeMode: appTheme.watch(context),
    home: home,
  );
}
