import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'add_new_card.dart';
import 'payment_success_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String bookingPrice;
  final String referenceNo;

  const PaymentMethodScreen({
    super.key,
    required this.bookingPrice,
    required this.referenceNo,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  int selectedCardIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Convert bookingPrice safely to int for math
    final int busFare = int.tryParse(widget.bookingPrice) ?? 0;
    final int loungeFee = 700;
    final int totalAmount = busFare + loungeFee;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + Title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  const Text(
                    "Payment Method",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 80),

              _cardItem("VISA", "**** **** **** 1263", "assets/visa.jpg", 0),
              _cardItem(
                "Master Card",
                "**** **** **** 1682",
                "assets/master.jpg",
                1,
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddNewCardScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("+ Add New Card"),
              ),

              const SizedBox(height: 60),

              // ✅ Price Summary
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Bus fare :"),
                        Text("LKR $busFare"),
                      ],
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text("Lounge fee :"), Text("LKR 700")],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Amount :",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "LKR $totalAmount",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ✅ Pay Now Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentSuccessScreen(
                        referenceNo: widget.referenceNo,
                        totalAmount: totalAmount.toString(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.4),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Pay Now"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardItem(String name, String number, String assetPath, int index) {
    return GestureDetector(
      onTap: () {
        setState(() => selectedCardIndex = index);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selectedCardIndex == index
                ? Colors.blue
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Image.asset(assetPath, height: 35),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(number),
                ],
              ),
            ),
            Radio(
              value: index,
              groupValue: selectedCardIndex,
              onChanged: (value) {
                setState(() => selectedCardIndex = value!);
              },
            ),
          ],
        ),
      ),
    );
  }
}
