## **About**
SkyPay is a comprehensive payment gateway solution in Nepal by SkyBase Innovations. It simplifies integration, boosts developer productivity, reduces costs, and minimizes technical challenges. With options like Manual Entry, Merchant API, and SkyPay Managed, it streamlines online payments and is especially beneficial for developers. It also supports various payment methods, including Khalti, eliminating the need to integrate with individual banks.

## **Pre-requisites**
1. Create your **FREE MERCHANT ACCOUNT** here: [Merchant Registration Page](https://pay.skybase.com.np/register)
2. Download & set up the **Merchant App** from the link available your Dashboard
3. Copy your **Access Key / API** Key provided on your dashboard page

## **Getting Started**
- Import package: ```import 'package:skypay_pkg/skypay_pkg.dart';```
- Create a navigator key in your ```main.dart```
    
    ```bash
    class SkyPayDemoApp extends StatefulWidget {
        final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
         SkyPayDemoApp({super.key});
    ```
- Pass the navigator key in your Material app
    ```bash
    return MaterialApp(
      navigatorKey: widget.navigatorKey,
    ```
- Go to your Skypay dashboard and copy the ```API Key``` from **My Api Key**
</br></br><img src="assets/api_key.png" alt="Markdown Monster icon" style="height: 200px; width:auto;" />

- Override your ```initState``` method with the following
    ```bash
    @override
  void initState() {
    Skypay.initConfig(
        navigatorKey: widget.navigatorKey, 
        apiKey: "870027",
        );
    super.initState();
  }
    ```
    Replace the apiKey with your api key

## Initialize Payment

To initiate a payment, use this code snippet with Skypay. Don't forget to set the orderId and amount as needed. Customize success, failure, and cancellation events to match your app.

```bash
Skypay.initPayment(
    orderId: "123457",
    amount: 100,
    onSuccess: (data) {
        //On Success Event
    },
    onFailure: (data) {
        //On Fail Event
    },
    onCancellation: () {
        //On Cancell Event
    },
);
```

### **Parameters**

| Parameter | Required | Description |  
| --- | --- | --- |
| amount | true | The transaction amount. |  |
| success_url | false | URL to be redirected when payment successful |  |
| failure_url | false | URL to be redirected when payment fails |  |
| order_id | true | Unique identifier for the order (same order_id is available for 10 minutes) |  |

### **Callbacks**

- **onSuccess**: On successful transactions, you can use the onSuccess callback. The function will be invoked on a successful transaction.
  
- **onFailure**: On On failed transactions, you can use the onFailure callback. The function is responsible for handeling fail cases.

- **onCancel**: When user decides to cancel the payment the onCancel function will be invoked.
    

That's it! You've successfully integrated Skybase Payments into your platform. If you have any questions or need further clarification, feel free to reach out to our support team.
