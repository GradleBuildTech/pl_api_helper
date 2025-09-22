import 'package:http/http.dart' as http;
import 'package:pl_api_helper/pl_api_helper.dart';
import 'package:pl_api_helper/stream/sstream/base_sstream.dart';

class SstreamHttp extends BaseSstream {
  final http.Client _client = http.Client();

  StreamConfig? _config;

  static SstreamHttp? _instance;

  SstreamHttp._({required super.config});

  factory SstreamHttp.init({required StreamConfig config}) {
    _instance ??= SstreamHttp._(config: config);
    return _instance!;
  }

  static SstreamHttp get instance {
    if (_instance == null) {
      throw Exception(
        'SstreamHttp is not initialized. Call SstreamHttp() first.',
      );
    }
    return _instance!;
  }

  Future<http.Response> get(String url, {Map<String, String>? headers}) {
    return _client.get(Uri.parse(url), headers: headers);
  }

  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) {
    return _client.post(Uri.parse(url), headers: headers, body: body);
  }

  // Add more methods for PUT, DELETE, etc. as needed
}
