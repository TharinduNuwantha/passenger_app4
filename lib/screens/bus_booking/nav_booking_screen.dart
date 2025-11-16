import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'Trip_details_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Your Activities",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Tabs UI
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                labelColor: AppColors.primary,
                tabs: const [
                  Tab(text: "Ongoing"),
                  Tab(text: "Completed"),
                ],
              ),
            ),

            // Tab Contents
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildOngoing(), _buildCompleted()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOngoing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.receipt_long, size: 90, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          "You have no ongoing trips at the moment",
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      ],
    );
  }

  //  Completed Trips UI
  Widget _buildCompleted() {
    List<Map<String, String>> completedTrips = [
      {
        "route": "Galle",
        "date": "Sep 12  - 10.45 AM",
        "price": "LKR 1500",
        "bus": "AC Luxury GL-2984",
        "departCity": "Colombo",
        "departTime": "10.45 AM",
        "arrivalCity": "Galle",
        "arrivalTime": "01.45 PM",
        "lounge": "Colombo Gold Lounge",
        "duration": "1 hour",
        "passengers": "1 Adult",
        "loungePrice": "LKR 700",
      },
      {
        "route": "Colombo",
        "date": "Sep 10  - 04.30 PM",
        "price": "LKR 1500",
        "bus": "AC Luxury GL-2984",
        "departCity": "Galle",
        "departTime": "04.30 PM",
        "arrivalCity": "Colombo",
        "arrivalTime": "07.30 PM",
        "lounge": "Galle Lounge",
        "duration": "1 hour",
        "passengers": "1 Adult",
        "loungePrice": "LKR 700",
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedTrips.length,
      itemBuilder: (context, index) {
        final trip = completedTrips[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TripDetailsScreen(trip: trip)),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip["route"]!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(trip["date"]!),
                    Text(trip["price"]!),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios),
              ],
            ),
          ),
        );
      },
    );
  }
}
