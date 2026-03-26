class AuthTokensModel {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final DateTime expiryTime;

  AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.expiryTime,
  });

  // From JSON
  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expires_in'] as int;
    final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));

    return AuthTokensModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: expiresIn,
      expiryTime: expiryTime,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'expiry_time': expiryTime.toIso8601String(),
    };
  }

  // Check if token is expired
  bool get isExpired {
    return DateTime.now().isAfter(expiryTime);
  }

  // Check if token needs refresh (within 5 minutes of expiry)
  bool get needsRefresh {
    final fiveMinutesBeforeExpiry = expiryTime.subtract(
      const Duration(minutes: 5),
    );
    return DateTime.now().isAfter(fiveMinutesBeforeExpiry);
  }

  // Time until expiry in minutes
  int get minutesUntilExpiry {
    final duration = expiryTime.difference(DateTime.now());
    return duration.inMinutes;
  }

  @override
  String toString() {
    return 'AuthTokensModel(expiresIn: $expiresIn, expiryTime: $expiryTime, needsRefresh: $needsRefresh)';
  }
}
