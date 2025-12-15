import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  static const TextStyle body = TextStyle(fontSize: 14, color: AppColors.white);
  
  static const TextStyle bodyText1 = TextStyle(fontSize: 16, color: AppColors.white);
  
  static const TextStyle buttonText = TextStyle(
    color: AppColors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle small = TextStyle(
    color: AppColors.white70,
    fontSize: 14,
  );
}
