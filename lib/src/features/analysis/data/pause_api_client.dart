import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../app/pause_api_config.dart';

class PauseAnalysis {
  const PauseAnalysis({
    required this.riskLevel,
    required this.riskScore,
    required this.summary,
    required this.guidance,
    required this.urls,
    required this.evidence,
    required this.safeActions,
  });

  factory PauseAnalysis.fromJson(Map<String, dynamic> json) => PauseAnalysis(
    riskLevel: (json['risk'] as Map<String, dynamic>)['level'] as String,
    riskScore: (json['risk'] as Map<String, dynamic>)['score'] as int,
    summary: (json['risk'] as Map<String, dynamic>)['summary'] as String,
    guidance: (json['risk'] as Map<String, dynamic>)['guidance'] as String,
    urls: (json['urls'] as List<dynamic>)
        .map((item) => (item as Map<String, dynamic>)['original'] as String)
        .toList(),
    evidence: (json['evidence'] as List<dynamic>)
        .map((item) => PauseEvidence.fromJson(item as Map<String, dynamic>))
        .toList(),
    safeActions: (json['safeActions'] as List<dynamic>)
        .map((item) => PauseSafeAction.fromJson(item as Map<String, dynamic>))
        .toList(),
  );

  final String riskLevel;
  final int riskScore;
  final String summary;
  final String guidance;
  final List<String> urls;
  final List<PauseEvidence> evidence;
  final List<PauseSafeAction> safeActions;
}

class PauseEvidence {
  const PauseEvidence({
    required this.severity,
    required this.title,
    required this.detail,
  });

  factory PauseEvidence.fromJson(Map<String, dynamic> json) => PauseEvidence(
    severity: json['severity'] as String,
    title: json['title'] as String,
    detail: json['detail'] as String,
  );

  final String severity;
  final String title;
  final String detail;
}

class PauseSafeAction {
  const PauseSafeAction({required this.label, required this.url});

  factory PauseSafeAction.fromJson(Map<String, dynamic> json) =>
      PauseSafeAction(
        label: json['label'] as String,
        url: json['url'] as String,
      );

  final String label;
  final String url;
}

class PauseApiClient {
  const PauseApiClient({this.baseUrl});

  final String? baseUrl;

  Future<PauseAnalysis> analyse({
    required String type,
    required String value,
  }) async {
    try {
      return await _request(
        type: type,
        value: value,
      ).timeout(const Duration(seconds: 12));
    } on TimeoutException catch (_) {
      throw const PauseApiUnavailable();
    }
  }

  Future<PauseAnalysis> _request({
    required String type,
    required String value,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final root = baseUrl == null
          ? PauseApiConfig.baseUri
          : Uri.parse(baseUrl!);
      final request = await client.postUrl(root.resolve('/v1/analyses'));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.write(
        jsonEncode({
          'input': {'type': type, 'value': value},
          'context': {'source': 'paste', 'locale': 'en-NG'},
        }),
      );
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != 200) {
        throw PauseApiException(statusCode: response.statusCode);
      }
      return PauseAnalysis.fromJson(jsonDecode(body) as Map<String, dynamic>);
    } on HttpException catch (_) {
      throw const PauseApiUnavailable();
    } on SocketException catch (_) {
      throw const PauseApiUnavailable();
    } on TimeoutException catch (_) {
      throw const PauseApiUnavailable();
    } finally {
      client.close(force: true);
    }
  }
}

class PauseApiUnavailable implements Exception {
  const PauseApiUnavailable();
}

class PauseApiException implements Exception {
  const PauseApiException({required this.statusCode});
  final int statusCode;
}
