class PauseScreenshotState {
  const PauseScreenshotState({
    this.isReading = false,
    this.extractedText,
    this.errorMessage,
  });

  final bool isReading;
  final String? extractedText;
  final String? errorMessage;

  PauseScreenshotState copyWith({
    bool? isReading,
    String? extractedText,
    String? errorMessage,
    bool clearText = false,
    bool clearError = false,
  }) {
    return PauseScreenshotState(
      isReading: isReading ?? this.isReading,
      extractedText: clearText ? null : (extractedText ?? this.extractedText),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
