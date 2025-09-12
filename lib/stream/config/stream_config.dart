import 'package:dio/dio.dart';
import 'package:pl_api_helper/models/stream_error.dart';

///[StreamConfig] is a configuration class for Stream settings.
class StreamConfig {
  final String baseUrl;

  ///[defaultHeaders] are the headers that will be sent with every request.
  final Map<String, String> defaultHeaders;

  ///[timeout] is the duration for the request to timeout.
  final Duration timeout;

  ///[validateStatus] is a function that takes an integer status code and returns a boolean.
  final bool Function(int?)? validateStatus;

  ///[streamResponseStart] [streamResponseEnd] are used to parse the stream response.
  final String streamResponseStart;

  final String streamResponseEnd;

  ///[parseStreamError] is a function that takes an error and returns a StreamError.
  final StreamError Function(dynamic error)? parseStreamError;

  const StreamConfig({
    required this.baseUrl,
    required this.streamResponseStart,
    required this.streamResponseEnd,
    this.defaultHeaders = const {},
    this.timeout = const Duration(seconds: 30),
    this.validateStatus,
    this.parseStreamError,
  });

  /// Copy with
  StreamConfig copyWith({
    String? baseUrl,
    String? streamResponseStart,
    Map<String, String>? defaultHeaders,
    Duration? timeout,
    bool Function(int?)? validateStatus,
    String? streamResponseEnd,
    StreamError Function(dynamic error)? parseStreamError,
  }) {
    return StreamConfig(
      parseStreamError: parseStreamError,
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
