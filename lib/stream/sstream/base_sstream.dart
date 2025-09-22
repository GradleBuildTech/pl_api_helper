import '../config/stream_config.dart';

typedef StreamResposneMapper<T> = T Function(Map<String, dynamic> data);

///[BaseSstream] is an abstract class that provides common functionality for streaming APIs.
abstract class BaseSstream {
  /// Configuration for the streaming API
  final StreamConfig config;

  BaseSstream({required this.config});

  /// Get the start parse string from the configuration
  String? getStartParse() => config.streamResponseStart;

  /// Get the end parse string from the configuration
  String? getEndParse() => config.streamResponseEnd;

  /// Check if the Dio instance is configured
  bool doesErrorExists(Map<String, dynamic> decodedData) {
    return decodedData.containsKey('error') && decodedData['error'] != null;
  }
}
