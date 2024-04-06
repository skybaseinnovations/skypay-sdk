class Constants {
  static const String paymentUrl =
      "https://app-uat.skypay.dev/checkout?";
  static const String lsu = "https://pay.skybase.com.np/success";
  static const String lfu = "https://pay.skybase.com.np/failure";

  static generatePaymentLink({
    required String apiKey,
    required num amount,
    required String orderId,
    String? successUrl = lsu,
    String? failureUrl = lfu,
  }) {
    var paymentLink = paymentUrl;

    paymentLink += "api_key=$apiKey";
    paymentLink += "&amount=$amount";
    paymentLink += "&success_url=$successUrl";
    paymentLink += "&failure_url=$failureUrl";
    paymentLink += "&code=$orderId";
    paymentLink += "&type=Internal";

    return paymentLink;
  }
}
