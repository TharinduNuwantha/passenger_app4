import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import 'colombo_lounge_screen.dart';
import 'galle_lounge_screen.dart'; // 👈 make sure this file exists!

class LoungeDetailsScreen extends StatefulWidget {
  const LoungeDetailsScreen({super.key});

  @override
  State<LoungeDetailsScreen> createState() => _LoungeDetailsScreenState();
}

class _LoungeDetailsScreenState extends State<LoungeDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? loungeData;

  // Hardcoded lounge info
  final Map<String, Map<String, dynamic>> lounges = {
    "colombo": {
      "image": "assets/Lounge01.jpg",
      "title": "Colombo Gold Lounge",
      "location": "Colombo Central Bus Terminal",
      "price": "LKR 700 per hour",
      "hours": "5 AM – 10 PM",
      "availability": "Available",
      "facilities": ["Wifi", "A/C", "TV Entertainment", "Snacks"],
    },
    "galle": {
      "image": "assets/Lounge02.jpg",
      "title": "Galle Silver Lounge",
      "location": "Galle Main Bus Terminal",
      "price": "LKR 600 per hour",
      "hours": "6 AM – 9 PM",
      "availability": "Available",
      "facilities": ["Wifi", "A/C", "Charging Ports", "Snacks"],
    },
  };

  void _searchLounge() {
    String query = _searchController.text.toLowerCase().trim();
    setState(() {
      loungeData = lounges[query];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lounges Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              // 🔍 Search bar
              TextField(
                controller: _searchController,
                onSubmitted: (_) => _searchLounge(),
                decoration: InputDecoration(
                  hintText: 'Enter city',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _searchLounge,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 20),

              // 🏢 Lounge Info Card (only visible when data found)
              if (loungeData != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    loungeData!["image"] as String,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🏨 Title
                      Row(
                        children: [
                          const Icon(Icons.local_hotel, color: Colors.black54),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loungeData!["title"] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 📍 Location
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text(loungeData!["location"] as String),
                        ],
                      ),

                      // 💰 Price
                      Row(
                        children: [
                          const Icon(Icons.attach_money, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text("Price: ${loungeData!["price"] as String}"),
                        ],
                      ),

                      // ⏰ Hours
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text("Hours: ${loungeData!["hours"] as String}"),
                        ],
                      ),

                      // ✅ Availability
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 6),
                          Text(
                            "Availability: ${loungeData!["availability"] as String}",
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 🛎 Facilities
                      const Row(
                        children: [
                          Icon(Icons.room_service, color: Colors.black54),
                          SizedBox(width: 6),
                          Text(
                            "Facilities:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...List.generate(
                        (loungeData!["facilities"] as List).length,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                (loungeData!["facilities"] as List)[index],
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 🚀 Navigation Button (Dynamic for both lounges)
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            String title = loungeData!["title"] as String;

                            if (title == "Colombo Gold Lounge") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ColomboLoungeScreen(),
                                ),
                              );
                            } else if (title == "Galle Silver Lounge") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const GalleLoungeScreen(),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "No details page available for this lounge.",
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlueAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "View Details",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
