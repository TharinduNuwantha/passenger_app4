class ApiResponseModel<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponseModel({
    required this.success,
    this.message,
    this.data,
    this.error,
    this.statusCode,
  });

  // Success response
  factory ApiResponseModel.success({
    String? message,
    T? data,
    int? statusCode,
  }) {
    return ApiResponseModel(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode,
    );
  }

  // Error response
  factory ApiResponseModel.error({
    required String error,
    String? message,
    int? statusCode,
  }) {
    return ApiResponseModel(
      success: false,
      message: message,
      error: error,
      statusCode: statusCode,
    );
  }

  // From JSON
  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponseModel(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      error: json['error'] as String?,
      statusCode: json['status_code'] as int?,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'error': error,
      'status_code': statusCode,
    };
  }

  @override
  String toString() {
    return 'ApiResponseModel(success: $success, message: $message, error: $error, statusCode: $statusCode)';
  }
}
