import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../api_client.dart';
import 'payment_screen.dart';
import 'copiable_text.dart';

class CheckoutView extends StatefulWidget {
  final SkyPayClient client;
  final SkyPayIntent intent;
  final Function(SkyPayment)? onPaymentCompleted;
  final Function(String)? onError;

  const CheckoutView({
    super.key,
    required this.client,
    required this.intent,
    this.onPaymentCompleted,
    this.onError,
  });

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  bool _isLoading = true;
  List<PaymentProvider> _providers = [];
  UserDetails? _userDetails;
  SkyPayment? _activePayment;
  PaymentProvider? _selectedProvider;
  Timer? _pollingTimer;
  bool _isVerifying = false;
  bool _proceededToManual = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        widget.client.getProviders(),
        widget.client.getUserDetails(),
        widget.client.initializePayment(widget.intent),
      ]);

      setState(() {
        _providers = results[0] as List<PaymentProvider>;
        _userDetails = results[1] as UserDetails;
        _activePayment = results[2] as SkyPayment;
        _isLoading = false;
      });

      if (_activePayment?.status == 'waiting') {
        _startPollingAndProcessing();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showErrorDialog(e.toString());
      widget.onError?.call(e.toString());
    }
  }

  void _startPollingAndProcessing() {
    setState(() {
      _isVerifying = true;
    });
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_activePayment == null || !mounted) return;
      try {
        final payment = await widget.client.getPaymentStatus(
          _activePayment!.id,
        );
        if (mounted) {
          setState(() {
            _activePayment = payment;
            if (payment.isTerminal) {
              _isVerifying = false;
            }
          });
        }
        if (payment.isTerminal) {
          timer.cancel();
          if (payment.isSuccess) {
            widget.onPaymentCompleted?.call(payment);
            _showSuccessDialog(payment);
          }
        }
      } catch (e) {
        // Silently fail
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(
          message.replaceFirst('Exception: ', ''),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(SkyPayment payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaction ID: ${payment.id}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(payment);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                'Back to Merchant',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectProvider(PaymentProvider provider) async {
    if (_isVerifying) return;
    setState(() {
      _selectedProvider = provider;
      _isLoading = true;
    });

    try {
      final updatedPayment = await widget.client.updatePayment(
        _activePayment!.id,
        {'user_payment_provider_id': provider.id},
      );

      if (mounted) {
        setState(() {
          _activePayment = updatedPayment;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showErrorDialog(e.toString());
      widget.onError?.call(e.toString());
    }
  }

  Future<void> _proceedToPayment() async {
    if (_selectedProvider == null || _activePayment == null || _isLoading)
      return;

    if (_selectedProvider!.mode == 'Manual') {
      setState(() => _proceededToManual = true);
    } else {
      await _handleRedirect(_activePayment!);
    }
  }

  Future<void> _handleRedirect(SkyPayment payment) async {
    if (payment.processData == null) return;
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          processData: payment.processData!,
          successUrl: payment.successUrl,
          failureUrl: payment.failureUrl,
        ),
      ),
    );

    if (success == true) {
      _startPollingAndProcessing();
    } else {
      // User cancelled or closed the browser
      final message = 'Payment cancelled by user.';
      _showErrorDialog(message);
      widget.onError?.call(message);
    }
  }

  Future<void> _markAsPaid() async {
    if (_activePayment == null || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final updated = await widget.client.updatePayment(_activePayment!.id, {
        'status': 'waiting',
      });
      if (mounted) {
        setState(() {
          _activePayment = updated;
          _isLoading = false;
        });
      }
      _startPollingAndProcessing();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showErrorDialog(e.toString());
      widget.onError?.call(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Column(
            children: [
              Text(
                _userDetails?.businessName ?? 'SkyPay',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                'Secure Payment Gateway',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () {
              if (_isVerifying) return;
              if (_proceededToManual && _activePayment?.status != 'waiting') {
                setState(() => _proceededToManual = false);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  (_userDetails?.businessName ?? 'S')[0],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            _isLoading && _providers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader()
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: -0.1),
                        const SizedBox(height: 24),
                        if (!_proceededToManual) ...[
                          const Text(
                            'Choose Payment Method',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 16),
                          _buildProviderGrid(),
                          if (_selectedProvider != null) ...[
                            const SizedBox(height: 24),
                            _buildSelectedMethodInfo()
                                .animate()
                                .fadeIn(delay: 100.ms)
                                .slideY(begin: 0.05),
                            const SizedBox(height: 16),
                            _buildPriceSummary()
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .slideY(begin: 0.05),
                            const SizedBox(height: 32),
                            _buildProceedButton().animate().fadeIn(
                              delay: 300.ms,
                            ),
                          ],
                        ] else ...[
                          _buildManualFlow(),
                        ],
                      ],
                    ),
                  ),
            if (_isVerifying) _buildProcessingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Verifying Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please wait while we confirm your transaction...',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
                .animate()
                .scale(duration: 400.ms, curve: Curves.easeOutBack)
                .fadeIn(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Code',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '#${widget.intent.code}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Amount',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF475569),
                ),
              ),
              Text(
                'Rs. ${widget.intent.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        final provider = _providers[index];
        final isSelected = _selectedProvider?.id == provider.id;
        return _buildProviderCard(provider, index, isSelected);
      },
    );
  }

  Widget _buildProviderCard(
    PaymentProvider provider,
    int index,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => _selectProvider(provider),
      borderRadius: BorderRadius.circular(16),
      child:
          Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.blue : const Color(0xFFF1F5F9),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? Colors.blue.withOpacity(0.05)
                          : Colors.black.withOpacity(0.01),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.white,
                          ),
                        ).animate().scale(duration: 200.ms),
                      ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.network(
                              provider.logoUrl,
                              height: 28,
                              width: 28,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.payment,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 11,
                              color: isSelected
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: (200 + (50 * index)).ms)
              .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut),
    );
  }

  Widget _buildSelectedMethodInfo() {
    if (_selectedProvider == null) return const SizedBox.shrink();

    final mode = _selectedProvider!.mode;
    Color badgeColor;
    String description;

    switch (mode) {
      case 'Manual':
        badgeColor = Colors.purple;
        description = 'Follow the steps to complete your payment manually.';
        break;
      case 'Assisted':
      case 'API':
        badgeColor = Colors.blue;
        description =
            'You will be securely redirected to ${_selectedProvider!.name}\'s portal.';
        break;
      default:
        badgeColor = Colors.grey;
        description = 'Proceed to secure your payment.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.network(
                      _selectedProvider!.logoUrl,
                      height: 18,
                      width: 18,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _selectedProvider!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  mode == 'Manual' ? 'Manual' : 'Redirect',
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    final payment = _activePayment;
    if (payment == null) return const SizedBox.shrink();

    final subtotal = payment.amount;
    final fee = payment.providerFee;
    final vat = payment.vatAmount;
    final total = subtotal + fee + vat;
    final hasBreakdown = fee > 0 || vat > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBreakdown) ...[
            _buildPriceRow('Subtotal', subtotal),
            if (fee > 0) _buildPriceRow('Provider Fee', fee),
            if (vat > 0) _buildPriceRow('VAT (13%)', vat),
            const SizedBox(height: 12),
            _buildDottedDivider(),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total to Pay',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Rs. ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDottedDivider() {
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 1,
            color: const Color(0xFFF1F5F9),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          Text(
            'Rs. ${value.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProceedButton() {
    return ElevatedButton(
      onPressed: _isLoading || _isVerifying ? null : _proceedToPayment,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Proceed to Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
    );
  }

  Widget _buildManualFlow() {
    final data = _activePayment?.data;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0F0FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF0066FF), size: 18),
                  SizedBox(width: 10),
                  Text(
                    'Follow These Steps',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003399),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStep(1, 'Scan the QR code below using your banking app.'),
              _buildStep(2, 'Transfer the exact amount displayed below.'),
              _buildStep(3, 'Tap "Mark as Paid" to complete verification.'),
            ],
          ),
        ).animate().fadeIn().slideX(begin: -0.05),
        const SizedBox(height: 20),
        _buildAccountDetails(data),
        const SizedBox(height: 20),
        _buildQRCode(data),
        const SizedBox(height: 32),
        if (!_isVerifying) _buildMarkAsPaidButton(),
      ],
    );
  }

  Widget _buildMarkAsPaidButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _markAsPaid,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.check_circle_outline),
      label: Text(_isLoading ? 'Processing...' : 'Mark as Paid'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(60),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildStep(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: const Color(0xFF0066FF).withOpacity(0.1),
            child: Text(
              num.toString(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0066FF),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF003399),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetails(Map<String, dynamic>? data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Account Name',
            data?['account_name'] ?? 'Loading...',
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildDetailRow(
            'Account Number',
            data?['account_number'] ?? 'Loading...',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
        SkyCopiableText(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildQRCode(Map<String, dynamic>? data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          const Text(
            'Scan QR Code',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          if (data?['image_url'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                data!['image_url'],
                height: 180,
                width: 180,
                fit: BoxFit.contain,
              ),
            )
          else
            Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Scan with any mobile banking app',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }
}
