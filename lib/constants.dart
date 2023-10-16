class Constants {
  static const String paymentUrl =
      "https://pay.skybase.com.np/payments/initiate?";
  static const String lsu = "https://pay.skybase.com.np/payments/success";
  static const String lfu = "https://pay.skybase.com.np/payments/failure";

  static generatePaymentLink({
    required String apiKey,
    required num amount,
    required String orderId,
    String? successUrl = lsu,
    String? failureUrl = lfu,
  }) {
    var paymentLink = paymentUrl;

    paymentLink += "access_key=$apiKey";
    paymentLink += "&amount=$amount";
    paymentLink += "&success_url=$successUrl";
    paymentLink += "&failure_url=$failureUrl";
    paymentLink += "&order_id=$orderId";
    paymentLink += "&type=Internal";

    return paymentLink;
  }
}
