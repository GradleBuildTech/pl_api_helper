import 'package:pl_api_helper/models/api_error.dart';

class ApiResponse<T> {
  final int? code;
  final String? message;

  final T? _data;

  // use for update avatar of user api
  final String? link;

  final List<String>? errorDetails;

  final Map<String, dynamic>? meta;

  const ApiResponse({
    T? data,
    this.code,
    this.message,
    this.link,
    this.meta,
    this.errorDetails,
  }) : _data = data;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromT,
  ) => ApiResponse<T>(
    data: json['data'] == null ? null : fromT(json['data']),
    code: (json['code'] as num?)?.toInt(),
    message: json['message'] as String?,
    link: json['link'] as String?,
    errorDetails: (json['errorDetails'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
  );
  const ApiResponse.dynamic({
    this.code,
    this.message,
    this.link,
    this.meta,
    this.errorDetails,
  }) : _data = true as T?;

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      <String, dynamic>{
        'code': code,
        'message': message,
        'link': link,
        'errorDetails': errorDetails,
        'data': toJsonT(_data as T),
      };

  T get data => _getData();

  T? get getData => _data;

  String? get errorMessage => errorDetails?.firstOrNull;

  T _getData() {
    if (0 != code && (message?.isNotEmpty ?? false || _data == null)) {
      throw ApiError(message: message!, type: ApiErrorType.unknown);
    }
    return _data as T;
  }
}
