import 'package:flutter/material.dart';
import 'package:skypay_sdk/skypay_sdk.dart';

void main() {
  runApp(SkyPayDemoApp());
}

class SkyPayDemoApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(); //Navigator Key
  final String apiKey = "870027"; //Api Key

  SkyPayDemoApp({super.key});

  @override
  State<SkyPayDemoApp> createState() => _SkyPayDemoAppState();
}

class _SkyPayDemoAppState extends State<SkyPayDemoApp> {
  String? message;
  bool isError = false;

  @override
  void initState() {
    // Initialize SkyPay Configuration
    Skypay.initConfig(navigatorKey: widget.navigatorKey, apiKey: widget.apiKey);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return MaterialApp(
      navigatorKey: widget.navigatorKey,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: _makePayment,
                  child: const Text("Pay with Skypay"),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                height: size.height / 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Result",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      message ?? "No Result",
                      style: TextStyle(
                        color: isError ? Colors.red : Colors.black,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _makePayment() {
    // Initialize Payment
    Skypay.initPayment(
      orderId: "123459",
      amount: 100,
      onSuccess: (data) {
        //On Payment Success
        setState(() {
          message = data.toString();
          isError = false;
        });
      },
      onFailure: (data) {
        // On Payment Failed
        setState(() {
          message = data.toString();
          isError = true;
        });
      },
      onCancel: () {
        // On Payment Cancelled
        setState(() {
          message = "Payment Cancelled";
          isError = true;
        });
      },
    );
  }
}
