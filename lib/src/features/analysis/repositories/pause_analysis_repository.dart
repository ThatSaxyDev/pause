import '../data/pause_api_client.dart';

/// Domain-facing boundary for the manual-analysis API.
///
/// Keeping the client behind this repository lets the notifier be tested with
/// a fake repository and gives future local history/cache work one home.
class PauseAnalysisRepository {
  const PauseAnalysisRepository(this._client);

  final PauseApiClient _client;

  Future<PauseAnalysis> analyse({required String type, required String value}) {
    return _client.analyse(type: type, value: value);
  }
}
