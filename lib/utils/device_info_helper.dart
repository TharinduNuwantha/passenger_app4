import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoHelper {
  static final DeviceInfoHelper _instance = DeviceInfoHelper._internal();
  factory DeviceInfoHelper() => _instance;
  DeviceInfoHelper._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Uuid _uuid = const Uuid();

  String? _deviceId;
  String? _deviceType;
  String? _deviceModel;
  String? _osVersion;
  String? _appVersion;
  String? _userAgent;

  /// Initialize device info (call once at app startup)
  Future<void> initialize() async {
    // Get or create device ID
    _deviceId = await _getOrCreateDeviceId();

    // Get device type and model
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      _deviceType = 'android';
      _deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
      _osVersion = 'Android ${androidInfo.version.release}';
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      _deviceType = 'ios';
      _deviceModel = iosInfo.utsname.machine ?? 'iPhone';
      _osVersion = 'iOS ${iosInfo.systemVersion}';
    } else {
      _deviceType = 'unknown';
      _deviceModel = 'Unknown';
      _osVersion = 'Unknown';
    }

    // Get app version
    final packageInfo = await PackageInfo.fromPlatform();
    _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

    // Build custom User-Agent
    _userAgent = _buildUserAgent();
  }

  /// Get or create a unique device ID
  Future<String> _getOrCreateDeviceId() async {
    const key = 'device_id';

    // Try to get existing device ID
    String? deviceId = await _storage.read(key: key);

    if (deviceId == null || deviceId.isEmpty) {
      // Generate new UUID for device
      deviceId = _uuid.v4();
      await _storage.write(key: key, value: deviceId);
    }

    return deviceId;
  }

  /// Build a custom User-Agent string for the app
  String _buildUserAgent() {
    // Format: SmartTransit-Passenger/1.0.0 (Android 12; Samsung SM-G991B)
    return 'SmartTransit-Passenger/$_appVersion ($_osVersion; $_deviceModel)';
  }

  // Getters
  String get deviceId => _deviceId ?? 'unknown';
  String get deviceType => _deviceType ?? 'unknown';
  String get deviceModel => _deviceModel ?? 'Unknown';
  String get osVersion => _osVersion ?? 'Unknown';
  String get appVersion => _appVersion ?? 'Unknown';
  String get userAgent => _userAgent ?? 'SmartTransit-Passenger';

  /// Get all device headers for API requests
  Map<String, String> getDeviceHeaders({String? fcmToken}) {
    return {
      'X-Device-ID': deviceId,
      'X-Device-Type': deviceType,
      'X-Device-Model': deviceModel,
      'X-App-Version': appVersion,
      'X-OS-Version': osVersion,
      'User-Agent': userAgent,
      if (fcmToken != null && fcmToken.isNotEmpty) 'X-FCM-Token': fcmToken,
    };
  }
}
