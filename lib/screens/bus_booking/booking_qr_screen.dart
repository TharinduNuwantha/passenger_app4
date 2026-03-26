// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
import 'check_in_status_screen.dart';

class BookingQRScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const BookingQRScreen({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Navigate to dashboard when back button is pressed
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashBoard()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Navigate back to dashboard
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const DashBoard()),
                (route) => false,
              );
            },
          ),
          title: const Text(
            'Booking QR Code',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: jsonEncode(bookingData),
                        version: QrVersions.auto,
                        size: 250.0,
                        backgroundColor: Colors.white,
                        errorStateBuilder: (cxt, err) {
                          return const Center(
                            child: Text(
                              'Error generating QR code',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Scan this QR code at check-in',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Reference Number Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.secondary, Colors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Reference Number',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bookingData['referenceNo'] ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Booking Details Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_bus,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Trip Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Bus Route
                    _buildDetailRow(
                      Icons.route,
                      'Route',
                      bookingData['route'] ?? 'N/A',
                    ),
                    const SizedBox(height: 12),

                    // Date & Time
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Date & Time',
                      bookingData['dateTime'] ?? 'N/A',
                    ),
                    const SizedBox(height: 12),

                    // Seat Number
                    _buildDetailRow(
                      Icons.airline_seat_recline_normal,
                      'Seat',
                      bookingData['seatNo'] ?? 'N/A',
                    ),
                    const SizedBox(height: 12),

                    // Bus Type
                    _buildDetailRow(
                      Icons.info_outline,
                      'Bus Type',
                      bookingData['busType'] ?? 'N/A',
                    ),

                    // Lounge Bookings Section
                    if (bookingData['loungeBookings'] != null &&
                        (bookingData['loungeBookings'] as List).isNotEmpty) ...[
                      const Divider(height: 32),
                      Row(
                        children: [
                          Icon(Icons.business, color: Colors.orange, size: 24),
                          const SizedBox(width: 12),
                          const Text(
                            'Lounge Bookings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...((bookingData['loungeBookings'] as List).map((lounge) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: lounge['loungeId'] == 'boarding'
                                          ? Colors.orange.shade100
                                          : Colors.purple.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      lounge['loungeId'] == 'boarding'
                                          ? 'Boarding Lounge'
                                          : 'Destination Lounge',
                                      style: TextStyle(
                                        color: lounge['loungeId'] == 'boarding'
                                            ? Colors.orange.shade800
                                            : Colors.purple.shade800,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                lounge['loungeName'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Adults: ${lounge['adults']} | Children: ${lounge['children']}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Price: LKR ${lounge['price']?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),

                              // Marketplace Items
                              if (lounge['marketplaceItems'] != null &&
                                  (lounge['marketplaceItems'] as List)
                                      .isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                const Text(
                                  'Marketplace Items:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...(lounge['marketplaceItems'] as List).map((
                                  item,
                                ) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.shopping_bag,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item['name'] ?? 'N/A',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'LKR ${item['price']?.toStringAsFixed(2) ?? '0.00'}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ],
                          ),
                        );
                      }).toList()),
                    ],

                    // User Details Section
                    const Divider(height: 32),
                    Row(
                      children: [
                        Icon(Icons.person, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Passenger Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildValidatedDetailRow(
                      Icons.account_circle,
                      'Name',
                      bookingData['userName'] ?? '',
                      _validateUserName(bookingData['userName']),
                    ),
                    const SizedBox(height: 12),
                    _buildValidatedDetailRow(
                      Icons.phone,
                      'Phone',
                      _formatPhoneNumber(bookingData['userPhone'] ?? ''),
                      _validatePhoneNumber(bookingData['userPhone']),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Instructions Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstruction('1. Save a screenshot of this QR code'),
                    _buildInstruction('2. Arrive 15 minutes before departure'),
                    _buildInstruction('3. Show QR code at check-in counter'),
                    _buildInstruction('4. Have your ID ready for verification'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Check-In Status Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CheckInStatusScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'View Check-In Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Back to Home Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashBoard(),
                      ),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Home',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidatedDetailRow(
    IconData icon,
    String label,
    String value,
    bool isValid,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isValid ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isValid ? Icons.verified : Icons.warning,
                      size: 16,
                      color: isValid ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: value.isEmpty ? Colors.grey : Colors.black87,
                  ),
                ),
                if (!isValid && value.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label == 'Name'
                          ? 'Name should be 2-50 characters'
                          : 'Phone should be 10 digits',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _validateUserName(dynamic userName) {
    if (userName == null) return false;
    final name = userName.toString().trim();
    // Check if name is not empty, has minimum 2 characters, and maximum 50 characters
    return name.isNotEmpty && name.length >= 2 && name.length <= 50;
  }

  bool _validatePhoneNumber(dynamic phone) {
    if (phone == null) return false;
    final phoneStr = phone.toString().replaceAll(RegExp(r'[^0-9]'), '');
    // Check if phone has exactly 10 digits
    return phoneStr.length == 10;
  }

  String _formatPhoneNumber(String phone) {
    if (phone.isEmpty) return '';
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 10) {
      // Format as (XXX) XXX-XXXX
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    return phone;
  }
}

class CheckInStatusScreen extends StatelessWidget {
  const CheckInStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-In Status')),
      body: const Center(child: Text('Check-In Status Screen')),
    );
  }
}
