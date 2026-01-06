import 'package:flutter/material.dart';
import '../../models/lounge_booking_models.dart';
import '../../services/lounge_booking_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import 'lounge_detail_screen.dart';
import '../../widgets/blue_header.dart';

/// Main lounge marketplace screen - displays available lounges
/// By default loads 5 random lounges, allows search by state
class LoungeListScreen extends StatefulWidget {
  const LoungeListScreen({super.key});

  @override
  State<LoungeListScreen> createState() => _LoungeListScreenState();
}

class _LoungeListScreenState extends State<LoungeListScreen> {
  final LoungeBookingService _loungeService = LoungeBookingService();

  List<Lounge> _lounges = [];
  List<String> _availableStates = [];
  String? _selectedState;
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// Load initial data: 5 random lounges + available states for dropdown
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load both in parallel
      final results = await Future.wait([
        _loungeService.searchLounges(limit: 5),
        _loungeService.getAvailableStates(),
      ]);

      setState(() {
        _lounges = results[0] as List<Lounge>;
        _availableStates = results[1] as List<String>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Search lounges by selected state
  Future<void> _searchByState(String? state) async {
    setState(() {
      _selectedState = state;
      _isSearching = true;
      _error = null;
    });

    try {
      final lounges = await _loungeService.searchLounges(
        state: state,
        limit: state == null ? 5 : null, // Only limit if no state filter
      );

      setState(() {
        _lounges = lounges;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlueHeader(
              padding: EdgeInsets.fromLTRB(20, topInset + 18, 20, 18),
              title: 'Lounges',
              subtitle: 'Discover and book premium lounges',
            ),
            // State Filter Dropdown
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildStateFilter(),
            ),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedState,
                hint: const Text(
                  'Select State / Province',
                  style: TextStyle(color: Colors.grey),
                ),
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                items: [
                  // "All States" option
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All States (Random 5)'),
                  ),
                  // Dynamic states from API
                  ..._availableStates.map((state) {
                    return DropdownMenuItem<String>(
                      value: state,
                      child: Text(state),
                    );
                  }),
                ],
                onChanged: _isSearching ? null : _searchByState,
              ),
            ),
          ),
          if (_isSearching)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.warning,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load lounges',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadInitialData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_lounges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.airline_seat_individual_suite_outlined,
                size: 64,
                color: AppColors.primaryLight,
              ),
              const SizedBox(height: 16),
              Text(
                _selectedState != null
                    ? 'No lounges in $_selectedState'
                    : 'No lounges available',
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _selectedState != null
                    ? 'Try selecting a different state'
                    : 'Check back later for available lounges',
                style: AppTextStyles.body,
              ),
              if (_selectedState != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _searchByState(null),
                  child: const Text(
                    'Show All Lounges',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _searchByState(_selectedState),
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _selectedState != null
                  ? '${_lounges.length} lounge(s) in $_selectedState'
                  : 'Showing ${_lounges.length} lounges',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          
          // Lounge list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _lounges.length,
              itemBuilder: (context, index) {
                return _LoungeCard(
                  lounge: _lounges[index],
                  onTap: () => _navigateToDetail(_lounges[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(Lounge lounge) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoungeDetailScreen(lounge: lounge),
      ),
    );
  }
}

/// Card widget for displaying lounge in list
class _LoungeCard extends StatelessWidget {
  final Lounge lounge;
  final VoidCallback onTap;

  const _LoungeCard({
    required this.lounge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: lounge.primaryImage != null
                  ? Image.network(
                      lounge.primaryImage!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lounge.loungeName,
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lounge.averageRating != null)
                        _buildRating(lounge.averageRating!),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Address
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lounge.address,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Amenities
                  if (lounge.amenities.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: lounge.amenities.take(4).map((amenity) {
                        return _buildAmenityChip(amenity);
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Price and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Starting from',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            lounge.formattedPrice1Hour,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: lounge.isOperational
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          lounge.isOperational ? 'Available' : 'Closed',
                          style: TextStyle(
                            color: lounge.isOperational
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.airline_seat_individual_suite_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Lounge',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRating(double rating) {
    return Row(
      children: [
        const Icon(
          Icons.star,
          size: 18,
          color: Colors.amber,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAmenityChip(String amenity) {
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
        icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.textLight,
          ),
          const SizedBox(width: 4),
          Text(
            amenity,
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
