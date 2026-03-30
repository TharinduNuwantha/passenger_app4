// Models for Lounge Booking functionality
// Matches backend API response structure

// ============================================================================
// ENUMS / STATUS TYPES
// ============================================================================

enum LoungePricingType {
  oneHour,
  twoHours,
  threeHours,
  untilBus;

  String toJson() {
    switch (this) {
      case LoungePricingType.oneHour:
        return '1_hour';
      case LoungePricingType.twoHours:
        return '2_hours';
      case LoungePricingType.threeHours:
        return '3_hours';
      case LoungePricingType.untilBus:
        return 'until_bus';
    }
  }

  static LoungePricingType fromJson(String? value) {
    switch (value) {
      case '1_hour':
        return LoungePricingType.oneHour;
      case '2_hours':
        return LoungePricingType.twoHours;
      case '3_hours':
        return LoungePricingType.threeHours;
      case 'until_bus':
        return LoungePricingType.untilBus;
      default:
        return LoungePricingType.oneHour;
    }
  }

  String get displayName {
    switch (this) {
      case LoungePricingType.oneHour:
        return '1 Hour';
      case LoungePricingType.twoHours:
        return '2 Hours';
      case LoungePricingType.threeHours:
        return '3 Hours';
      case LoungePricingType.untilBus:
        return 'Until Bus Arrives';
    }
  }
}

enum LoungeBookingStatus {
  pending,
  confirmed,
  checkedIn,
  completed,
  cancelled,
  noShow;

  String toJson() {
    switch (this) {
      case LoungeBookingStatus.pending:
        return 'pending';
      case LoungeBookingStatus.confirmed:
        return 'confirmed';
      case LoungeBookingStatus.checkedIn:
        return 'checked_in';
      case LoungeBookingStatus.completed:
        return 'completed';
      case LoungeBookingStatus.cancelled:
        return 'cancelled';
      case LoungeBookingStatus.noShow:
        return 'no_show';
    }
  }

  static LoungeBookingStatus fromJson(String? value) {
    switch (value) {
      case 'pending':
        return LoungeBookingStatus.pending;
      case 'confirmed':
        return LoungeBookingStatus.confirmed;
      case 'checked_in':
        return LoungeBookingStatus.checkedIn;
      case 'completed':
        return LoungeBookingStatus.completed;
      case 'cancelled':
        return LoungeBookingStatus.cancelled;
      case 'no_show':
        return LoungeBookingStatus.noShow;
      default:
        return LoungeBookingStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case LoungeBookingStatus.pending:
        return 'Pending';
      case LoungeBookingStatus.confirmed:
        return 'Confirmed';
      case LoungeBookingStatus.checkedIn:
        return 'Checked In';
      case LoungeBookingStatus.completed:
        return 'Completed';
      case LoungeBookingStatus.cancelled:
        return 'Cancelled';
      case LoungeBookingStatus.noShow:
        return 'No Show';
    }
  }

  bool get isActive =>
      this == LoungeBookingStatus.pending ||
      this == LoungeBookingStatus.confirmed ||
      this == LoungeBookingStatus.checkedIn;
}

enum LoungePaymentStatus {
  pending,
  partial,
  paid,
  refunded;

  String toJson() {
    switch (this) {
      case LoungePaymentStatus.pending:
        return 'pending';
      case LoungePaymentStatus.partial:
        return 'partial';
      case LoungePaymentStatus.paid:
        return 'paid';
      case LoungePaymentStatus.refunded:
        return 'refunded';
    }
  }

  static LoungePaymentStatus fromJson(String? value) {
    switch (value) {
      case 'pending':
        return LoungePaymentStatus.pending;
      case 'partial':
        return LoungePaymentStatus.partial;
      case 'paid':
        return LoungePaymentStatus.paid;
      case 'refunded':
        return LoungePaymentStatus.refunded;
      default:
        return LoungePaymentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case LoungePaymentStatus.pending:
        return 'Pending';
      case LoungePaymentStatus.partial:
        return 'Partial';
      case LoungePaymentStatus.paid:
        return 'Paid';
      case LoungePaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

enum LoungeOrderStatus {
  pending,
  preparing,
  ready,
  delivered,
  cancelled;

  String toJson() {
    switch (this) {
      case LoungeOrderStatus.pending:
        return 'pending';
      case LoungeOrderStatus.preparing:
        return 'preparing';
      case LoungeOrderStatus.ready:
        return 'ready';
      case LoungeOrderStatus.delivered:
        return 'delivered';
      case LoungeOrderStatus.cancelled:
        return 'cancelled';
    }
  }

  static LoungeOrderStatus fromJson(String? value) {
    switch (value) {
      case 'pending':
        return LoungeOrderStatus.pending;
      case 'preparing':
        return LoungeOrderStatus.preparing;
      case 'ready':
        return LoungeOrderStatus.ready;
      case 'delivered':
        return LoungeOrderStatus.delivered;
      case 'cancelled':
        return LoungeOrderStatus.cancelled;
      default:
        return LoungeOrderStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case LoungeOrderStatus.pending:
        return 'Pending';
      case LoungeOrderStatus.preparing:
        return 'Preparing';
      case LoungeOrderStatus.ready:
        return 'Ready';
      case LoungeOrderStatus.delivered:
        return 'Delivered';
      case LoungeOrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// ============================================================================
// LOUNGE MODEL (for marketplace)
// ============================================================================

class Lounge {
  final String id;
  final String loungeOwnerId;
  final String loungeName;
  final String? description;
  final String address;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? contactPhone;
  final double? latitude;
  final double? longitude;
  final int? capacity;
  final double? price1Hour;
  final double? price2Hours;
  final double? price3Hours;
  final double? priceUntilBus;
  final List<String> amenities;
  final List<String> images;
  final String status;
  final bool isOperational;
  final double? averageRating;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lounge({
    required this.id,
    required this.loungeOwnerId,
    required this.loungeName,
    this.description,
    required this.address,
    this.state,
    this.country,
    this.postalCode,
    this.contactPhone,
    this.latitude,
    this.longitude,
    this.capacity,
    this.price1Hour,
    this.price2Hours,
    this.price3Hours,
    this.priceUntilBus,
    this.amenities = const [],
    this.images = const [],
    required this.status,
    required this.isOperational,
    this.averageRating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Lounge.fromJson(Map<String, dynamic> json) {
    return Lounge(
      id: json['id'] as String? ?? '',
      loungeOwnerId: json['lounge_owner_id'] as String? ?? '',
      loungeName: json['lounge_name'] as String? ?? 'Unknown Lounge',
      description: json['description'] as String?,
      address: json['address'] as String? ?? '',
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postal_code'] as String?,
      contactPhone: json['contact_phone'] as String?,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      capacity: _parseInt(json['capacity']),
      price1Hour: _parseDouble(json['price_1_hour']),
      price2Hours: _parseDouble(json['price_2_hours']),
      price3Hours: _parseDouble(json['price_3_hours']),
      priceUntilBus: _parseDouble(json['price_until_bus']),
      amenities: _parseStringList(json['amenities']),
      images: _parseStringList(json['images']),
      status: json['status'] as String? ?? 'approved',
      isOperational: json['is_operational'] as bool? ?? true,
      averageRating: _parseDouble(json['average_rating']),
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    // Handle Go's sql.NullString/sql.NullFloat64 format: {"String":"value","Valid":true}
    if (value is Map) {
      final stringValue = value['String'];
      final valid = value['Valid'] as bool?;
      if (valid == true && stringValue != null) {
        if (stringValue is num) return stringValue.toDouble();
        if (stringValue is String) return double.tryParse(stringValue);
      }
      return null;
    }
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    // Handle Go's sql.NullInt64 format: {"Int64":value,"Valid":true}
    if (value is Map) {
      final int64Value = value['Int64'];
      final valid = value['Valid'] as bool?;
      if (valid == true && int64Value != null) {
        if (int64Value is int) return int64Value;
        if (int64Value is String) return int.tryParse(int64Value);
      }
      return null;
    }
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Get price for a specific pricing type
  double? getPriceForType(LoungePricingType type) {
    switch (type) {
      case LoungePricingType.oneHour:
        return price1Hour;
      case LoungePricingType.twoHours:
        return price2Hours;
      case LoungePricingType.threeHours:
        return price3Hours;
      case LoungePricingType.untilBus:
        return priceUntilBus;
    }
  }

  String get formattedPrice1Hour =>
      price1Hour != null ? 'LKR ${price1Hour!.toStringAsFixed(2)}' : 'N/A';

  String? get primaryImage => images.isNotEmpty ? images.first : null;

  bool get hasWifi => amenities.any((a) => a.toLowerCase().contains('wifi'));

  bool get hasAC => amenities.any(
    (a) => a.toLowerCase().contains('ac') || a.toLowerCase().contains('air'),
  );
}

// ============================================================================
// LOUNGE CATEGORY MODEL
// ============================================================================

class LoungeCategory {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final int displayOrder;
  final bool isActive;

  LoungeCategory({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.displayOrder,
    required this.isActive,
  });

  factory LoungeCategory.fromJson(Map<String, dynamic> json) {
    return LoungeCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

// ============================================================================
// LOUNGE TRANSPORT (pickup locations + per-vehicle prices)
// ============================================================================

class LoungeTransportLocationOption {
  final String id;
  final String location;
  final double latitude;
  final double longitude;
  final int? estDurationMinutes;
  final double? distanceKm;
  final double threeWheelerPrice;
  final double carPrice;
  final double vanPrice;

  LoungeTransportLocationOption({
    required this.id,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.estDurationMinutes,
    this.distanceKm,
    required this.threeWheelerPrice,
    required this.carPrice,
    required this.vanPrice,
  });

  factory LoungeTransportLocationOption.fromJson(Map<String, dynamic> json) {
    return LoungeTransportLocationOption(
      id: _stringOrNull(json['location_id']) ?? '',
      location: json['location'] as String? ?? '',
      latitude: _numToDouble(json['latitude']),
      longitude: _numToDouble(json['longitude']),
      estDurationMinutes: _parseOptionalInt(json['est_duration_minutes']),
      distanceKm: _parseOptionalDouble(json['distance_km']),
      threeWheelerPrice: _numToDouble(json['three_wheeler_price']),
      carPrice: _numToDouble(json['car_price']),
      vanPrice: _numToDouble(json['van_price']),
    );
  }

  static String? _stringOrNull(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  static double _numToDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int? _parseOptionalInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString());
  }

  static double? _parseOptionalDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  /// [type] is `tuktuk`, `car`, or `van` (matches app UI keys).
  double priceForVehicleType(String type) {
    switch (type) {
      case 'tuktuk':
        return threeWheelerPrice;
      case 'car':
        return carPrice;
      case 'van':
        return vanPrice;
      default:
        return 0;
    }
  }
}

// ============================================================================
// LOUNGE PRODUCT MODEL
// ============================================================================

class LoungeProduct {
  final String id;
  final String loungeId;
  final String? categoryId;
  final String? categoryName;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String productType; // 'product', 'service', 'package'
  final String
  stockStatus; // 'in_stock', 'low_stock', 'out_of_stock', 'discontinued', 'made_to_order'
  final bool isAvailable;
  final bool isPreOrderable;
  final bool isVegetarian;
  final bool isHalal;
  final int displayOrder;
  final int? serviceDurationMinutes;
  final String? availableFrom; // Time string like "06:00:00"
  final String? availableUntil; // Time string like "10:30:00"
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoungeProduct({
    required this.id,
    required this.loungeId,
    this.categoryId,
    this.categoryName,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.productType,
    required this.stockStatus,
    required this.isAvailable,
    required this.isPreOrderable,
    this.isVegetarian = false,
    this.isHalal = false,
    this.displayOrder = 0,
    this.serviceDurationMinutes,
    this.availableFrom,
    this.availableUntil,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoungeProduct.fromJson(Map<String, dynamic> json) {
    // Handle category_id which might be a String or Map with 'id' field
    String? categoryId;
    if (json['category_id'] != null) {
      if (json['category_id'] is String) {
        categoryId = json['category_id'] as String;
      } else if (json['category_id'] is Map) {
        categoryId = (json['category_id'] as Map)['id']?.toString();
      }
    }

    return LoungeProduct(
      id: json['id'] as String,
      loungeId: json['lounge_id'] as String,
      categoryId: categoryId,
      categoryName: json['category_name'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: Lounge._parseDouble(json['price']) ?? 0.0,
      imageUrl: json['image_url'] as String?,
      productType: json['product_type'] as String? ?? 'product',
      stockStatus: json['stock_status'] as String? ?? 'in_stock',
      isAvailable: json['is_available'] as bool? ?? true,
      isPreOrderable: json['is_pre_orderable'] as bool? ?? false,
      isVegetarian: json['is_vegetarian'] as bool? ?? false,
      isHalal: json['is_halal'] as bool? ?? false,
      displayOrder: json['display_order'] as int? ?? 0,
      serviceDurationMinutes: json['service_duration_minutes'] as int?,
      availableFrom: json['available_from'] as String?,
      availableUntil: json['available_until'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String get formattedPrice => 'LKR ${price.toStringAsFixed(2)}';

  // Helper getters
  bool get isProduct => productType == 'product';
  bool get isService => productType == 'service';
  bool get isPackage => productType == 'package';

  bool get isMadeToOrder => stockStatus == 'made_to_order';
  bool get isInStock => stockStatus == 'in_stock';
  bool get isOutOfStock => stockStatus == 'out_of_stock';
  bool get isLowStock => stockStatus == 'low_stock';

  bool get hasTimeRestriction =>
      availableFrom != null && availableUntil != null;

  String get productTypeLabel {
    switch (productType) {
      case 'product':
        return 'Product';
      case 'service':
        return 'Service';
      case 'package':
        return 'Package';
      default:
        return productType;
    }
  }

  String get stockStatusLabel {
    switch (stockStatus) {
      case 'in_stock':
        return 'In Stock';
      case 'low_stock':
        return 'Low Stock';
      case 'out_of_stock':
        return 'Out of Stock';
      case 'made_to_order':
        return 'Made to Order';
      case 'discontinued':
        return 'Discontinued';
      default:
        return stockStatus;
    }
  }
}

// ============================================================================
// LOUNGE BOOKING MODEL
// ============================================================================

class LoungeBooking {
  final String id;
  final String loungeId;
  final String? loungeName;
  final String userId;
  final String? busBookingId;
  final String bookingReference;
  final LoungePricingType pricingType;
  final int numberOfGuests;
  final DateTime checkInTime;
  final DateTime? expectedEndTime;
  final DateTime? actualCheckOutTime;
  final double basePrice;
  final double totalAmount;
  final LoungePaymentStatus paymentStatus;
  final LoungeBookingStatus bookingStatus;
  final String? specialRequests;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final List<LoungeBookingGuest> guests;
  final List<LoungePreOrderItem> preOrders;
  final Lounge? lounge;

  LoungeBooking({
    required this.id,
    required this.loungeId,
    this.loungeName,
    required this.userId,
    this.busBookingId,
    required this.bookingReference,
    required this.pricingType,
    required this.numberOfGuests,
    required this.checkInTime,
    this.expectedEndTime,
    this.actualCheckOutTime,
    required this.basePrice,
    required this.totalAmount,
    required this.paymentStatus,
    required this.bookingStatus,
    this.specialRequests,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.guests = const [],
    this.preOrders = const [],
    this.lounge,
  });

  factory LoungeBooking.fromJson(Map<String, dynamic> json) {
    // Handle both old and new field names for backwards compatibility
    final checkInTimeStr = json['scheduled_arrival'] ?? json['check_in_time'];
    final expectedEndTimeStr =
        json['scheduled_departure'] ?? json['expected_end_time'];
    final actualCheckOutTimeStr =
        json['actual_departure'] ?? json['actual_check_out_time'];
    final statusStr = json['status'] ?? json['booking_status'];
    final createdAtStr = json['created_at'];
    final updatedAtStr = json['updated_at'];

    return LoungeBooking(
      id: json['id'] as String? ?? '',
      loungeId: json['lounge_id'] as String? ?? '',
      loungeName: json['lounge_name'] as String?,
      userId: json['user_id'] as String? ?? '',
      busBookingId: json['bus_booking_id'] as String?,
      bookingReference: json['booking_reference'] as String? ?? '',
      pricingType: LoungePricingType.fromJson(json['pricing_type'] as String?),
      numberOfGuests: json['number_of_guests'] as int? ?? 1,
      checkInTime: checkInTimeStr != null
          ? DateTime.parse(checkInTimeStr as String)
          : DateTime.now(),
      expectedEndTime: expectedEndTimeStr != null
          ? DateTime.parse(expectedEndTimeStr as String)
          : null,
      actualCheckOutTime: actualCheckOutTimeStr != null
          ? DateTime.parse(actualCheckOutTimeStr as String)
          : null,
      basePrice: Lounge._parseDouble(json['base_price']) ?? 0.0,
      totalAmount: Lounge._parseDouble(json['total_amount']) ?? 0.0,
      paymentStatus: LoungePaymentStatus.fromJson(
        json['payment_status'] as String?,
      ),
      bookingStatus: LoungeBookingStatus.fromJson(statusStr as String?),
      specialRequests: json['special_requests'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: createdAtStr != null
          ? DateTime.parse(createdAtStr as String)
          : DateTime.now(),
      updatedAt: updatedAtStr != null
          ? DateTime.parse(updatedAtStr as String)
          : DateTime.now(),
      guests:
          (json['guests'] as List<dynamic>?)
              ?.map(
                (e) => LoungeBookingGuest.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      preOrders:
          (json['pre_orders'] as List<dynamic>?)
              ?.map(
                (e) => LoungePreOrderItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      lounge: json['lounge'] != null
          ? Lounge.fromJson(json['lounge'] as Map<String, dynamic>)
          : null,
    );
  }

  String get formattedTotal => 'LKR ${totalAmount.toStringAsFixed(2)}';

  String get formattedCheckIn {
    return '${checkInTime.day}/${checkInTime.month}/${checkInTime.year} '
        '${checkInTime.hour.toString().padLeft(2, '0')}:'
        '${checkInTime.minute.toString().padLeft(2, '0')}';
  }

  /// Alias for formattedCheckIn for backwards compatibility
  String get formattedScheduledArrival => formattedCheckIn;

  /// Get QR code data (uses booking reference if no qr_code field)
  String get qrCodeData => bookingReference;

  /// Get booking status
  LoungeBookingStatus get status => bookingStatus;

  /// Get pre-order total
  double get preOrderTotal =>
      preOrders.fold(0, (sum, item) => sum + item.subtotal);

  bool get canBeCancelled =>
      bookingStatus == LoungeBookingStatus.pending ||
      bookingStatus == LoungeBookingStatus.confirmed;

  bool get isUpcoming => checkInTime.isAfter(DateTime.now());
}

// ============================================================================
// LOUNGE BOOKING GUEST MODEL
// ============================================================================

class LoungeBookingGuest {
  final String id;
  final String loungeBookingId;
  final String guestName;
  final String? guestPhone;
  final bool isPrimaryGuest;
  final DateTime? checkedInAt;

  LoungeBookingGuest({
    required this.id,
    required this.loungeBookingId,
    required this.guestName,
    this.guestPhone,
    required this.isPrimaryGuest,
    this.checkedInAt,
  });

  factory LoungeBookingGuest.fromJson(Map<String, dynamic> json) {
    // Temporary: Handle sql.NullString format from backend
    String? parseGuestPhone(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      if (value is Map<String, dynamic>) {
        if (value['Valid'] == true && value['String'] != null) {
          final str = value['String'] as String;
          return str.isEmpty ? null : str;
        }
      }
      return null;
    }

    // Temporary: Handle sql.NullTime format from backend
    DateTime? parseCheckedInAt(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      if (value is Map<String, dynamic>) {
        if (value['Valid'] == true && value['Time'] != null) {
          try {
            return DateTime.parse(value['Time'] as String);
          } catch (_) {
            return null;
          }
        }
      }
      return null;
    }

    return LoungeBookingGuest(
      id: json['id'] as String? ?? '',
      loungeBookingId: json['lounge_booking_id'] as String? ?? '',
      guestName: json['guest_name'] as String? ?? 'Guest',
      guestPhone: parseGuestPhone(json['guest_phone']),
      isPrimaryGuest: json['is_primary_guest'] as bool? ?? false,
      checkedInAt: parseCheckedInAt(json['checked_in_at']),
    );
  }

  bool get isCheckedIn => checkedInAt != null;

  /// Alias for backwards compatibility
  bool get checkedIn => isCheckedIn;
}

// ============================================================================
// LOUNGE PRE-ORDER ITEM MODEL
// ============================================================================

class LoungePreOrderItem {
  final String id;
  final String loungeBookingId;
  final String productId;
  final String productName;
  final String productType; // Added - snapshot from product
  final String? productImageUrl; // Added - snapshot from product
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime? createdAt;

  LoungePreOrderItem({
    required this.id,
    required this.loungeBookingId,
    required this.productId,
    required this.productName,
    required this.productType,
    this.productImageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.createdAt,
  });

  factory LoungePreOrderItem.fromJson(Map<String, dynamic> json) {
    return LoungePreOrderItem(
      id: json['id'] as String? ?? '',
      loungeBookingId: json['lounge_booking_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Unknown Product',
      productType: json['product_type'] as String? ?? 'product',
      productImageUrl: json['product_image_url'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: Lounge._parseDouble(json['unit_price']) ?? 0.0,
      totalPrice:
          Lounge._parseDouble(json['total_price'] ?? json['subtotal']) ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  String get formattedTotalPrice => 'LKR ${totalPrice.toStringAsFixed(2)}';

  /// Alias for backwards compatibility
  double get subtotal => totalPrice;
}

// ============================================================================
// LOUNGE ORDER MODEL (In-lounge orders)
// ============================================================================

class LoungeOrder {
  final String id;
  final String loungeId;
  final String? loungeBookingId;
  final String userId;
  final String orderNumber;
  final double totalAmount;
  final LoungeOrderStatus status;
  final LoungePaymentStatus paymentStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LoungeOrderItem> items;

  LoungeOrder({
    required this.id,
    required this.loungeId,
    this.loungeBookingId,
    required this.userId,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory LoungeOrder.fromJson(Map<String, dynamic> json) {
    return LoungeOrder(
      id: json['id'] as String,
      loungeId: json['lounge_id'] as String,
      loungeBookingId: json['lounge_booking_id'] as String?,
      userId: json['user_id'] as String,
      orderNumber: json['order_number'] as String,
      totalAmount: Lounge._parseDouble(json['total_amount']) ?? 0.0,
      status: LoungeOrderStatus.fromJson(json['status'] as String?),
      paymentStatus: LoungePaymentStatus.fromJson(
        json['payment_status'] as String?,
      ),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => LoungeOrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get formattedTotal => 'LKR ${totalAmount.toStringAsFixed(2)}';
}

// ============================================================================
// LOUNGE ORDER ITEM MODEL
// ============================================================================

class LoungeOrderItem {
  final String id;
  final String loungeOrderId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? specialInstructions;

  LoungeOrderItem({
    required this.id,
    required this.loungeOrderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.specialInstructions,
  });

  factory LoungeOrderItem.fromJson(Map<String, dynamic> json) {
    return LoungeOrderItem(
      id: json['id'] as String,
      loungeOrderId: json['lounge_order_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: Lounge._parseDouble(json['unit_price']) ?? 0.0,
      subtotal: Lounge._parseDouble(json['subtotal']) ?? 0.0,
      specialInstructions: json['special_instructions'] as String?,
    );
  }

  /// Alias for subtotal
  double get totalPrice => subtotal;
}

// ============================================================================
// REQUEST MODELS
// ============================================================================

/// Guest entry for booking
class GuestEntry {
  final String guestName;
  final String? guestPhone;
  final bool isPrimaryGuest;

  GuestEntry({
    required this.guestName,
    this.guestPhone,
    this.isPrimaryGuest = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'guest_name': guestName,
      if (guestPhone != null) 'guest_phone': guestPhone,
      'is_primary_guest': isPrimaryGuest,
    };
  }
}

/// Pre-order item for booking
class PreOrderEntry {
  final String productId;
  final int quantity;
  final String? specialInstructions;

  PreOrderEntry({
    required this.productId,
    required this.quantity,
    this.specialInstructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      if (specialInstructions != null)
        'special_instructions': specialInstructions,
    };
  }
}

/// Request to create a lounge booking
class CreateLoungeBookingRequest {
  final String loungeId;
  final String? busBookingId;
  final String bookingType; // 'pre_trip', 'post_trip', 'standalone'
  final LoungePricingType pricingType;
  final DateTime scheduledArrival;
  final DateTime? scheduledDeparture;
  final int numberOfGuests;
  final String primaryGuestName;
  final String primaryGuestPhone;
  final String? specialRequests;
  final String? promoCode;
  final List<GuestEntry> guests;
  final List<PreOrderEntry> preOrders;

  CreateLoungeBookingRequest({
    required this.loungeId,
    this.busBookingId,
    this.bookingType = 'standalone', // Default to standalone
    required this.pricingType,
    required this.scheduledArrival,
    this.scheduledDeparture,
    required this.numberOfGuests,
    required this.primaryGuestName,
    required this.primaryGuestPhone,
    this.specialRequests,
    this.promoCode,
    this.guests = const [],
    this.preOrders = const [],
  });

  Map<String, dynamic> toJson() {
    // Always include primary guest in the guests array
    final allGuests = [
      {
        'guest_name': primaryGuestName,
        'guest_phone': primaryGuestPhone,
        'is_primary_guest': true,
      },
      ...guests.map((g) => g.toJson()).toList(),
    ];

    return {
      'lounge_id': loungeId,
      if (busBookingId != null) 'bus_booking_id': busBookingId,
      'booking_type': bookingType,
      'scheduled_arrival': scheduledArrival.toUtc().toIso8601String(),
      if (scheduledDeparture != null)
        'scheduled_departure': scheduledDeparture!.toUtc().toIso8601String(),
      'number_of_guests': numberOfGuests,
      'primary_guest_name': primaryGuestName,
      'primary_guest_phone': primaryGuestPhone,
      'pricing_type': pricingType.toJson(),
      if (specialRequests != null && specialRequests!.isNotEmpty)
        'special_requests': specialRequests,
      if (promoCode != null && promoCode!.isNotEmpty) 'promo_code': promoCode,
      'guests': allGuests,
      if (preOrders.isNotEmpty)
        'pre_orders': preOrders.map((p) => p.toJson()).toList(),
    };
  }
}

/// Order item for in-lounge order
class OrderItemEntry {
  final String productId;
  final int quantity;
  final String? specialInstructions;

  OrderItemEntry({
    required this.productId,
    required this.quantity,
    this.specialInstructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      if (specialInstructions != null)
        'special_instructions': specialInstructions,
    };
  }
}

/// Request to create a lounge order
class CreateLoungeOrderRequest {
  final String loungeId;
  final String? loungeBookingId;
  final String? notes;
  final List<OrderItemEntry> items;

  CreateLoungeOrderRequest({
    required this.loungeId,
    this.loungeBookingId,
    this.notes,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'lounge_id': loungeId,
      if (loungeBookingId != null) 'lounge_booking_id': loungeBookingId,
      if (notes != null) 'notes': notes,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

// ============================================================================
// CART ITEM (for UI state management)
// ============================================================================

class CartItem {
  final LoungeProduct product;
  int quantity;
  String? specialInstructions;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.specialInstructions,
  });

  double get subtotal => product.price * quantity;
  String get formattedSubtotal => 'LKR ${subtotal.toStringAsFixed(2)}';

  PreOrderEntry toPreOrderEntry() {
    return PreOrderEntry(
      productId: product.id,
      quantity: quantity,
      specialInstructions: specialInstructions,
    );
  }

  OrderItemEntry toOrderItemEntry() {
    return OrderItemEntry(
      productId: product.id,
      quantity: quantity,
      specialInstructions: specialInstructions,
    );
  }
}
