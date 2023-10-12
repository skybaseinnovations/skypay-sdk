library skypay_pkg;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:skypay_sdk/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  final String paymentUrl;

  const PaymentScreen({super.key, required this.paymentUrl});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;

  double progressValue = 0;
  String url = "";

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.close,
              color: isDarkMode ? Colors.white : Colors.black,
            )),
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        title: Text(
          "Skypay",
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
      ),
      body: Column(
        children: [
          if (progressValue < 1)
            LinearProgressIndicator(
              value: progressValue,
              backgroundColor: const Color(0xFF042948).withOpacity(0.5),
              color: const Color(0xFF042948),
            ),
          Expanded(
            child: InAppWebView(
              key: webViewKey,
              initialUrlRequest: URLRequest(url: Uri.parse(widget.paymentUrl)),
              initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  javaScriptEnabled: true,
                ),
                android: AndroidInAppWebViewOptions(
                  networkAvailable: true,
                ),
              ),
              onWebViewCreated: (controller) async {
                webViewController = controller;
              },
              onLoadStart: (controller, url) {
                this.url = url.toString();
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  progressValue = progress / 100;
                });
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url!;

                if (![
                  "http",
                  "https",
                  "file",
                  "chrome",
                  "data",
                  "javascript",
                  "about"
                ].contains(uri.scheme)) {
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));

                    return NavigationActionPolicy.CANCEL;
                  }
                  return NavigationActionPolicy.ALLOW;
                }
                return null;
              },
              onUpdateVisitedHistory: (controller, url, androidIsReload) {
                this.url = url.toString();
                checkUrl(this.url);
              },
            ),
          ),
        ],
      ),
    );
  }

  void checkUrl(String url) {
    if (url.startsWith(Constants.lsu)) {
      var uri = Uri.parse(url);
      Map<String, String> params = uri.queryParameters;
      Navigator.pop(context, {"status": true, "data": params});
    } else if (url.startsWith(Constants.lfu)) {
      var uri = Uri.parse(url);
      Map<String, String> params = uri.queryParameters;
      Navigator.pop(context, {"status": false, "data": params});
    }
  }
}
