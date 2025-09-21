import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

enum ApiErrorType {
  noInternet(code: 0),
  timeout(code: 1),
  unauthorized(code: 401),
  badRequest(code: 400),
  serverUnexpected(code: 500),
  internalServerError(code: 500),
  unknown(code: 520);

  final int code;
  const ApiErrorType({required this.code});

  static ApiErrorType fromCode(int code) {
    return ApiErrorType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ApiErrorType.unknown,
    );
  }
}

class ApiError {
  final ApiErrorType type;
  final String? message;
  final int? statusCode;
  final String? errorCode;

  final RequestOptions? requestOptions;
  final Response<dynamic>? response;
  final Map<String, dynamic>? headers;
  final dynamic body;

  const ApiError({
    required this.type,
    this.message,
    this.statusCode,
    this.errorCode,
    this.requestOptions,
    this.response,
    this.headers,
    this.body,
  });

  factory ApiError.fromDio(DioException error) {
    ApiErrorType type = ApiErrorType.unknown;
    String? message = error.message;
    int? statusCode;
    String? errorCode;
    Map<String, dynamic>? headers;
    dynamic body;

    final request = error.requestOptions;
    final resp = error.response;

    if (resp != null) {
      statusCode = resp.statusCode;
      headers = Map<String, dynamic>.from(resp.headers.map);
      body = resp.data;
    }

    switch (error.type) {
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
        type = ApiErrorType.timeout;
        break;

      case DioExceptionType.badResponse:
        if (body is Map) {
          errorCode = body['code']?.toString();
          message = _getErrorMessage(body);
        }
        if (errorCode == "INVALID_TOKEN" ||
            errorCode == "USER_NOT_FOUND" ||
            statusCode == 401) {
          type = ApiErrorType.unauthorized;
        } else if (statusCode == 400) {
          type = ApiErrorType.badRequest;
        } else {
          type = ApiErrorType.fromCode(statusCode ?? 500);
        }
        break;

      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
        type = ApiErrorType.unknown;
        break;

      case DioExceptionType.unknown:
        if (error.message?.contains("Unexpected character") == true) {
          type = ApiErrorType.serverUnexpected;
        } else {
          type = ApiErrorType.noInternet;
        }
        break;
    }

    return ApiError(
      type: type,
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
      requestOptions: request,
      response: resp,
      headers: headers,
      body: body,
    );
  }

  /// Tạo ApiError từ Response của Dio
  factory ApiError.fromDioResponse(Response<dynamic> response) {
    final data = response.data;
    String? message;

    if (data is Map<String, dynamic>) {
      message = _getErrorMessage(data);
    } else {
      message = "Unexpected response from server";
    }

    return ApiError(
      type: ApiErrorType.fromCode(response.statusCode ?? 500),
      message: message,
      statusCode: response.statusCode,
      errorCode: response.statusCode?.toString(),
      requestOptions: response.requestOptions,
      response: response,
      headers: Map<String, dynamic>.from(response.headers.map),
      body: response.data,
    );
  }

  factory ApiError.fromHttp(http.Response response) {
    final statusCode = response.statusCode;

    final body = response.body;
    String? message;

    try {
      final parsed = _tryParseJson(body);
      if (parsed is Map<String, dynamic>) {
        message = _getErrorMessage(parsed);
      } else {
        message = body;
      }
    } catch (_) {
      message = body;
    }

    return ApiError(
      type: ApiErrorType.fromCode(statusCode),
      message: message,
      statusCode: statusCode,
      errorCode: statusCode.toString(),
      headers: response.headers,
      body: body,
    );
  }

  static dynamic _tryParseJson(String body) {
    try {
      return http.Response.fromStream(
        http.StreamedResponse(Stream.value(body.codeUnits), 200),
      );
    } catch (_) {
      return null;
    }
  }

  static String _getErrorMessage(Map data) {
    try {
      if (data['message'] != null) return data['message'].toString();
      if (data['msg'] != null) return data['msg'].toString();
      if (data['error'] != null) return data['error'].toString();
      if (data['errors'] != null) return data['errors'].toString();
    } catch (_) {}
    return data.toString();
  }
}
