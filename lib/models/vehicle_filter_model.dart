/// Sorting options for vehicles.
enum VehicleSort {
  nearest,
  priceLowToHigh,
  priceHighToLow,
  newest,
}

String vehicleSortLabel(VehicleSort sort) {
  switch (sort) {
    case VehicleSort.nearest:
      return 'Nearest';
    case VehicleSort.priceLowToHigh:
      return 'Price: Low to High';
    case VehicleSort.priceHighToLow:
      return 'Price: High to Low';
    case VehicleSort.newest:
      return 'Newest';
  }
}

/// Holds all active filter/search/sort state for nearby & vehicle browsing.
class VehicleFilter {
  /// Search radius in km. One of: 1, 5, 10, 25, 50.
  double radiusKm;

  /// Top-level category: 'Car', 'TwoWheeler', or null (all).
  String? vehicleCategory;

  /// Sub-type: 'Sedan', 'SUV', 'Bike', etc. Null means all sub-types.
  String? carSubType;

  /// Fuel type: 'Petrol', 'Diesel', etc. Null means all.
  String? fuelType;

  /// Minimum price per day filter. Null means no lower bound.
  double? minPrice;

  /// Maximum price per day filter. Null means no upper bound.
  double? maxPrice;

  /// When true, only available vehicles are shown.
  bool availableOnly;

  /// Free-text search query matched against brand and model.
  String searchQuery;

  /// Active sorting criterion.
  VehicleSort sortBy;

  VehicleFilter({
    this.radiusKm = 5,
    this.vehicleCategory,
    this.carSubType,
    this.fuelType,
    this.minPrice,
    this.maxPrice,
    this.availableOnly = true,
    this.searchQuery = '',
    this.sortBy = VehicleSort.nearest,
  });

  /// Returns true if any filter is active (non-default).
  bool get hasActiveFilters =>
      vehicleCategory != null ||
      carSubType != null ||
      fuelType != null ||
      minPrice != null ||
      maxPrice != null ||
      !availableOnly ||
      radiusKm != 5 ||
      sortBy != VehicleSort.nearest;

  /// Resets all filters to defaults.
  void reset() {
    radiusKm = 5;
    vehicleCategory = null;
    carSubType = null;
    fuelType = null;
    minPrice = null;
    maxPrice = null;
    availableOnly = true;
    searchQuery = '';
    sortBy = VehicleSort.nearest;
  }

  /// Creates a copy of this filter.
  VehicleFilter copyWith({
    double? radiusKm,
    String? Function()? vehicleCategory,
    String? Function()? carSubType,
    String? Function()? fuelType,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    bool? availableOnly,
    String? searchQuery,
    VehicleSort? sortBy,
  }) {
    return VehicleFilter(
      radiusKm: radiusKm ?? this.radiusKm,
      vehicleCategory: vehicleCategory != null ? vehicleCategory() : this.vehicleCategory,
      carSubType: carSubType != null ? carSubType() : this.carSubType,
      fuelType: fuelType != null ? fuelType() : this.fuelType,
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
      availableOnly: availableOnly ?? this.availableOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}
