import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TripDetailsScreen extends StatelessWidget {
  final Map<String, String> trip;
  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Trip Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip["bus"]!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(trip["date"]!),
                    Text(trip["price"]!),
                    const SizedBox(height: 12),

                    // Locations
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.radio_button_checked, size: 16),
                            const SizedBox(width: 6),
                            Text(trip["departCity"]!),
                          ],
                        ),
                        Text(trip["departTime"]!),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.stop_circle, size: 16),
                            const SizedBox(width: 6),
                            Text(trip["arrivalCity"]!),
                          ],
                        ),
                        Text(trip["arrivalTime"]!),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Text(
                      trip["lounge"]!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(trip["duration"]!),
                    Text(trip["passengers"]!),
                    const SizedBox(height: 10),
                    Text(trip["loungePrice"]!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
