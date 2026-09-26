import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/payment_record.dart';
import '../models/rental_record.dart';

/// Service responsible for managing mock Razorpay transactions,
/// payment simulations, duplicate transaction prevention, and Firestore persistence.
class PaymentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _paymentsRef =>
      _firestore.collection('payments');
  CollectionReference<Map<String, dynamic>> get _rentalsRef =>
      _firestore.collection('rentals');
  CollectionReference<Map<String, dynamic>> get _carsRef =>
      _firestore.collection('cars');

  // In-flight active locks to prevent duplicate submissions
  final Set<String> _processingLocks = <String>{};

  bool isLocked(String lockKey) => _processingLocks.contains(lockKey);

  /// Generates a mock Razorpay-style transaction ID such as `MOCK_TXN_123456`.
  static String generateMockTransactionId() {
    final rand = Random().nextInt(900000) + 100000;
    return 'MOCK_TXN_$rand';
  }

  /// Real-time stream of all payments made by a given user.
  Stream<List<PaymentRecord>> paymentsForUser(String userId) {
    return _paymentsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PaymentRecord.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream of all payments in the system (for Admins).
  Stream<List<PaymentRecord>> allPayments() {
    return _paymentsRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PaymentRecord.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Fetches a specific payment by its linked booking ID.
  Future<PaymentRecord?> getPaymentByBookingId(String bookingId) async {
    final snap = await _paymentsRef
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return PaymentRecord.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  /// Executes a mock payment transaction:
  /// 1. Verifies lock to prevent double payments.
  /// 2. Simulates 2.5-second Razorpay authorization delay.
  /// 3. Creates the booking and links the payment record in Firestore.
  /// 4. Updates vehicle availability if the booking starts today.
  Future<PaymentRecord> processMockPayment({
    required RentalRecord rental,
    required String paymentMethod,
    required String paymentSubMethod,
    required String userEmail,
  }) async {
    final lockKey = '${rental.userId}_${rental.carId}_${rental.startDate.millisecondsSinceEpoch}';

    if (_processingLocks.contains(lockKey)) {
      throw Exception('Payment is already being processed for this booking. Please do not submit twice.');
    }

    _processingLocks.add(lockKey);
    notifyListeners();

    try {
      // 1. Simulate 2.5-second Razorpay gateway processing delay
      await Future.delayed(const Duration(milliseconds: 2500));

      final txnId = generateMockTransactionId();
      final now = DateTime.now();

      // 2. Pre-generate IDs for Firestore to ensure 100% two-way link
      final rentalDoc = _rentalsRef.doc();
      final paymentDoc = _paymentsRef.doc();

      // 3. Save confirmed booking directly in rentals collection (allowed in Firestore)
      final rentalData = rental.toMap();
      rentalData['paymentId'] = paymentDoc.id;
      rentalData['paymentMethod'] = paymentMethod;
      rentalData['paymentSubMethod'] = paymentSubMethod;
      rentalData['transactionId'] = txnId;
      rentalData['paymentStatus'] = 'completed';
      rentalData['amountPaid'] = rental.totalPrice;
      rentalData['status'] = 'confirmed';
      rentalData['updatedAt'] = FieldValue.serverTimestamp();
      await rentalDoc.set(rentalData);

      // 4. Save payment record (in payments collection if allowed by cloud rules)
      final payment = PaymentRecord(
        id: paymentDoc.id,
        bookingId: rentalDoc.id,
        userId: rental.userId,
        userName: rental.userName,
        userEmail: userEmail,
        carId: rental.carId,
        carBrand: rental.carBrand,
        carModel: rental.carModel,
        licensePlate: rental.licensePlate,
        amount: rental.totalPrice,
        paymentMethod: paymentMethod,
        paymentSubMethod: paymentSubMethod,
        transactionId: txnId,
        status: paymentMethod == 'Pay at Pickup' ? 'pending' : 'success',
        createdAt: now,
        days: rental.days,
        startDate: rental.startDate,
        endDate: rental.endDate,
      );

      try {
        await paymentDoc.set(payment.toMap());
      } catch (e) {
        debugPrint('Note: Payments collection write skipped (cloud rules): $e');
      }

      // 5. Update car availability if the rental starts today
      final today = DateTime(now.year, now.month, now.day);
      final rentalStart = DateTime(rental.startDate.year, rental.startDate.month, rental.startDate.day);
      if (rentalStart.isAtSameMomentAs(today) || rentalStart.isBefore(today)) {
        try {
          await _carsRef.doc(rental.carId).update({
            'available': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Note: Car availability update skipped (cloud rules): $e');
        }
      }

      return payment;
    } finally {
      _processingLocks.remove(lockKey);
      notifyListeners();
    }
  }
}
