// lib/screens/lounges_details_screen.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart'; // Assuming you have AppTextStyles

class LoungesDetailsScreen extends StatelessWidget {
  const LoungesDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lounges Details',
          style: AppTextStyles.h2.copyWith(color: AppColors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Boarding Lounge Section
            Text(
              'Boarding Lounge',
              style: AppTextStyles.h3.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 10),
            _buildLoungeCard(
              context,
              name: 'Colombo Gold Lounge',
              price: 'LKR 500',
              rating: 4, // 4 stars shown in image
              imagePath: 'assets/lounge1.png', // Placeholder path
            ),
            const SizedBox(height: 30),

            // Destination Lounge Section
            Text(
              'Destination Lounge',
              style: AppTextStyles.h3.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 10),
            _buildLoungeCard(
              context,
              name: 'Galle Premium Lounge',
              price: 'LKR 500',
              rating: 3, // 3 stars shown in image
              imagePath: 'assets/lounge2.png', // Placeholder path
            ),
            const SizedBox(height: 50),

            // Note: Add a Continue button/final CTA here if needed,
            // based on the flow after selecting lounges.
          ],
        ),
      ),
    );
  }

  Widget _buildLoungeCard(
    BuildContext context, {
    required String name,
    required String price,
    required int rating,
    required String imagePath,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              // Use a real image path or NetworkImage/Container for a placeholder
              child: Image.asset(
                imagePath,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: const Center(child: Text('Lounge Image')),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: AppTextStyles.h3.copyWith(color: AppColors.primary),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRatingAndPrice(rating, price),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Add logic to view lounge details
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Colors.blueGrey),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                  ),
                  child: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingAndPrice(int rating, String price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 20,
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Price : $price',
          style: AppTextStyles.body.copyWith(color: AppColors.black54),
        ),
      ],
    );
  }
}
