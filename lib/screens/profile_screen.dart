import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/car_service.dart';
import '../services/rental_service.dart';
import 'my_rental_history_screen.dart';
import 'nearby_vehicles_screen.dart';
import 'add_edit_car_screen.dart';

/// Comprehensive Profile Screen supporting both Borrower and Owner roles.
/// Features profile editing, role-specific shortcuts and stats, and account info.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final error = await context.read<AuthService>().updateProfile(
      name: _nameController.text,
      phone: _phoneController.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error == null ? Colors.green.shade800 : Colors.red.shade800,
        content: Text(error ?? 'Profile updated successfully!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final carService = context.watch<CarService>();
    final rentalService = context.watch<RentalService>();
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please log in to view your profile.')),
      );
    }

    final isOwner = user.isOwner;
    final isAdmin = user.isAdmin;
    final isBorrower = user.isBorrower;

    // Computed counts
    final userBookings = rentalService.rentalsByUser(user.uid);
    final ownerCars = carService.carsByOwner(user.uid);

    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isOwner ? 'Owner Profile' : 'Borrower Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              authService.logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── User Header Card ──
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: isOwner
                          ? Colors.teal.shade700
                          : isAdmin
                              ? Colors.purple.shade700
                              : Colors.indigo.shade700,
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : (user.email.isNotEmpty ? user.email[0].toUpperCase() : 'U'),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name.isNotEmpty ? user.name : 'User',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),

                    // Role Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOwner
                            ? Colors.teal.shade50
                            : isAdmin
                                ? Colors.purple.shade50
                                : Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOwner
                              ? Colors.teal.shade300
                              : isAdmin
                                  ? Colors.purple.shade300
                                  : Colors.indigo.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOwner
                                ? Icons.business
                                : isAdmin
                                    ? Icons.admin_panel_settings
                                    : Icons.directions_car,
                            size: 16,
                            color: isOwner
                                ? Colors.teal.shade800
                                : isAdmin
                                    ? Colors.purple.shade800
                                    : Colors.indigo.shade800,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOwner
                                ? 'VEHICLE OWNER'
                                : isAdmin
                                    ? 'SYSTEM ADMIN'
                                    : 'BORROWER / RENTER',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: isOwner
                                  ? Colors.teal.shade800
                                  : isAdmin
                                      ? Colors.purple.shade800
                                      : Colors.indigo.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (user.createdAt != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Member since: ${dateFormat.format(user.createdAt!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Role Specific Statistics ──
            if (isOwner)
              Row(
                children: [
                  _statCard('Listed Vehicles', '${ownerCars.length}', Icons.directions_car, Colors.teal),
                  const SizedBox(width: 10),
                  _statCard(
                    'Available Now',
                    '${ownerCars.where((c) => c.available).length}',
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                ],
              )
            else if (isBorrower)
              Row(
                children: [
                  _statCard('Total Bookings', '${userBookings.length}', Icons.history, Colors.indigo),
                  const SizedBox(width: 10),
                  _statCard(
                    'Active Now',
                    '${userBookings.where((r) => r.isConfirmed).length}',
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // ── Edit Profile Form Card ──
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? 'Name cannot be empty' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: user.email,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Email Address (Verified)',
                          prefixIcon: const Icon(Icons.email),
                          suffixIcon: const Icon(Icons.lock, size: 16, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isSaving ? 'Saving...' : 'Save Profile Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Quick Navigation Shortcuts ──
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  if (isBorrower) ...[
                    ListTile(
                      leading: const Icon(Icons.history, color: Colors.indigo),
                      title: const Text('My Booking History'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyRentalHistoryScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.near_me, color: Colors.indigo),
                      title: const Text('Find Nearby Vehicles (Google Maps)'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NearbyVehiclesScreen()),
                        );
                      },
                    ),
                  ],
                  if (isOwner) ...[
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline, color: Colors.teal),
                      title: const Text('Add New Vehicle'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddEditCarScreen()),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Logout Button ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                  authService.logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Log Out of Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, MaterialColor color) {
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color.shade800),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
