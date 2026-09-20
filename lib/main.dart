import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/car_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CarRentalApp());
}

class CarRentalApp extends StatelessWidget {
  const CarRentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CarService(),
      child: MaterialApp(
        title: 'Car Rental App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}