class SkyPayIntent {
  final double amount;
  final String code;
  final String? successUrl;
  final String? failureUrl;

  SkyPayIntent({
    required this.amount,
    required this.code,
    this.successUrl,
    this.failureUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'code': code,
      'success_url': successUrl,
      'failure_url': failureUrl,
    };
  }
}

class PaymentProvider {
  final String id;
  final String name;
  final String logoUrl;
  final String mode; // API, Manual, Assisted

  PaymentProvider({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.mode,
  });

  factory PaymentProvider.fromJson(Map<String, dynamic> json) {
    return PaymentProvider(
      id: json['id'].toString(),
      name: json['provider_name'],
      logoUrl: json['provider_logo_url'],
      mode: json['mode'] ?? 'API',
    );
  }
}

class SkyPayment {
  final String id;
  final String status;
  final double amount;
  final String code;
  final String? userProviderId;
  final ProcessData? processData;
  final String? successUrl;
  final String? failureUrl;
  final DateTime? expiresAt;
  final double providerFee;
  final double vatAmount;
  final Map<String, dynamic>? data;

  SkyPayment({
    required this.id,
    required this.status,
    required this.amount,
    required this.code,
    this.userProviderId,
    this.processData,
    this.successUrl,
    this.failureUrl,
    this.expiresAt,
    this.providerFee = 0.0,
    this.vatAmount = 0.0,
    this.data,
  });

  factory SkyPayment.fromJson(Map<String, dynamic> json) {
    return SkyPayment(
      id: json['id'].toString(),
      status: json['status'],
      amount: double.parse(json['amount'].toString()),
      code: json['code'],
      userProviderId: json['user_provider_id']?.toString(),
      processData: json['process_data'] != null
          ? ProcessData.fromJson(json['process_data'])
          : null,
      successUrl: json['success_url'],
      failureUrl: json['failure_url'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      providerFee:
          double.tryParse(json['provider_fee']?.toString() ?? '0.0') ?? 0.0,
      vatAmount:
          double.tryParse(json['vat_amount']?.toString() ?? '0.0') ?? 0.0,
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'])
          : null,
    );
  }

  bool get isTerminal => [
    'complete',
    'completed',
    'success',
    'failed',
    'cancelled',
    'invalid',
  ].contains(status);
  bool get isSuccess => ['complete', 'completed', 'success'].contains(status);

  /// Manual Mode: customer may leave after mark paid when merchant chose continue.
  bool get allowsContinueAfterMarkPaid =>
      (data?['after_mark_paid'] as String?) == 'continue';
}

class ProcessData {
  final String? url;
  final String? method;
  final Map<String, dynamic>? fields;

  ProcessData({this.url, this.method, this.fields});

  factory ProcessData.fromJson(Map<String, dynamic> json) {
    return ProcessData(
      url: json['url'],
      method: json['method'],
      fields: json['fields'] is Map
          ? Map<String, dynamic>.from(json['fields'])
          : null,
    );
  }
}

class UserDetails {
  final String businessName;
  final String? logo;

  UserDetails({required this.businessName, this.logo});

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      businessName: json['business_name'] ?? 'SkyPay Merchant',
      logo: json['logo'],
    );
  }
}
