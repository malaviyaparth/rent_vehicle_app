import 'package:flutter/material.dart';
import '../models/vehicle_enums.dart';
import '../models/vehicle_filter_model.dart';

/// Modal bottom sheet for setting vehicle filters and sorting.
///
/// Returns the updated [VehicleFilter] via Navigator.pop() when "Apply Filters" is tapped.
Future<VehicleFilter?> showVehicleFilterSheet(
  BuildContext context, {
  required VehicleFilter currentFilter,
}) {
  return showModalBottomSheet<VehicleFilter>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _VehicleFilterSheet(filter: currentFilter),
  );
}

class _VehicleFilterSheet extends StatefulWidget {
  final VehicleFilter filter;
  const _VehicleFilterSheet({required this.filter});

  @override
  State<_VehicleFilterSheet> createState() => _VehicleFilterSheetState();
}

class _VehicleFilterSheetState extends State<_VehicleFilterSheet> {
  late VehicleFilter _filter;

  static const _radiusOptions = [1.0, 5.0, 10.0, 25.0, 50.0];

  static const _priceMin = 0.0;
  static const _priceMax = 10000.0;

  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter.copyWith();
    _priceRange = RangeValues(
      _filter.minPrice ?? _priceMin,
      _filter.maxPrice ?? _priceMax,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters & Sorting',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filter.reset();
                        _priceRange = const RangeValues(_priceMin, _priceMax);
                      });
                    },
                    child: const Text('Reset All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Sort By ──
              _sectionTitle('Sort By'),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: VehicleSort.values.map((sort) {
                  return ChoiceChip(
                    label: Text(vehicleSortLabel(sort)),
                    selected: _filter.sortBy == sort,
                    onSelected: (selected) {
                      if (selected) setState(() => _filter.sortBy = sort);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ── Distance Radius ──
              _sectionTitle('Search Radius'),
              Wrap(
                spacing: 8,
                children: _radiusOptions.map((r) {
                  return ChoiceChip(
                    label: Text('${r.toInt()} km'),
                    selected: _filter.radiusKm == r,
                    onSelected: (selected) {
                      if (selected) setState(() => _filter.radiusKm = r);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ── Vehicle Category ──
              _sectionTitle('Vehicle Category'),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All Categories'),
                    selected: _filter.vehicleCategory == null,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _filter.vehicleCategory = null;
                          _filter.carSubType = null;
                        });
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Car'),
                    selected: _filter.vehicleCategory == 'Car',
                    onSelected: (selected) {
                      setState(() {
                        _filter.vehicleCategory = selected ? 'Car' : null;
                        _filter.carSubType = null;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Two-Wheeler'),
                    selected: _filter.vehicleCategory == 'TwoWheeler',
                    onSelected: (selected) {
                      setState(() {
                        _filter.vehicleCategory = selected ? 'TwoWheeler' : null;
                        _filter.carSubType = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Sub-Type Filter ──
              if (_filter.vehicleCategory != null) ...[
                _sectionTitle('${_filter.vehicleCategory == 'Car' ? 'Car' : 'Two-Wheeler'} Sub-Type'),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('All Sub-Types'),
                      selected: _filter.carSubType == null,
                      onSelected: (selected) {
                        if (selected) setState(() => _filter.carSubType = null);
                      },
                    ),
                    ...subTypesForCategory(_filter.vehicleCategory!).map((sub) {
                      return ChoiceChip(
                        label: Text(sub),
                        selected: _filter.carSubType == sub,
                        onSelected: (selected) {
                          setState(() {
                            _filter.carSubType = selected ? sub : null;
                          });
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // ── Fuel Type ──
              _sectionTitle('Fuel Type'),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('All Fuels'),
                    selected: _filter.fuelType == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _filter.fuelType = null);
                    },
                  ),
                  ...fuelTypes.map((fuel) {
                    return ChoiceChip(
                      label: Text(fuel),
                      selected: _filter.fuelType == fuel,
                      onSelected: (selected) {
                        setState(() {
                          _filter.fuelType = selected ? fuel : null;
                        });
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // ── Price Range ──
              _sectionTitle(
                'Price per Day: ₹${_priceRange.start.round()} – ₹${_priceRange.end.round()}',
              ),
              RangeSlider(
                values: _priceRange,
                min: _priceMin,
                max: _priceMax,
                divisions: 100,
                labels: RangeLabels(
                  '₹${_priceRange.start.round()}',
                  '₹${_priceRange.end.round()}',
                ),
                onChanged: (values) {
                  setState(() {
                    _priceRange = values;
                    _filter.minPrice = values.start > _priceMin ? values.start : null;
                    _filter.maxPrice = values.end < _priceMax ? values.end : null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // ── Availability ──
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available only'),
                subtitle: const Text('Hide vehicles currently rented out'),
                value: _filter.availableOnly,
                onChanged: (val) => setState(() => _filter.availableOnly = val),
              ),

              const SizedBox(height: 20),

              // ── Apply Button ──
              FilledButton(
                onPressed: () => Navigator.pop(context, _filter),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Apply Filters', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}
