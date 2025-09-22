import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pl_api_helper/pl_api_helper.dart'
    show StreamConfig, StreamError;

import 'base_sstream.dart';

///[Singleton] class for handling Dio operations in Sstream.
class SstreamDio extends BaseSstream {
  Dio? _dio;

  static SstreamDio? _instance;

  SstreamDio._({required super.config});

  factory SstreamDio.init({Dio? dio, required StreamConfig config}) {
    assert(dio != null, 'Dio must be provided');
    _instance ??= SstreamDio._(config: config);
    _instance?._dio = dio ?? config.toDio();
    return _instance!;
  }

  static SstreamDio get instance {
    if (_instance == null) {
      throw Exception(
        'SstreamDio is not initialized. Call SstreamDio() first.',
      );
    }
    return _instance!;
  }

  Dio checkDio() {
    if (_dio == null) {
      throw Exception('Dio instance is not initialized.');
    }

    return _dio!;
  }

  /// Handle stream chunk
  void handleStreamChunk<T>({
    required String chunk,
    required StringBuffer responseData,
    required String startParse,
    required String endParse,
    required Response response,
    required StreamController<T> controller,
    required StreamResposneMapper<T> mapper,
    Function()? onDone,
  }) {
    var data = utf8.decode(chunk.codeUnits, allowMalformed: true);
    responseData.write(data);
    final dataList = data
        .split("\n")
        .where((element) => element.trim().isNotEmpty)
        .toList();
    for (final line in dataList) {
      if (line.startsWith(startParse)) {
        final jsonString = line.substring(startParse.length).trim();
        if (jsonString.contains(endParse)) {
          onDone?.call();
          controller.close();
          return;
        }
        final Map<String, dynamic> jsonData = jsonDecode(jsonString);
        controller.add(mapper(jsonData));
        continue;
      }

      try {
        final decodeData = jsonDecode(responseData.toString());
        if (doesErrorExists(decodeData)) {
          final errorMapper = config.parseStreamError;
          controller.addError(
            errorMapper?.call(decodeData) ?? StreamError('Unknown error', 500),
          );
          return;
        }
      } catch (_) {
        continue;
      }
    }
  }

  //Post stream
  Stream<T> postStream<T>({
    required String endpoint,
    required StreamResposneMapper<T> mapper,
    Function(Object error)? onError,
    Function()? onDone,
  }) {
    final dio = checkDio();
    return _handleRequest<T>(
      dio.post(
        dio.options.baseUrl + endpoint,
        options: Options(responseType: ResponseType.stream),
      ),
      mapper,
      onError: onError,
      onDone: onDone,
    );
  }

  //Get stream
  Stream<T> getStream<T>({
    required String endpoint,
    required StreamResposneMapper<T> mapper,
    Function(Object error)? onError,
    Function()? onDone,
  }) {
    final dio = checkDio();
    return _handleRequest<T>(
      dio.get(
        dio.options.baseUrl + endpoint,
        options: Options(responseType: ResponseType.stream),
      ),
      mapper,
      onError: onError,
      onDone: onDone,
    );
  }

  /// Handle stream request
  /// [method] - HTTP method
  /// [request] - Future request
  /// [mapper] - Function to map response data
  /// [onError] - Function to handle errors
  /// [onDone] - Function to call when done
  Stream<T> _handleRequest<T>(
    Future<Response> request,
    StreamResposneMapper<T> mapper, {
    Function(Object error)? onError,
    Function()? onDone,
  }) {
    final controller = StreamController<T>.broadcast();
    final startParse = getStartParse();
    final endParse = getEndParse();
    request
        .then((response) {
          final body = response.data;
          final responseData = StringBuffer();
          (body?.stream).listen(
            (chunk) {
              try {
                handleStreamChunk<T>(
                  mapper: mapper,
                  onDone: onDone,
                  chunk: utf8.decode(chunk, allowMalformed: true),
                  responseData: responseData,
                  startParse: startParse ?? '',
                  endParse: endParse ?? '',
                  response: response,
                  controller: controller,
                );
              } catch (e) {
                controller.addError('Stream parsing error: $e');
                return;
              }
            },
            onError: (error) {
              controller.addError('Stream error: $error');
              return;
            },
            onDone: () {
              controller.close();
            },
            cancelOnError: true,
          );
        })
        .catchError((error) {
          controller.addError('Request error: $error');
          controller.close();
        });
    return controller.stream;
  }
}
