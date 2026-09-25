import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'constants.dart';

class SkyPayClient {
  final String apiKey;
  final String baseUrl;
  final bool debug;

  SkyPayClient({
    required this.apiKey,
    this.baseUrl = kSkyPayDefaultBaseUrl,
    this.debug = false,
  });

  void _log(String message) {
    if (debug) {
      print('DEBUG [SkyPay]: $message');
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Key': apiKey,
  };

  dynamic _handleResponse(http.Response response, String defaultMessage) {
    _log('Response status: ${response.statusCode}');
    _log('Response body: ${response.body}');

    try {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        return data['data'];
      } else {
        // Capture both message and detailed error if available
        final String message = data['message'] ?? defaultMessage;
        final String? detailedError = data['error'];
        if (detailedError != null && detailedError.isNotEmpty) {
          throw Exception('$message\n$detailedError');
        }
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('$defaultMessage: ${response.statusCode}');
    }
  }

  Future<List<PaymentProvider>> getProviders() async {
    final url = Uri.parse('$baseUrl/providers');
    _log('GET $url');
    final response = await http.get(url, headers: _headers);
    final data = _handleResponse(response, 'Failed to load providers');
    return (data as List)
        .map((json) => PaymentProvider.fromJson(json))
        .toList();
  }

  Future<UserDetails> getUserDetails() async {
    final url = Uri.parse('$baseUrl/user-details');
    _log('GET $url');
    final response = await http.get(url, headers: _headers);
    final data = _handleResponse(response, 'Failed to load user details');
    return UserDetails.fromJson(data);
  }

  Future<SkyPayment> initializePayment(SkyPayIntent intent) async {
    final url = Uri.parse('$baseUrl/initiate');
    final body = jsonEncode(intent.toJson());
    _log('POST $url');
    _log('Request body: $body');
    final response = await http.post(url, headers: _headers, body: body);
    final data = _handleResponse(response, 'Failed to initialize payment');
    return SkyPayment.fromJson(data);
  }

  Future<SkyPayment> updatePayment(
    String paymentId,
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('$baseUrl/payments/$paymentId');
    final body = jsonEncode(payload);
    _log('PATCH $url');
    _log('Request body: $body');
    final response = await http.patch(url, headers: _headers, body: body);
    final data = _handleResponse(response, 'Failed to update payment');
    return SkyPayment.fromJson(data);
  }

  Future<SkyPayment> getPaymentStatus(String paymentId) async {
    final url = Uri.parse('$baseUrl/payments/$paymentId');
    _log('GET $url');
    final response = await http.get(url, headers: _headers);
    final data = _handleResponse(response, 'Failed to get payment status');
    return SkyPayment.fromJson(data);
  }
}
