library skypay_pkg;

import 'package:flutter/material.dart';
import 'package:skypay_sdk/constants.dart';
import 'package:skypay_sdk/payment_screen.dart';
import 'package:skypay_sdk/sky_config.dart';

class Skypay {
  static SkyConfig? _skyConfig;

  static initPayment({
    required num amount,
    required String orderId,
    String? successUrl,
    String? failureUrl,
    required Function(Map<String, String> successData) onSuccess,
    required Function(Map<String, String> failureData) onFailure,
    VoidCallback? onCancellation,
  }) async {
    try {
      if (_skyConfig == null) {
        onFailure({"message": "Please initialize the config"});
        return;
      }

      final navigatorState = _skyConfig!.navigatorKey.currentState;

      final paymentLink = Constants.generatePaymentLink(
        accessKey: _skyConfig!.apiKey,
        amount: amount,
        orderId: orderId,
      );

      final result = await navigatorState!.push(MaterialPageRoute(
        builder: (context) {
          return PaymentScreen(
            paymentUrl: paymentLink,
          );
        },
      ));

      if (result == null) {
        if (onCancellation != null) onCancellation();
      } else if (result["status"]) {
        onSuccess(result["data"]);
      } else {
        onFailure(result["data"]);
      }
    } catch (e) {
      onFailure({"message": e.toString()});
    }
  }

  static initConfig(
      {required GlobalKey<NavigatorState> navigatorKey,
      required String apiKey}) {
    _skyConfig ??= SkyConfig(
      navigatorKey: navigatorKey,
      apiKey: apiKey,
    );
  }
}
