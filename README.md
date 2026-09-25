# SkyPay Flutter SDK — Nepal payment aggregator (eSewa, Khalti & more)

**Simplifying payment aggregator integration in Nepal.**  
Plug-and-play aggregator for developers, startups, and businesses integrating **eSewa**, **Khalti**, and more — **one Flutter SDK**, multiple payment methods.

[Get started](https://app.skypay.dev/signup) · [Documentation](https://skypay.dev/guides) · [pub.dev](https://pub.dev/packages/skypay_sdk)

---

## Features

- **Dynamic providers** — Provider list loads from your SkyPay merchant account
- **API, Manual & Assisted modes** — Supports every integration mode your account enables
- **In-app checkout** — Secure payment redirects via `flutter_inappwebview`
- **Status polling** — Automatic payment status updates
- **One integration** — eSewa, Khalti, Connect IPS, Fonepay, and more behind one SDK

---

## Installation

From pub.dev:

```yaml
dependencies:
  skypay_sdk: ^0.0.6
```

From Git:

```yaml
dependencies:
  skypay_sdk:
    git:
      url: https://github.com/skybaseinnovations/skypay-sdk.git
      ref: main
```

---

## Usage

### 1. Initialize the SDK

Get your API key from the [SkyPay dashboard](https://app.skypay.dev/signup).

```dart
import 'package:skypay_sdk/skypay_sdk.dart';

void main() {
  SkyPay.init('YOUR_API_KEY', debug: true);
  runApp(const MyApp());
}
```

### 2. Start a payment

```dart
final intent = SkyPayIntent(
  amount: 100.0,
  code: 'ORD-12345',
  successUrl: 'https://yourdomain.com/success',
  failureUrl: 'https://yourdomain.com/failure',
);

await SkyPay.instance.startPayment(
  context,
  intent: intent,
  onPaymentCompleted: (payment) {
    // Payment completed on one of the aggregated methods
  },
  onError: (message) {},
);
```

---

## Example

See the [`example/`](example/) directory for a runnable demo app.

---

## Links

| Resource | URL |
| -------- | --- |
| Merchant dashboard | [app.skypay.dev](https://app.skypay.dev/) |
| Documentation | [skypay.dev/guides](https://skypay.dev/guides) |
| Package | [pub.dev/packages/skypay_sdk](https://pub.dev/packages/skypay_sdk) |
| Discord community | [discord.gg/p8u9xZKcxB](https://discord.gg/p8u9xZKcxB) |

---

## License

BSD-3-Clause — see [LICENSE](LICENSE).

Proudly built in Pokhara, Nepal — a product by **Skybase Innovations**.
