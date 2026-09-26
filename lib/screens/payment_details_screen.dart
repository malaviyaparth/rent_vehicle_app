import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/payment_record.dart';

/// Screen displaying the full digital receipt and details of a mock payment transaction.
class PaymentDetailsScreen extends StatelessWidget {
  final PaymentRecord payment;

  const PaymentDetailsScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final dateRangeFormat = DateFormat('dd MMM yyyy');

    final isSuccess = payment.status == 'success';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Payment Details'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Transaction ID',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: payment.transactionId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction ID copied to clipboard!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Demo disclaimer banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'DEMO PAYMENT — No real money was charged.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Receipt Card ──
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Status Icon + Title
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSuccess ? Colors.green.shade50 : Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSuccess ? Icons.check_circle : Icons.schedule,
                        color: isSuccess ? Colors.green.shade700 : Colors.blue.shade700,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isSuccess ? 'Payment Successful' : 'Pay at Pickup Scheduled',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSuccess ? Colors.green.shade800 : Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${payment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Transaction attributes
                    _receiptRow(
                      'Transaction ID',
                      payment.transactionId,
                      canCopy: true,
                      context: context,
                      isBold: true,
                    ),
                    const SizedBox(height: 10),
                    _receiptRow(
                      'Date & Time',
                      dateFormat.format(payment.createdAt),
                      context: context,
                    ),
                    const SizedBox(height: 10),
                    _receiptRow(
                      'Payment Method',
                      '${payment.paymentMethod} ${payment.paymentSubMethod.isNotEmpty ? "(${payment.paymentSubMethod})" : ""}',
                      context: context,
                    ),
                    const SizedBox(height: 10),
                    _receiptRow(
                      'Booking ID',
                      payment.bookingId.isNotEmpty ? payment.bookingId : 'N/A',
                      context: context,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Vehicle & Rental Breakdown
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Rental Details',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _receiptRow(
                      'Vehicle',
                      '${payment.carBrand} ${payment.carModel}',
                      context: context,
                      isBold: true,
                    ),
                    if (payment.licensePlate.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _receiptRow(
                        'License Plate',
                        payment.licensePlate,
                        context: context,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _receiptRow(
                      'Duration',
                      '${payment.days} day(s)',
                      context: context,
                    ),
                    const SizedBox(height: 8),
                    _receiptRow(
                      'Dates',
                      '${dateRangeFormat.format(payment.startDate)} to ${dateRangeFormat.format(payment.endDate)}',
                      context: context,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Borrower details
                    _receiptRow('Borrower', payment.userName, context: context),
                    if (payment.userEmail.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _receiptRow('Email', payment.userEmail, context: context),
                    ],
                    const SizedBox(height: 16),

                    // Footer security badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user, size: 16, color: Colors.indigo),
                          SizedBox(width: 6),
                          Text(
                            'Secured by Razorpay Demo Gateway',
                            style: TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(
    String label,
    String value, {
    required BuildContext context,
    bool canCopy = false,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$label copied!')),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.copy, size: 14, color: Colors.indigo),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
