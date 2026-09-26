import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../models/rental_record.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import 'payment_success_screen.dart';

/// Professional Razorpay-style Mock Payment Gateway screen.
/// Supports UPI, Card, Net Banking, and Pay at Pickup with dynamic calculation,
/// simulated 2-3s gateway delay, duplicate prevention, and Firestore persistence.
class PaymentGatewayScreen extends StatefulWidget {
  final Car car;
  final DateTime startDate;
  final int days;
  final double totalPrice;

  const PaymentGatewayScreen({
    super.key,
    required this.car,
    required this.startDate,
    required this.days,
    required this.totalPrice,
  });

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  String _selectedMethod = 'UPI';

  // UPI fields
  String _selectedUpiApp = 'Google Pay';
  final _upiIdController = TextEditingController(text: 'demo@razorpay');

  // Card fields
  final _cardNumberController = TextEditingController(text: '4111 2222 3333 4444');
  final _cardExpiryController = TextEditingController(text: '12/28');
  final _cardCvvController = TextEditingController(text: '123');
  final _cardHolderController = TextEditingController();

  // Net Banking
  String _selectedBank = 'HDFC Bank';
  final List<String> _popularBanks = [
    'HDFC Bank',
    'State Bank of India',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'Punjab National Bank',
  ];

  bool _isProcessing = false;
  String _processingStep = '';

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    _cardHolderController.text = (user != null && user.name.isNotEmpty)
        ? user.name
        : 'Demo Borrower';
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  DateTime get _endDate => widget.startDate.add(Duration(days: widget.days));

  String get _paymentSubMethod {
    switch (_selectedMethod) {
      case 'UPI':
        return _selectedUpiApp;
      case 'Card':
        final cleanNum = _cardNumberController.text.replaceAll(' ', '');
        final last4 = cleanNum.length >= 4 ? cleanNum.substring(cleanNum.length - 4) : '4444';
        return 'Card ending in $last4';
      case 'Net Banking':
        return _selectedBank;
      case 'Pay at Pickup':
        return 'Cash/UPI at vehicle pickup';
      default:
        return '';
    }
  }

  Future<void> _handlePayment() async {
    if (_isProcessing) return; // Prevent double taps

    final authService = context.read<AuthService>();
    final paymentService = context.read<PaymentService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to proceed with payment.')),
      );
      return;
    }

    // Owner protection check
    if (currentUser.isOwner || widget.car.ownerId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owners cannot rent vehicles.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingStep = 'Connecting to Razorpay Demo Gateway...';
    });

    // Show processing modal
    _showProcessingDialog();

    final rental = RentalRecord(
      id: '',
      carId: widget.car.id,
      carBrand: widget.car.brand,
      carModel: widget.car.model,
      licensePlate: widget.car.licensePlate,
      ownerId: widget.car.ownerId,
      userId: currentUser.uid,
      userName: currentUser.name.isNotEmpty ? currentUser.name : currentUser.email,
      userEmail: currentUser.email,
      userPhone: currentUser.phone,
      days: widget.days,
      pricePerDay: widget.car.pricePerDay,
      totalPrice: widget.totalPrice,
      startDate: widget.startDate,
      endDate: _endDate,
      status: 'confirmed',
    );

    try {
      // Step update during simulated delay
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted && _isProcessing) {
          setState(() => _processingStep = 'Authorizing with simulated banking gateway...');
        }
      });
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted && _isProcessing) {
          setState(() => _processingStep = 'Securing transaction & confirming booking...');
        }
      });

      final payment = await paymentService.processMockPayment(
        rental: rental,
        paymentMethod: _selectedMethod,
        paymentSubMethod: _paymentSubMethod,
        userEmail: currentUser.email,
      );

      if (!mounted) return;

      // Dismiss dialog
      Navigator.of(context, rootNavigator: true).pop();

      setState(() => _isProcessing = false);

      // Navigate to Payment Result & Confirmation screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(payment: payment),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Dismiss dialog
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          content: Text('Payment Failed: $e'),
        ),
      );
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Processing Payment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder: (ctx, setDialogState) {
                      return Text(
                        _processingStep.isNotEmpty
                            ? _processingStep
                            : 'Connecting to Demo Gateway...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: const Text(
                      'DEMO MODE • Please do not close this window',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C2340), // Razorpay dark navy
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.shield, color: Colors.cyanAccent, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Razorpay',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amberAccent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'DEMO',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Razorpay Navy Accent Banner ──
          Container(
            width: double.infinity,
            color: const Color(0xFF0C2340),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.car.brand} ${widget.car.model}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${dateFormat.format(widget.startDate)} – ${dateFormat.format(_endDate)} (${widget.days}d)',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Amount', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    Text(
                      '₹${widget.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Prominent Demo Warning Banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              border: Border(bottom: BorderSide(color: Colors.amber.shade300)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.brown),
                SizedBox(width: 8),
                Text(
                  'DEMO PAYMENT — No real money will be charged.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ],
            ),
          ),

          // ── Payment Methods & Form ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Order summary breakdown card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Breakdown',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${widget.car.pricePerDay.toStringAsFixed(0)} × ${widget.days} day(s)',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                            Text(
                              '₹${widget.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Platform / Demo Fee', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                            const Text('₹0.00 (FREE)', style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Payable', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            Text(
                              '₹${widget.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Select Payment Method',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),

                // Method 1: UPI
                _methodTile(
                  title: 'UPI / QR Code',
                  subtitle: 'Google Pay, PhonePe, Paytm, BHIM',
                  icon: Icons.qr_code,
                  methodKey: 'UPI',
                ),

                // Method 2: Cards
                _methodTile(
                  title: 'Cards (Credit / Debit)',
                  subtitle: 'Visa, MasterCard, RuPay, Maestro',
                  icon: Icons.credit_card,
                  methodKey: 'Card',
                ),

                // Method 3: Net Banking
                _methodTile(
                  title: 'Net Banking',
                  subtitle: 'All Indian banks supported',
                  icon: Icons.account_balance,
                  methodKey: 'Net Banking',
                ),

                // Method 4: Pay at Pickup
                _methodTile(
                  title: 'Pay at Pickup',
                  subtitle: 'Pay cash or UPI directly at vehicle pickup',
                  icon: Icons.handshake,
                  methodKey: 'Pay at Pickup',
                ),

                const SizedBox(height: 16),

                // Expanded inputs for selected method
                _buildSelectedMethodView(),
              ],
            ),
          ),

          // ── Bottom Razorpay Action CTA ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Secured by Razorpay • 256-Bit SSL Demo Gateway',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0C2340),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isProcessing ? null : _handlePayment,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        _selectedMethod == 'Pay at Pickup'
                            ? 'Confirm Booking (Pay ₹${widget.totalPrice.toStringAsFixed(2)} at Pickup)'
                            : 'Pay ₹${widget.totalPrice.toStringAsFixed(2)} [DEMO]',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String methodKey,
  }) {
    final isSelected = _selectedMethod == methodKey;

    return Card(
      elevation: isSelected ? 2 : 0.5,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? Colors.indigo : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected ? Colors.indigo.shade50 : Colors.grey.shade100,
          child: Icon(icon, color: isSelected ? Colors.indigo : Colors.grey.shade700),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.indigo.shade900 : Colors.black87,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: isSelected ? Colors.indigo : Colors.grey,
        ),
        onTap: () => setState(() => _selectedMethod = methodKey),
      ),
    );
  }

  Widget _buildSelectedMethodView() {
    switch (_selectedMethod) {
      case 'UPI':
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select UPI App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Google Pay', 'PhonePe', 'Paytm', 'BHIM'].map((app) {
                    final sel = _selectedUpiApp == app;
                    return ChoiceChip(
                      label: Text(app),
                      selected: sel,
                      onSelected: (_) => setState(() => _selectedUpiApp = app),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _upiIdController,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID / VPA',
                    hintText: 'e.g. username@okhdfcbank',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.alternate_email),
                    helperText: 'Pre-filled demo VPA for test simulation',
                  ),
                ),
              ],
            ),
          ),
        );

      case 'Card':
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Card Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _cardNumberController.text = '4111 2222 3333 4444';
                          _cardExpiryController.text = '12/28';
                          _cardCvvController.text = '123';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Demo test card details filled!')),
                        );
                      },
                      icon: const Icon(Icons.auto_fix_high, size: 16),
                      label: const Text('Autofill Demo Card', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cardExpiryController,
                        decoration: const InputDecoration(
                          labelText: 'Valid Thru (MM/YY)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _cardCvvController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _cardHolderController,
                  decoration: const InputDecoration(
                    labelText: 'Cardholder Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
              ],
            ),
          ),
        );

      case 'Net Banking':
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choose Your Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedBank,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  items: _popularBanks.map((bank) {
                    return DropdownMenuItem(value: bank, child: Text(bank));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBank = val);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Simulation: Login and authorization will be completed in demo test mode.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );

      case 'Pay at Pickup':
        return Card(
          elevation: 1,
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.shade200),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.indigo, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Pay at Pickup Instructions',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Your booking will be reserved instantly. You can pay the total rental amount directly to the vehicle owner using Cash or UPI when picking up the keys.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
