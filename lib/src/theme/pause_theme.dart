import 'package:dartnative/dartnative.dart';

abstract final class PauseColors {
  static const navy = Color(0xFF00101D),
      blue = Color(0xFF156EB7),
      blueSoft = Color(0xFFDCE9F4),
      red = Color(0xFFEA372D),
      redSoft = Color(0xFFF4D9D9),
      ink = Color(0xFF222222),
      muted = Color(0xFF646769),
      line = Color(0xFFE7E8EB),
      canvas = Color(0xFFF7F8FA),
      darkCanvas = Color(0xFF0A0A0A),
      darkSurface = Color(0xFF222222);
}

abstract final class PauseTheme {
  static const light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: PauseColors.canvas,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: PauseColors.blue,
      onPrimary: Colors.white,
      primaryContainer: PauseColors.blueSoft,
      onPrimaryContainer: PauseColors.navy,
      secondary: Color(0xFF0FB016),
      onSecondary: Colors.white,
      error: PauseColors.red,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: PauseColors.ink,
      surfaceContainerHighest: PauseColors.line,
      surfaceContainerHigh: PauseColors.canvas,
      surfaceContainer: Colors.white,
      onSurfaceVariant: PauseColors.muted,
      outline: PauseColors.line,
    ),
  );
  static const dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: PauseColors.darkCanvas,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: PauseColors.blue,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF1F3540),
      onPrimaryContainer: Colors.white,
      secondary: Color(0xFF0FB016),
      onSecondary: PauseColors.navy,
      error: PauseColors.red,
      onError: Colors.white,
      surface: PauseColors.darkSurface,
      onSurface: Colors.white,
      surfaceContainerHighest: Color(0xFF2A2A2A),
      surfaceContainerHigh: PauseColors.darkSurface,
      surfaceContainer: Color(0xFF101010),
      onSurfaceVariant: Color(0xFFA1A4AD),
      outline: Color(0xFF646769),
    ),
  );
}
