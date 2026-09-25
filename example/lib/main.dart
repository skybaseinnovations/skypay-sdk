import 'package:flutter/material.dart';
import 'package:skypay_sdk/skypay_sdk.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  // Replace with your SkyPay API key from https://app.skypay.dev
  const apiKey = String.fromEnvironment('SKYPAY_API_KEY', defaultValue: 'YOUR_API_KEY');
  SkyPay.init(apiKey, debug: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkyPay SDK Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
      ),
      home: const PaymentHome(),
    );
  }
}

class PaymentHome extends StatefulWidget {
  const PaymentHome({super.key});

  @override
  State<PaymentHome> createState() => _PaymentHomeState();
}

class _PaymentHomeState extends State<PaymentHome> {
  final _amountController = TextEditingController(text: '100.0');
  bool _isProcessing = false;

  void _startPayment() {
    final amount = double.tryParse(_amountController.text) ?? 100.0;
    final orderCode = 'ORDER-${DateTime.now().millisecondsSinceEpoch}';

    final intent = SkyPayIntent(
      amount: amount,
      code: orderCode,
      successUrl: 'https://example.com/success',
      failureUrl: 'https://example.com/failure',
    );

    SkyPay.instance.startPayment(
      context,
      intent: intent,
      onPaymentCompleted: (payment) {
        debugPrint('Payment Completed Callback: ${payment.id}');
      },
      onError: (message) {
        _showStatus('Error: $message', isError: true);
      },
    ).then((payment) {
      if (payment != null) {
        _showStatus(
          'Payment Successful (Returned)!\nID: ${payment.id}\nStatus: ${payment.status}',
        );
      }
    });
  }

  void _showStatus(String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isError ? 'Error' : 'Payment Status'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SkyPay Example')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter Amount to Pay',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixText: 'Rs. ',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isProcessing ? null : _startPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Pay with SkyPay',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
