import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../models/vehicle_enums.dart';
import '../services/car_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import 'location_picker_screen.dart';

class AddEditCarScreen extends StatefulWidget {
  /// If null, we're adding a new vehicle. If provided, we're editing it.
  final Car? car;

  const AddEditCarScreen({super.key, this.car});

  @override
  State<AddEditCarScreen> createState() => _AddEditCarScreenState();
}

class _AddEditCarScreenState extends State<AddEditCarScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _plateController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _imageUrlController;

  String _selectedCategory = 'Car'; // 'Car' or 'TwoWheeler'
  String _selectedSubType = 'Sedan';
  String _selectedFuelType = 'Petrol';
  Map<String, double>? _pickupLocation;

  bool get isEditing => widget.car != null;

  @override
  void initState() {
    super.initState();
    final car = widget.car;
    _plateController = TextEditingController(text: car?.licensePlate ?? '');
    _brandController = TextEditingController(text: car?.brand ?? '');
    _modelController = TextEditingController(text: car?.model ?? '');
    _yearController = TextEditingController(text: car?.year.toString() ?? '');
    _priceController = TextEditingController(text: car?.pricePerDay.toString() ?? '');
    _descController = TextEditingController(text: car?.description ?? '');
    _imageUrlController = TextEditingController(
      text: (car != null && car.imageUrls.isNotEmpty) ? car.imageUrls.first : '',
    );

    if (car != null) {
      _selectedCategory = vehicleCategory(car.vehicleType);
      _selectedSubType = car.vehicleSubType;
      _selectedFuelType = car.fuelType;
      _pickupLocation = car.pickupLocation;
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  bool _isSubmitting = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate pickup location (Section 10).
    if (_pickupLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a pickup location for the vehicle.')),
      );
      return;
    }

    final lat = _pickupLocation!['latitude'];
    final lng = _pickupLocation!['longitude'];
    if (lat == null || lat < -90 || lat > 90 || lng == null || lng < -180 || lng > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid pickup coordinates.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final carService = context.read<CarService>();
    final authService = context.read<AuthService>();
    final plate = _plateController.text.trim().toUpperCase();

    final taken = await carService.isPlateTaken(plate, excludeId: widget.car?.id);
    if (taken) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A vehicle with this license plate already exists.')),
      );
      return;
    }

    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();
    final year = int.parse(_yearController.text.trim());
    final price = double.parse(_priceController.text.trim());
    final desc = _descController.text.trim();
    final imageUrl = _imageUrlController.text.trim();
    final images = imageUrl.isNotEmpty ? [imageUrl] : <String>[];

    try {
      if (isEditing) {
        final updated = widget.car!.copyWith(
          licensePlate: plate,
          brand: brand,
          model: model,
          year: year,
          pricePerDay: price,
          description: desc,
          vehicleType: _selectedCategory,
          vehicleSubType: _selectedSubType,
          fuelType: _selectedFuelType,
          pickupLocation: () => _pickupLocation,
          imageUrls: images,
        );
        await carService.updateCar(updated);
      } else {
        final newCar = Car(
          id: '',
          ownerId: authService.currentUser!.uid,
          licensePlate: plate,
          brand: brand,
          model: model,
          year: year,
          pricePerDay: price,
          description: desc,
          available: true,
          vehicleType: _selectedCategory,
          vehicleSubType: _selectedSubType,
          fuelType: _selectedFuelType,
          pickupLocation: _pickupLocation,
          imageUrls: images,
        );
        await carService.addCar(newCar);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    }
  }

  void _useCurrentLocation() async {
    final locationService = context.read<LocationService>();
    final position = await locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _pickupLocation = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup location set to your current GPS position.')),
      );
    } else if (mounted && locationService.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locationService.errorMessage!)),
      );
    }
  }

  void _selectOnMap() async {
    final result = await Navigator.push<Map<String, double>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation: _pickupLocation,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _pickupLocation = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = context.watch<LocationService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── License Plate ──
            TextFormField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'License Plate (e.g. GJ01AB1234)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'License plate is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // ── Brand & Model ──
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: 'Brand (e.g. Toyota)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Brand is required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model (e.g. Fortuner)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Model is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Year ──
            TextFormField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Year (e.g. 2024)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Year is required';
                final y = int.tryParse(value.trim());
                if (y == null || y < 1990 || y > DateTime.now().year + 1) {
                  return 'Enter a valid year';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Vehicle Category (Car / TwoWheeler) ──
            const Text(
              'Vehicle Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Car'),
                  selected: _selectedCategory == 'Car',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = 'Car';
                        _selectedSubType = carSubTypes.first;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Two-Wheeler'),
                  selected: _selectedCategory == 'TwoWheeler',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = 'TwoWheeler';
                        _selectedSubType = twoWheelerSubTypes.first;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Sub-Type Dropdown ──
            DropdownButtonFormField<String>(
              initialValue: _selectedSubType,
              decoration: InputDecoration(
                labelText: _selectedCategory == 'Car' ? 'Car Sub-Type' : 'Two-Wheeler Sub-Type',
                border: const OutlineInputBorder(),
              ),
              items: subTypesForCategory(_selectedCategory)
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSubType = value);
                }
              },
            ),
            const SizedBox(height: 20),

            // ── Fuel Type ──
            const Text(
              'Fuel Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: fuelTypes.map((fuel) {
                return ChoiceChip(
                  label: Text(fuel),
                  selected: _selectedFuelType == fuel,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFuelType = fuel);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Price Per Day ──
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price per day (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Price is required';
                final price = double.tryParse(value.trim());
                if (price == null || price <= 0) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // ── Image URL (Optional) ──
            TextFormField(
              controller: _imageUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Vehicle Image URL (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_imageUrlController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _imageUrlController.text.trim(),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 80,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Text('Could not load image from URL', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // ── Description ──
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // ── Pickup Location Section (Section 10) ──
            const Text(
              'Pickup Location (Required)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            if (_pickupLocation != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lat: ${_pickupLocation!['latitude']!.toStringAsFixed(5)}\n'
                        'Lng: ${_pickupLocation!['longitude']!.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => setState(() => _pickupLocation = null),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No pickup location set. Please set the pickup point using the buttons below.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: locationService.isLoading ? null : _useCurrentLocation,
                    icon: locationService.isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: const Text('Use Current Location'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectOnMap,
                    icon: const Icon(Icons.map),
                    label: const Text('Select Location on Map'),
                  ),
                ),
              ],
            ),

            // ── Save Vehicle Button ──
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(isEditing ? Icons.save : Icons.add),
              label: Text(isEditing ? 'Save Changes' : 'Save Vehicle'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}