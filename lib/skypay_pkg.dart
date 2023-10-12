library skypay_pkg;

import 'package:flutter/material.dart';
import 'package:skypay_pkg/constants.dart';
import 'package:skypay_pkg/payment_screen.dart';
import 'package:skypay_pkg/sky_config.dart';

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
        accessKey: _skyConfig!.accessKey,
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
      required String accessKey}) {
    _skyConfig = SkyConfig(
      navigatorKey: navigatorKey,
      accessKey: accessKey,
    );
  }
}
