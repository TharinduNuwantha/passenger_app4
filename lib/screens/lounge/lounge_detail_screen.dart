import 'package:flutter/material.dart';
import '../../models/lounge_booking_models.dart';
import '../../services/lounge_booking_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import 'lounge_intent_booking_screen.dart';

/// Detailed view of a single lounge with booking option
class LoungeDetailScreen extends StatefulWidget {
  /// The lounge to display (can pass basic info, will fetch full details)
  final Lounge lounge;

  /// Optional: Link to a bus booking
  final String? busBookingId;

  const LoungeDetailScreen({
    super.key,
    required this.lounge,
    this.busBookingId,
  });

  @override
  State<LoungeDetailScreen> createState() => _LoungeDetailScreenState();
}

class _LoungeDetailScreenState extends State<LoungeDetailScreen> {
  final LoungeBookingService _loungeService = LoungeBookingService();

  late Lounge _lounge;
  List<LoungeProduct> _products = [];
  bool _isLoadingProducts = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _lounge = widget.lounge;
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _loungeService.getLoungeProducts(_lounge.id);
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          _buildSliverAppBar(),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Rating
                  _buildHeader(),
                  const SizedBox(height: 16),

                  // Location
                  _buildLocationSection(),
                  const SizedBox(height: 24),

                  // Description
                  if (_lounge.description != null) ...[
                    _buildDescriptionSection(),
                    const SizedBox(height: 24),
                  ],

                  // Amenities
                  if (_lounge.amenities.isNotEmpty) ...[
                    _buildAmenitiesSection(),
                    const SizedBox(height: 24),
                  ],

                  // Pricing
                  _buildPricingSection(),
                  const SizedBox(height: 24),

                  // Products Preview
                  if (!_isLoadingProducts && _products.isNotEmpty) ...[
                    _buildProductsSection(),
                    const SizedBox(height: 24),
                  ],

                  // Contact Info
                  if (_lounge.contactPhone != null) ...[
                    _buildContactSection(),
                    const SizedBox(height: 24),
                  ],

                  // Spacer for bottom button
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBookButton(),
    );
  }

  Widget _buildSliverAppBar() {
    final images = _lounge.images;
    final hasImages = images.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: AppColors.primary),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image or Placeholder
            hasImages
                ? PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      );
                    },
                  )
                : _buildPlaceholder(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                ),
              ),
            ),

            // Image indicators
            if (images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.airline_seat_individual_suite_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Lounge',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _lounge.loungeName,
                style: AppTextStyles.h2.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _lounge.isOperational
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _lounge.isOperational ? 'Open Now' : 'Closed',
                  style: TextStyle(
                    color: _lounge.isOperational
                        ? Colors.green[700]
                        : Colors.red[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_lounge.averageRating != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 4),
                Text(
                  _lounge.averageRating!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lounge.address,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_lounge.state != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _lounge.state!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: AppTextStyles.h3.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _lounge.description!,
          style: TextStyle(color: Colors.grey[700], fontSize: 15, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: AppTextStyles.h3.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _lounge.amenities.map((amenity) {
            return _buildAmenityItem(amenity);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmenityItem(String amenity) {
    IconData icon;
    switch (amenity.toLowerCase()) {
      case 'wifi':
        icon = Icons.wifi;
        break;
      case 'ac':
      case 'air conditioning':
        icon = Icons.ac_unit;
        break;
      case 'tv':
      case 'tv entertainment':
        icon = Icons.tv;
        break;
      case 'cafe':
      case 'cafeteria':
      case 'snacks':
        icon = Icons.local_cafe;
        break;
      case 'charging':
      case 'charging ports':
      case 'charging_ports':
        icon = Icons.power;
        break;
      case 'shower':
        icon = Icons.shower;
        break;
      default:
        icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            amenity,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing',
          style: AppTextStyles.h3.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (_lounge.price1Hour != null)
                _buildPriceRow(
                  '1 Hour',
                  'LKR ${_lounge.price1Hour!.toStringAsFixed(2)}',
                  isFirst: true,
                ),
              if (_lounge.price2Hours != null)
                _buildPriceRow(
                  '2 Hours',
                  'LKR ${_lounge.price2Hours!.toStringAsFixed(2)}',
                ),
              if (_lounge.price3Hours != null)
                _buildPriceRow(
                  '3 Hours',
                  'LKR ${_lounge.price3Hours!.toStringAsFixed(2)}',
                ),
              if (_lounge.priceUntilBus != null)
                _buildPriceRow(
                  'Until Bus Arrives',
                  'LKR ${_lounge.priceUntilBus!.toStringAsFixed(2)}',
                  isLast: true,
                  highlight: true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    String price, {
    bool isFirst = false,
    bool isLast = false,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primary.withOpacity(0.05) : null,
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey[300]!)),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
          Text(
            price,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: highlight ? AppColors.primary : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    final displayProducts = _products.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Menu',
              style: AppTextStyles.h3.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_products.length > 4)
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full menu
                },
                child: Text(
                  'See All (${_products.length})',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayProducts.length,
            itemBuilder: (context, index) {
              return _buildProductCard(displayProducts[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(LoungeProduct product) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: product.imageUrl != null
                ? Image.network(
                    product.imageUrl!,
                    height: 70,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 70,
                      color: Colors.grey[100],
                      child: Icon(Icons.fastfood, color: Colors.grey[400]),
                    ),
                  )
                : Container(
                    height: 70,
                    color: Colors.grey[100],
                    child: Center(
                      child: Icon(Icons.fastfood, color: Colors.grey[400]),
                    ),
                  ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.formattedPrice,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.phone, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  _lounge.contactPhone!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Open phone dialer
            },
            icon: Icon(Icons.call, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Price info
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Starting from',
                  style: TextStyle(color: Colors.grey, fontSize: 13), // Adjusted contrast
                ),
                Text(
                  _lounge.formattedPrice1Hour,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22, // Slightly larger for emphasis
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Book button
          ElevatedButton(
            onPressed: _lounge.isOperational ? _navigateToBooking : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary, // Use secondary (yellow) for consistency with "Book" buttons
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Book Now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 236, 238, 240)),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LoungeIntentBookingScreen(lounge: _lounge, products: _products),
      ),
    );
  }
}
