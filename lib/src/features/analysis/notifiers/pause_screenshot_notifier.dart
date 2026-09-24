import 'package:dartnative/dartnative.dart';
import 'package:pause_ocr/pause_ocr.dart';

import 'pause_analysis_notifier.dart';
import '../repositories/pause_ocr_repository.dart';
import '../state/pause_screenshot_state.dart';

/// Coordinates local screenshot text extraction independently of the view.
class PauseScreenshotNotifier {
  PauseScreenshotNotifier(this._repository, this._analysisNotifier);

  final PauseOcrRepository _repository;
  final PauseAnalysisNotifier _analysisNotifier;
  final state = signal<PauseScreenshotState>(const PauseScreenshotState());

  /// Runs one screenshot through local OCR, then the existing analysis flow.
  Future<void> analyseImage(String imagePath) async {
    if (state.value.isReading) return;
    state.value = const PauseScreenshotState(isReading: true);
    _analysisNotifier.beginNewIntake();
    try {
      final text = await _repository.extractText(imagePath);
      if (text.trim().isEmpty) {
        state.value = const PauseScreenshotState(
          errorMessage: 'No text was found. You can type or paste it instead.',
        );
        return;
      }
      state.value = PauseScreenshotState(extractedText: text);
      await _analysisNotifier.analyse(text);
    } on PauseOcrException catch (error) {
      state.value = PauseScreenshotState(errorMessage: error.message);
    } catch (_) {
      state.value = const PauseScreenshotState(
        errorMessage: 'We could not read that image. Try another one.',
      );
    }
  }

  /// Rechecks user-edited OCR text through the shared analysis notifier.
  Future<void> analyseEditedText(String text) =>
      _analysisNotifier.analyse(text);

  /// Clears all derived screenshot and result state; the typed input stays put.
  void clearAll() {
    state.value = const PauseScreenshotState();
    _analysisNotifier.clear();
  }
}

final pauseScreenshotNotifier = PauseScreenshotNotifier(
  const PauseOcrRepository(),
  pauseAnalysisNotifier,
);
