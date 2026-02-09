import 'package:flutter/material.dart';
import 'lounge_list_screen.dart';

/// Legacy wrapper kept for backward compatibility.
class LoungesDetailsScreen extends StatelessWidget {
  const LoungesDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoungeListScreen();
  }
}
