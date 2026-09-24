import 'package:pause_mobile/src/features/analysis/intake/pause_intake_sanitizer.dart';
import 'package:test/test.dart';

void main() {
  const sanitizer = PauseIntakeSanitizer();

  test('extracts distinct links and excludes surrounding punctuation', () {
    final preview = sanitizer.prepare(
      'Compare https://frscgov.top/ng, https://frscgov.top/ng and www.frsc.gov.ng.',
    );

    expect(preview.urls, ['https://frscgov.top/ng', 'www.frsc.gov.ng']);
  });

  test('masks sensitive values before remote analysis', () {
    final preview = sanitizer.prepare(
      'Your OTP is 123456. Account: 0123456789. Card 4111 1111 1111 1111.',
    );

    expect(preview.redactedFields, [
      'one-time code',
      'account number',
      'card number',
    ]);
    expect(preview.valueForAnalysis, isNot(contains('123456')));
    expect(preview.valueForAnalysis, isNot(contains('0123456789')));
    expect(preview.valueForAnalysis, isNot(contains('4111 1111 1111 1111')));
  });
}
