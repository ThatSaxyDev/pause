import 'package:dartnative/dartnative.dart';

import '../data/pause_api_client.dart';
import '../repositories/pause_analysis_repository.dart';
import '../state/pause_analysis_state.dart';

/// Coordinates the manual-check feature without depending on a widget.
///
/// This is the DartNative equivalent of the Riverpod notifier used in
/// KwikSim: it owns state and actions, while its repository owns data access.
class PauseAnalysisNotifier {
  PauseAnalysisNotifier(this._repository);

  final PauseAnalysisRepository _repository;
  final state = signal<PauseAnalysisState>(const PauseAnalysisState());

  Future<void> analyse(String value) async {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty || state.value.isLoading) return;

    state.value = state.value.copyWith(
      isLoading: true,
      clearAnalysis: true,
      clearError: true,
    );

    try {
      final result = await _repository.analyse(
        type: _inputTypeFor(trimmedValue),
        value: trimmedValue,
      );
      state.value = state.value.copyWith(isLoading: false, analysis: result);
    } on PauseApiUnavailable {
      _showError(
        'Pause could not reach the checking service. Check your connection and try again.',
      );
    } on PauseApiException catch (error) {
      _showError(
        error.statusCode == 429
            ? 'Too many checks were requested. Please wait a moment and try again.'
            : 'Pause could not analyse this item right now. Please try again.',
      );
    } catch (_) {
      _showError(
        'We could not analyse this item. Please check it and try again.',
      );
    }
  }

  void _showError(String message) {
    state.value = state.value.copyWith(isLoading: false, errorMessage: message);
  }

  /// Sends one complete URL through the API's URL path. Messages and other
  /// mixed input use the text path, where embedded links are extracted.
  String _inputTypeFor(String value) {
    if (value.contains(RegExp(r'\s')) || value.contains('@')) return 'text';

    final normalized = value.contains('://') ? value : 'https://$value';
    final uri = Uri.tryParse(normalized);
    return uri != null && uri.hasAuthority && uri.host.contains('.')
        ? 'url'
        : 'text';
  }
}

/// App-level holder for the feature. Tests can construct a notifier directly
/// with a fake repository instead of relying on this production instance.
final pauseAnalysisNotifier = PauseAnalysisNotifier(
  PauseAnalysisRepository(const PauseApiClient()),
);
