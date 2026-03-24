import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../localization/app_localization.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    super.key,
    this.title = 'Error',
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final t = (String key) => AppLocalization.tr(context, key);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 28),
          const SizedBox(width: AppSpacing.small),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: Text(t('retryButton')),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: Text(t('ok')),
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    String title = 'Error',
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
    );
  }
}
