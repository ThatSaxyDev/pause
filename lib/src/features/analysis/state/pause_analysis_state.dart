import '../data/pause_api_client.dart';

/// Immutable UI state for one manual analysis.
///
/// A single value keeps each transition explicit and prevents the view from
/// having to coordinate loading, error, and result fields independently.
class PauseAnalysisState {
  const PauseAnalysisState({
    this.isLoading = false,
    this.analysis,
    this.errorMessage,
  });

  final bool isLoading;
  final PauseAnalysis? analysis;
  final String? errorMessage;

  PauseAnalysisState copyWith({
    bool? isLoading,
    PauseAnalysis? analysis,
    String? errorMessage,
    bool clearAnalysis = false,
    bool clearError = false,
  }) {
    return PauseAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      analysis: clearAnalysis ? null : (analysis ?? this.analysis),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
