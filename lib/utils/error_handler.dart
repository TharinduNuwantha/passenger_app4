import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../config/constants.dart';

class ErrorHandler {
  static final Logger _logger = Logger();

  // Handle API errors
  static String handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is Exception) {
      return _handleException(error);
    } else {
      _logger.e('Unknown error: $error');
      return AppConstants.unknownError;
    }
  }

  // Handle Dio errors
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        _logger.w('Timeout error: ${error.message}');
        _logger.w('Request URL: ${error.requestOptions.uri}');
        _logger.w('Timeout type: ${error.type}');
        return 'Connection timeout. Please check your internet connection and try again.';

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        _logger.w('Request cancelled');
        return 'Request was cancelled';

      case DioExceptionType.unknown:
        _logger.e('Network error: ${error.message}');
        return AppConstants.networkError;

      default:
        _logger.e('DioException: ${error.message}');
        return AppConstants.unknownError;
    }
  }

  // Handle bad response (4xx, 5xx)
  static String _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    _logger.e('Bad response [$statusCode]: $responseData');

    // Try to extract error message from response
    String? errorMessage;
    if (responseData is Map<String, dynamic>) {
      // For rate limit errors, show the detailed message
      if (statusCode == 429 && responseData['message'] != null) {
        errorMessage = responseData['message'] as String;
      } else {
        errorMessage =
            responseData['error'] as String? ??
            responseData['message'] as String?;
      }
    } else if (responseData is String) {
      errorMessage = responseData;
    }

    // Return appropriate error message based on status code
    switch (statusCode) {
      case 400:
        return errorMessage ?? 'Invalid request. Please check your input.';
      case 401:
        return errorMessage ?? 'Unauthorized. Please login again.';
      case 403:
        return errorMessage ?? 'Access denied.';
      case 404:
        return errorMessage ?? 'Resource not found.';
      case 429:
        return errorMessage ?? AppConstants.tooManyAttemptsError;
      case 500:
      case 502:
      case 503:
        return errorMessage ?? AppConstants.serverError;
      default:
        return errorMessage ?? AppConstants.unknownError;
    }
  }

  // Handle generic exceptions
  static String _handleException(Exception exception) {
    _logger.e('Exception: ${exception.toString()}');

    final exceptionString = exception.toString().toLowerCase();

    if (exceptionString.contains('socket') ||
        exceptionString.contains('network') ||
        exceptionString.contains('connection')) {
      return AppConstants.networkError;
    }

    if (exceptionString.contains('format') ||
        exceptionString.contains('parse')) {
      return 'Invalid data format. Please try again.';
    }

    return AppConstants.unknownError;
  }

  // Log error for debugging
  static void logError(
    String message,
    dynamic error, [
    StackTrace? stackTrace,
  ]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  // Log warning
  static void logWarning(String message) {
    _logger.w(message);
  }

  // Log info
  static void logInfo(String message) {
    _logger.i(message);
  }

  // Log debug
  static void logDebug(String message) {
    _logger.d(message);
  }
}
