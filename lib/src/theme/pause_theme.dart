import 'package:dartnative/dartnative.dart';

abstract final class PauseColors {
  // KwikSim's neutral scale keeps dark mode genuinely neutral. Blue remains
  // an action colour, rather than tinting the app's structural surfaces.
  static const navy = Color(0xFF00101D),
      blue = Color(0xFF156EB7),
      blueSoft = Color(0xFFB9D3E9),
      red = Color(0xFFEA372D),
      redSoft = Color(0xFFF4D9D9),
      ink = Color(0xFF222222),
      muted = Color(0xFF646769),
      line = Color(0xFFE7E8EB),
      canvas = Color(0xFFFCFDFE),
      darkCanvas = Color(0xFF0A0A0A),
      darkSurface = Color(0xFF000000),
      darkContainer = Color(0xFF222222),
      darkContainerHigh = Color(0xFF2A2A2A);
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
      primaryContainer: PauseColors.darkContainer,
      onPrimaryContainer: Colors.white,
      secondary: Color(0xFF0FB016),
      onSecondary: PauseColors.navy,
      error: PauseColors.red,
      onError: Colors.white,
      surface: PauseColors.darkSurface,
      onSurface: Colors.white,
      surfaceContainerHighest: PauseColors.darkContainerHigh,
      surfaceContainerHigh: PauseColors.darkContainer,
      surfaceContainer: Color(0xFF101010),
      onSurfaceVariant: Color(0xFFA1A4AD),
      outline: Color(0xFF646769),
    ),
  );
}
