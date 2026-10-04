import 'package:flutter_test/flutter_test.dart';
import 'package:rent_vehicle/models/car.dart';
import 'package:rent_vehicle/models/rental_record.dart';
import 'package:rent_vehicle/models/review.dart';

void main() {
  group('Vehicle Rating Tests', () {
    test('New vehicle defaults to 0.0 rating and 0 count with "No ratings yet"', () {
      final car = Car(
        id: 'car1',
        ownerId: 'owner1',
        licensePlate: 'GJ01AB1234',
        brand: 'Hyundai',
        model: 'Creta',
        year: 2022,
        pricePerDay: 2500,
        description: 'Clean SUV',
      );

      expect(car.averageRating, 0.0);
      expect(car.totalRatings, 0);
      expect(car.hasRatings, false);
      expect(car.ratingText, 'No ratings yet');
    });

    test('Rating calculation formula: ((oldAvg * total) + newRating) / (total + 1)', () {
      double oldAverage = 0.0;
      int totalRatings = 0;

      // Review 1: 5.0 stars
      double newRating1 = 5.0;
      int newTotal1 = totalRatings + 1;
      double newAverage1 = ((oldAverage * totalRatings) + newRating1) / newTotal1;
      expect(newAverage1, 5.0);

      // Review 2: 4.0 stars
      oldAverage = newAverage1;
      totalRatings = newTotal1;
      double newRating2 = 4.0;
      int newTotal2 = totalRatings + 1;
      double newAverage2 = ((oldAverage * totalRatings) + newRating2) / newTotal2;
      expect(newAverage2, 4.5);

      // Review 3: 4.0 stars
      oldAverage = newAverage2;
      totalRatings = newTotal2;
      double newRating3 = 4.0;
      int newTotal3 = totalRatings + 1;
      double newAverage3 = ((oldAverage * totalRatings) + newRating3) / newTotal3;
      // (4.5 * 2 + 4.0) / 3 = 13 / 3 = 4.3333... -> rounded to 1 decimal place: 4.3
      expect(double.parse(newAverage3.toStringAsFixed(1)), 4.3);
    });

    test('RentalRecord hasRated tracks review submission state', () {
      final rental = RentalRecord(
        id: 'rental1',
        carId: 'car1',
        carBrand: 'Hyundai',
        carModel: 'Creta',
        licensePlate: 'GJ01AB1234',
        ownerId: 'owner1',
        userId: 'user1',
        userName: 'John Doe',
        days: 2,
        pricePerDay: 2500,
        totalPrice: 5000,
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        status: 'completed',
        hasRated: false,
      );

      expect(rental.isCompleted, true);
      expect(rental.hasRated, false);

      rental.hasRated = true;
      expect(rental.hasRated, true);
    });

    test('Review model serialization and deserialization', () {
      final now = DateTime.now();
      final review = Review(
        id: 'rev1',
        carId: 'car1',
        rentalId: 'rent1',
        userId: 'user1',
        userName: 'Alex Smith',
        rating: 4.5,
        comment: 'Great ride and smooth handling!',
        createdAt: now,
      );

      final map = review.toMap();
      expect(map['carId'], 'car1');
      expect(map['rating'], 4.5);
      expect(map['comment'], 'Great ride and smooth handling!');

      final restored = Review.fromMap('rev1', {
        'carId': 'car1',
        'rentalId': 'rent1',
        'userId': 'user1',
        'userName': 'Alex Smith',
        'rating': 4.5,
        'comment': 'Great ride and smooth handling!',
        'createdAt': now.toIso8601String(),
      });

      expect(restored.carId, 'car1');
      expect(restored.rating, 4.5);
      expect(restored.userName, 'Alex Smith');
    });
  });
}
