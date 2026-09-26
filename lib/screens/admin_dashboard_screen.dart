import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../services/car_service.dart';
import '../services/auth_service.dart';
import '../services/rental_service.dart';
import 'car_details_screen.dart';

/// Admin-only management dashboard.
/// Only accessible when [currentUser.isAdmin] is true.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppUser> _users = [];
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    final users = await context.read<AuthService>().getAllUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _loadingUsers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final carService = context.watch<CarService>();
    final rentalService = context.watch<RentalService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.directions_car),
              text: 'Vehicles (${carService.cars.length})',
            ),
            Tab(
              icon: const Icon(Icons.people),
              text: 'Users (${_users.length})',
            ),
            Tab(
              icon: const Icon(Icons.receipt_long),
              text: 'Bookings (${rentalService.all.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Vehicles Management ──
          _buildVehiclesTab(carService),

          // ── Tab 2: Users & Owners ──
          _buildUsersTab(),

          // ── Tab 3: Bookings Monitoring ──
          _buildBookingsTab(rentalService),
        ],
      ),
    );
  }

  Widget _buildVehiclesTab(CarService carService) {
    final cars = carService.cars;
    if (cars.isEmpty) {
      return const Center(child: Text('No vehicles in the system.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cars.length,
      itemBuilder: (context, index) {
        final car = cars[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: car.available ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(
                car.vehicleType == 'TwoWheeler' ? Icons.two_wheeler : Icons.directions_car,
                color: car.available ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
            title: Text('${car.brand} ${car.model} (${car.licensePlate})'),
            subtitle: Text(
              '${car.vehicleSubType} • ${car.fuelType} • ₹${car.pricePerDay.toStringAsFixed(0)}/day\n'
              'Status: ${car.available ? 'Active/Available' : 'Rented/Inactive'}',
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'toggle') {
                  await carService.toggleAvailability(car.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Updated availability for ${car.brand}')),
                    );
                  }
                } else if (val == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Admin: Remove Vehicle'),
                      content: Text('Permanently remove ${car.brand} ${car.model}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await carService.removeCar(car.id);
                  }
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(car.available ? 'Deactivate' : 'Activate'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Listing', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CarDetailsScreen(carId: car.id)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUsersTab() {
    if (_loadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No users found in Firestore.'),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _loadUsers, child: const Text('Refresh')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final isOwner = user.isOwner;
          final isAdmin = user.isAdmin;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isAdmin
                    ? Colors.purple.shade100
                    : isOwner
                        ? Colors.indigo.shade100
                        : Colors.teal.shade100,
                child: Icon(
                  isAdmin
                      ? Icons.admin_panel_settings
                      : isOwner
                          ? Icons.business_center
                          : Icons.person,
                  color: isAdmin
                      ? Colors.purple.shade800
                      : isOwner
                          ? Colors.indigo.shade800
                          : Colors.teal.shade800,
                ),
              ),
              title: Text(user.name.isEmpty ? 'No Name' : user.name),
              subtitle: Text(
                '${user.email}${user.phone.isNotEmpty ? ' • ${user.phone}' : ''}',
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? Colors.purple.shade50
                      : isOwner
                          ? Colors.indigo.shade50
                          : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAdmin
                        ? Colors.purple.shade200
                        : isOwner
                            ? Colors.indigo.shade200
                            : Colors.teal.shade200,
                  ),
                ),
                child: Text(
                  roleToString(user.role).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isAdmin
                        ? Colors.purple.shade800
                        : isOwner
                            ? Colors.indigo.shade800
                            : Colors.teal.shade800,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingsTab(RentalService rentalService) {
    final bookings = rentalService.all;
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings recorded yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        Color statusColor = Colors.grey;
        if (b.isConfirmed) statusColor = Colors.green;
        if (b.isPending) statusColor = Colors.orange;
        if (b.isCancelled) statusColor = Colors.red;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${b.carBrand} ${b.carModel}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        b.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Borrower: ${b.userName} • ${b.days} day(s) • Total: ₹${b.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  '${b.startDate.day}/${b.startDate.month}/${b.startDate.year} → '
                  '${b.endDate.day}/${b.endDate.month}/${b.endDate.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (b.isPending || b.isConfirmed) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        await rentalService.cancelRental(b.id, b.carId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Booking cancelled by Admin.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                      label: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
