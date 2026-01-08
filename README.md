# SkyPay SDK v2 for Flutter

Seamless payment integration for Flutter with SkyPay SDK – Simplify and secure payments in your apps effortlessly.

## Features

- **Easy Initialization**: Initialize with a single line of code.
- **Provider List**: Automatically fetches and displays available payment providers.
- **In-App Browser**: Handles payment redirects securely using `flutter_inappwebview`.
- **Status Polling**: Automatically polls for payment status updates.
- **Support for All Modes**: API, Manual, and Assisted payment modes.

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  skypay_sdk:
    git:
      url: https://github.com/skybaseinnovations/skypay-sdk.git
```

## Usage

### 1. Initialize the SDK

Initialize the SDK in your `main()` method or before starting a payment.

```dart
import 'package:skypay_sdk/skypay_sdk.dart';

void main() {
  SkyPay.init('YOUR_API_KEY');
  runApp(MyApp());
}
```

### 2. Start a Payment Intent

Create a `SkyPayIntent` and call `startPayment`.

```dart
void _handlePayment() {
  final intent = SkyPayIntent(
    amount: 100.0,
    code: 'ORD-12345',
    successUrl: 'https://yourdomain.com/success',
    failureUrl: 'https://yourdomain.com/failure',
  );

  SkyPay.instance.startPayment(
    context,
    intent: intent,
    onPaymentCompleted: (payment) {
      print('Payment Successful: ${payment.id}');
    },
    onError: (message) {
      print('Payment Error: $message');
    },
  );
}
```

## Example

Check the `example` directory for a full demonstration.

## License

MIT
