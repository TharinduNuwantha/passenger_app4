import 'package:sms_autofill/sms_autofill.dart';
import 'package:logger/logger.dart';

class SmsHelper {
  static final Logger _logger = Logger();

  /// Get the app signature hash required for SMS auto-read
  /// This hash must be included in the SMS message for automatic OTP detection
  static Future<String?> getAppSignature() async {
    try {
      final signature = await SmsAutoFill().getAppSignature;
      return signature;
    } catch (e) {
      _logger.e('Error getting app signature: $e');
      return null;
    }
  }

  /// Print app signature in a formatted way for easy copying
  static Future<void> printAppSignature() async {
    final signature = await getAppSignature();
    if (signature != null) {
      _logger.i('═══════════════════════════════════════');
      _logger.i('🔑 App Signature Hash: $signature');
      _logger.i('═══════════════════════════════════════');
      _logger.i('📋 Add this to your backend .env file:');
      _logger.i('PASSENGER_APP_HASH=$signature');
      _logger.i('═══════════════════════════════════════');
    } else {
      _logger.e('❌ Failed to get app signature');
    }
  }
}
