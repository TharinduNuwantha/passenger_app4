import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

class AddNewCardScreen extends StatefulWidget {
  const AddNewCardScreen({super.key});

  @override
  State<AddNewCardScreen> createState() => _AddNewCardScreenState();
}

class _AddNewCardScreenState extends State<AddNewCardScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  String? nameError;
  String? cardError;
  String? expiryError;
  String? cvvError;

  void validate() {
    setState(() {
      nameError =
          nameController.text.isEmpty ||
              !RegExp(r'^[a-zA-Z\s]+$').hasMatch(nameController.text)
          ? "Enter a valid name"
          : null;

      cardError = cardNumberController.text.replaceAll(" ", "").length != 16
          ? "Enter a valid 16-digit card number"
          : null;

      expiryError = !RegExp(r'^\d{2}\/\d{2}$').hasMatch(expiryController.text)
          ? "Enter MM/YY format"
          : null;

      cvvError = cvvController.text.length != 3
          ? "Enter valid 3-digit CVV"
          : null;
    });

    if (nameError == null &&
        cardError == null &&
        expiryError == null &&
        cvvError == null) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  const Text(
                    "Add New Card",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 25),

              _textField(
                "Cardholder Name",
                "Enter Your Name",
                controller: nameController,
                errorText: nameError,
                formatter: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
              ),

              const SizedBox(height: 12),

              _cardNumberField(),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _textField(
                      "Expiry Date",
                      "MM/YY",
                      controller: expiryController,
                      errorText: expiryError,
                      formatter: [
                        FilteringTextInputFormatter.digitsOnly,
                        ExpiryDateFormatter(),
                      ],
                      maxLength: 5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _textField(
                      "CVV",
                      "123",
                      controller: cvvController,
                      errorText: cvvError,
                      formatter: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 3,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: validate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Save", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(
    String title,
    String hint, {
    required TextEditingController controller,
    List<TextInputFormatter>? formatter,
    String? errorText,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLength: maxLength,
          inputFormatters: formatter,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            hintText: hint,
            counterText: "",
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cardNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Card Number", style: TextStyle(color: Colors.white)),
        const SizedBox(height: 6),
        TextField(
          controller: cardNumberController,
          keyboardType: TextInputType.number,
          maxLength: 19,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            counterText: "",
            errorText: cardError,
            hintText: "Enter Card Number",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CardNumberFormatter(),
          ],
        ),
      ],
    );
  }
}

/// Format Card Number (#### #### #### ####)
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(" ", "");
    String formatted = "";

    for (int i = 0; i < digits.length; i++) {
      formatted += digits[i];
      if ((i + 1) % 4 == 0 && i + 1 != digits.length) {
        formatted += " ";
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Format Expiry Date (MM/YY)
class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll("/", "");
    if (digits.length > 4) digits = digits.substring(0, 4);

    String formatted = "";
    for (int i = 0; i < digits.length; i++) {
      formatted += digits[i];
      if (i == 1 && digits.length > 2) {
        formatted += "/";
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
