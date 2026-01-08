export 'src/models.dart';
import 'package:flutter/material.dart';
import 'src/models.dart';
import 'src/api_client.dart';
import 'src/ui/checkout_view.dart';

class SkyPay {
  static SkyPay? _instance;
  late final SkyPayClient _client;

  SkyPay._internal(String apiKey, {String? baseUrl, bool debug = false}) {
    _client = SkyPayClient(
      apiKey: apiKey,
      baseUrl: baseUrl ?? 'https://api.skypay.dev/api/v1/checkout',
      debug: debug,
    );
  }

  /// Initialize the SkyPay SDK with your API key.
  static void init(String apiKey, {String? baseUrl, bool debug = false}) {
    _instance = SkyPay._internal(apiKey, baseUrl: baseUrl, debug: debug);
  }

  static SkyPay get instance {
    if (_instance == null) {
      throw Exception(
        'SkyPay SDK not initialized. Call SkyPay.init(apiKey) first.',
      );
    }
    return _instance!;
  }

  /// Start a payment process.
  /// This will open a bottom sheet or a full-screen view with the payment providers.
  Future<SkyPayment?> startPayment(
    BuildContext context, {
    required SkyPayIntent intent,
    Function(SkyPayment)? onPaymentCompleted,
    Function(String)? onError,
  }) {
    return Navigator.of(context).push<SkyPayment>(
      MaterialPageRoute(
        builder: (context) => CheckoutView(
          client: _client,
          intent: intent,
          onPaymentCompleted: onPaymentCompleted,
          onError: onError,
        ),
      ),
    );
  }
}
