import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../config/api_config.dart';
import '../utils/error_handler.dart';
import '../utils/device_info_helper.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initializeDio();
  }

  late Dio _dio;
  final StorageService _storage = StorageService();
  final DeviceInfoHelper _deviceInfo = DeviceInfoHelper();
  final Logger _logger = Logger();
  bool _isRefreshing = false;

  Dio get dio => _dio;

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add request interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Skip adding auth token for public auth endpoints
          final isPublicAuthEndpoint =
              options.path.contains('/auth/refresh') ||
              options.path.contains('/auth/send-otp') ||
              options.path.contains('/auth/verify-otp');

          // Add access token to headers if available (except for public auth endpoints)
          if (!isPublicAuthEndpoint) {
            final token = await _storage.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              _logger.d('Added auth token to request: ${options.path}');
            }
          } else {
            // Ensure no Authorization header for public endpoints
            options.headers.remove('Authorization');
            _logger.d(
              'Skipping auth token for public endpoint: ${options.path}',
            );
          }

          // Add device information headers
          final deviceHeaders = _deviceInfo.getDeviceHeaders();
          options.headers.addAll(deviceHeaders);
          _logger.d('Added device headers to request: ${options.path}');

          _logger.d('Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('Response [${response.statusCode}]: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          _logger.e('Error [${error.response?.statusCode}]: ${error.message}');

          // If 401 Unauthorized, try to refresh token
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;

            try {
              // Try to refresh token
              final refreshed = await _refreshToken();

              if (refreshed) {
                // Retry the original request
                _logger.i('Token refreshed, retrying request');
                final response = await _retry(error.requestOptions);
                _isRefreshing = false;
                return handler.resolve(response);
              } else {
                _logger.w('Token refresh failed');
              }
            } catch (e) {
              _logger.e('Error during token refresh: $e');
            } finally {
              _isRefreshing = false;
            }
          }

          return handler.next(error);
        },
      ),
    );

    // Add logging interceptor (only in debug mode)
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => _logger.d(obj),
      ),
    );
  }

  // Refresh token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.w('No refresh token available');
        return false;
      }

      _logger.i('Attempting to refresh token');

      final response = await _dio.post(
        ApiConfig.refreshTokenEndpoint,
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {
            'Authorization': null, // Don't use old token
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Save new tokens
        await _storage.saveTokens(
          accessToken: data['access_token'] as String,
          refreshToken: refreshToken, // Keep the same refresh token
          expiresIn: data['expires_in'] as int,
        );

        _logger.i('Token refreshed successfully');
        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Token refresh error: $e');
      return false;
    }
  }

  // Retry failed request
  Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );

    // Add new access token
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers?['Authorization'] = 'Bearer $token';
    }

    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  // Clear all interceptors
  void clearInterceptors() {
    _dio.interceptors.clear();
  }
}
