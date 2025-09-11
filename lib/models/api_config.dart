import 'package:dio/dio.dart';

///[ApiConfig] is a configuration class for API settings.
/// It holds the base URL, default headers, and timeout duration for API requests.
/// This class can be used to centralize and manage API-related configurations.
class ApiConfig {
  final String? baseUrl;

  final Map<String, String>? defaultHeaders;

  final Duration? timeout;

  final bool Function(int?)? validateStatus;

  const ApiConfig({
    this.baseUrl,
    this.defaultHeaders,
    this.timeout,
    this.validateStatus,
  });

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
