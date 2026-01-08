import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';

class SkyPayBrowser extends InAppBrowser {
  final Function(String url)? onURLChanged;
  final VoidCallback? onBrowserExit;

  SkyPayBrowser({this.onURLChanged, this.onBrowserExit});

  @override
  void onLoadStart(Uri? url) {
    if (url != null) {
      onURLChanged?.call(url.toString());
    }
  }

  @override
  void onLoadStop(Uri? url) {
    if (url != null) {
      onURLChanged?.call(url.toString());
    }
  }

  @override
  void onReceivedError(WebResourceRequest request, WebResourceError error) {
    onURLChanged?.call(request.url.toString());
  }

  @override
  void onExit() {
    onBrowserExit?.call();
  }

  @override
  Future<ServerTrustAuthResponse?>? onReceivedServerTrustAuthRequest(
    URLAuthenticationChallenge challenge,
  ) async {
    return ServerTrustAuthResponse(
      action: ServerTrustAuthResponseAction.PROCEED,
    );
  }
}

class PaymentScreen extends StatefulWidget {
  final ProcessData processData;
  final String? successUrl;
  final String? failureUrl;
  final Function(bool success)? onFinished;

  const PaymentScreen({
    super.key,
    required this.processData,
    this.successUrl,
    this.failureUrl,
    this.onFinished,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late SkyPayBrowser _browser;

  @override
  void initState() {
    super.initState();
    _browser = SkyPayBrowser(
      onURLChanged: (url) {
        // Log URL for debugging if needed
        debugPrint('SkyPay Browser URL: $url');

        bool isSuccess =
            widget.successUrl != null && url.contains(widget.successUrl!);
        bool isFailure =
            widget.failureUrl != null && url.contains(widget.failureUrl!);

        // Fallback detection for common patterns
        if (!isSuccess && !isFailure) {
          if (url.contains('status=Completed') ||
              url.contains('checkout.skypay.dev/handle')) {
            isSuccess = true;
          } else if (url.contains('status=Failed') ||
              url.contains('status=Canceled')) {
            isFailure = true;
          }
        }

        if (isSuccess || isFailure) {
          _browser.close();
          // The onBrowserExit callback below will handle the Navigator.pop(isSuccess)
        }
      },
      onBrowserExit: () {
        if (mounted) {
          // Check if we hit a success pattern before exiting
          // For now, we'll assume false unless we programmatically triggered closure with success detection elsewhere (which we can't easily track here without a local flag)
          // But to be safe, if they close it, we take them back to CheckoutView.
          Navigator.of(context).pop(false);
        }
      },
    );

    // Faster auto launch
    Future.microtask(_launchBrowser);
  }

  void _launchBrowser() async {
    if (widget.processData.method == 'POST' &&
        widget.processData.fields != null) {
      // For POST, we might need to handle it differently if InAppBrowser doesn't support easy POST with fields.
      // Usually, we host a small local HTML or use a WebView with a POST request.
      // For simplicity in this SDK, we'll assume GET if it's a simple URL,
      // or we can use a hidden WebView to submit the form.

      // Let's try to submit via JavaScript if it's POST
      await _browser.openUrlRequest(
        urlRequest: URLRequest(
          url: WebUri(widget.processData.url!),
          method: 'POST',
          body: Uint8List.fromList(
            utf8.encode(_buildPostData(widget.processData.fields!)),
          ),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
        settings: InAppBrowserClassSettings(
          browserSettings: InAppBrowserSettings(hideToolbarTop: false),
          webViewSettings: InAppWebViewSettings(javaScriptEnabled: true),
        ),
      );
    } else {
      await _browser.openUrlRequest(
        urlRequest: URLRequest(url: WebUri(widget.processData.url!)),
        settings: InAppBrowserClassSettings(
          browserSettings: InAppBrowserSettings(hideToolbarTop: false),
          webViewSettings: InAppWebViewSettings(javaScriptEnabled: true),
        ),
      );
    }
  }

  String _buildPostData(Map<String, dynamic> fields) {
    return fields.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Redirecting to Secure Payment...',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please do not close this window.',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            // Fallback button if auto-launch is blocked
            TextButton.icon(
              onPressed: _launchBrowser,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Tap if you are not redirected'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
