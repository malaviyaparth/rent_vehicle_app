import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rental_record.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';

/// Shows an interactive dialog for rating and reviewing a completed vehicle rental.
Future<bool?> showRatingDialog(BuildContext context, RentalRecord rental) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => RatingDialog(rental: rental),
  );
}

class RatingDialog extends StatefulWidget {
  final RentalRecord rental;

  const RatingDialog({super.key, required this.rental});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _selectedRating = 0.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _getSentimentLabel(double rating) {
    if (rating == 1.0) return 'Poor (1.0 ★)';
    if (rating == 2.0) return 'Fair (2.0 ★)';
    if (rating == 3.0) return 'Good (3.0 ★)';
    if (rating == 4.0) return 'Very Good (4.0 ★)';
    if (rating == 5.0) return 'Excellent! (5.0 ★)';
    return 'Tap a star to rate';
  }

  Future<void> _submitRating() async {
    if (_selectedRating < 1.0) {
      setState(() {
        _errorMessage = 'Please select a rating between 1 and 5 stars.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final reviewService = context.read<ReviewService>();
      final currentUser = authService.currentUser!;

      await reviewService.addReview(
        carId: widget.rental.carId,
        rentalId: widget.rental.id,
        userId: currentUser.uid,
        userName: currentUser.name.trim().isNotEmpty
            ? currentUser.name.trim()
            : widget.rental.userName,
        rating: _selectedRating,
        comment: _commentController.text,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF059669),
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Thank you! Your review has been submitted.'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header Icon & Title ──
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 34,
                  color: Color(0xFFD97706),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Center(
              child: Text(
                'Rate Your Trip',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 4),

            Center(
              child: Text(
                '${widget.rental.carBrand} ${widget.rental.carModel}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            Center(
              child: Text(
                widget.rental.licensePlate,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 16),

            // ── Interactive Star Rating Bar ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = (index + 1).toDouble();
                final isSelected = starValue <= _selectedRating;

                return GestureDetector(
                  onTap: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _selectedRating = starValue;
                            _errorMessage = null;
                          });
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedScale(
                      scale: isSelected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 38,
                        color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

            // Sentiment Label
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _getSentimentLabel(_selectedRating),
                  key: ValueKey<double>(_selectedRating),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _selectedRating > 0
                        ? const Color(0xFFD97706)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Optional Comment Input ──
            const Text(
              'Your Review (Optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _commentController,
              enabled: !_isSubmitting,
              maxLines: 3,
              maxLength: 300,
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'Share feedback about vehicle cleanliness, ride comfort, performance...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            const SizedBox(height: 16),

            // ── Action Buttons ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
