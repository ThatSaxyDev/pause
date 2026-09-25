import 'package:dartnative/dartnative.dart';

/// A one-shot, already-redacted notification preview delivered after the user
/// taps a Pause warning. PauseHome observes this only to populate its input.
final pauseGuardIncomingText = signal<String?>(null);
