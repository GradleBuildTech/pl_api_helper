import 'package:dio/dio.dart';

/// [ApiConfig] - Configuration class for API settings
///
/// This class centralizes and manages API-related configurations including
/// base URL, headers, timeout, and status validation.
///
/// Key features:
/// - Centralized API configuration
/// - Default headers management
/// - Timeout configuration
/// - Status code validation
/// - Easy conversion to Dio configuration
class ApiConfig {
  /// Base URL for API requests
  final String? baseUrl;

  /// Default headers to include with all requests
  final Map<String, String>? defaultHeaders;

  /// Request timeout duration
  final Duration? timeout;

  /// Function to validate HTTP status codes
  final bool Function(int?)? validateStatus;

  /// Constructor for ApiConfig
  ///
  /// Parameters:
  /// - [baseUrl]: Base URL for API requests
  /// - [defaultHeaders]: Default headers to include with all requests
  /// - [timeout]: Request timeout duration
  /// - [validateStatus]: Function to validate HTTP status codes
  const ApiConfig({
    this.baseUrl,
    this.defaultHeaders,
    this.timeout,
    this.validateStatus,
  });

  /// Create a copy of ApiConfig with updated values
  ///
  /// This method creates a new ApiConfig instance with the same values as the current
  /// instance, but with the specified parameters updated.
  ///
  /// Parameters:
  /// - [baseUrl]: New base URL (optional)
  /// - [defaultHeaders]: New default headers (optional)
  /// - [timeout]: New timeout duration (optional)
  /// - [validateStatus]: New status validation function (optional)
  ///
  /// Returns: New ApiConfig instance with updated values
  ApiConfig copyWith({
    String? baseUrl,
    Map<String, String>? defaultHeaders,
    Duration? timeout,
    bool Function(int?)? validateStatus,
  }) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      timeout: timeout ?? this.timeout,
      validateStatus: validateStatus ?? this.validateStatus,
    );
  }

  /// Convert ApiConfig to Dio configuration
  ///
  /// This method creates a Dio instance configured with the settings from this ApiConfig.
  ///
  /// Returns: Configured Dio instance
  Dio toDio() {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: Duration(
          milliseconds: timeout?.inMilliseconds ?? 30000,
        ),
        receiveTimeout: Duration(
          milliseconds: timeout?.inMilliseconds ?? 30000,
        ),
        headers: defaultHeaders ?? {},
        validateStatus:
            validateStatus ?? (status) => status != null && status < 500,
      ),
    );
  }
}
