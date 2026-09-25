import 'package:flutter_test/flutter_test.dart';
import 'package:skypay_sdk/skypay_sdk.dart';

void main() {
  test('SkyPayIntent serializes to JSON', () {
    final intent = SkyPayIntent(
      amount: 100.0,
      code: 'ORD-12345',
      successUrl: 'https://example.com/success',
      failureUrl: 'https://example.com/failure',
    );

    expect(intent.toJson(), {
      'amount': 100.0,
      'code': 'ORD-12345',
      'success_url': 'https://example.com/success',
      'failure_url': 'https://example.com/failure',
    });
  });
}
