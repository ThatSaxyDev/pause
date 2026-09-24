import 'package:pause_ocr/pause_ocr.dart';

/// Native OCR data source. The notifier owns state transitions; this class
/// keeps the platform OCR dependency out of the view.
class PauseOcrRepository {
  const PauseOcrRepository();

  Future<String> extractText(String imagePath) => PauseOcr.recognize(imagePath);
}
