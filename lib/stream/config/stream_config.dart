import 'package:dio/dio.dart';

class StreamConfig {
  final String baseUrl;

  final Map<String, String> defaultHeaders;

  final Duration timeout;

  final bool Function(int?)? validateStatus;

  final String streamResponseStart;

  final String streamResponseEnd;

  const StreamConfig({
    required this.baseUrl,
    required this.streamResponseStart,
    required this.streamResponseEnd,
    this.defaultHeaders = const {},
    this.timeout = const Duration(seconds: 30),
    this.validateStatus,
  });

  /// Copy with
  StreamConfig copyWith({
    String? baseUrl,
    String? streamResponseStart,
    Map<String, String>? defaultHeaders,
    Duration? timeout,
    bool Function(int?)? validateStatus,
    String? streamResponseEnd,
  }) {
    return StreamConfig(
      streamResponseEnd: streamResponseEnd ?? this.streamResponseEnd,
      streamResponseStart: streamResponseStart ?? this.streamResponseStart,
      baseUrl: baseUrl ?? this.baseUrl,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      timeout: timeout ?? this.timeout,
      validateStatus: validateStatus ?? this.validateStatus,
    );
  }

  Dio toDio() {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: timeout.inMilliseconds),
        receiveTimeout: Duration(milliseconds: timeout.inMilliseconds),
        headers: defaultHeaders,
        validateStatus:
            validateStatus ?? (status) => status != null && status < 500,
      ),
    );
  }
}
