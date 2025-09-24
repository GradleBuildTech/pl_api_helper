import 'package:pl_api_helper/models/api_error.dart';

/// [ApiResponse] - Generic response wrapper for API calls
///
/// This class provides a standardized structure for API responses,
/// including success/error status, data, and metadata.
///
/// Generic type T allows for type-safe data handling.
///
/// Key features:
/// - Generic type support for any data type
/// - Standardized response structure
/// - Error handling and validation
/// - Metadata support for pagination, etc.
/// - Link support for file uploads
class ApiResponse<T> {
  /// HTTP status code from the API response
  final int? code;

  /// Response message from the API
  final String? message;

  /// Private data field (accessed through getter)
  final T? _data;

  /// Link field, commonly used for file upload responses (e.g., avatar URLs)
  final String? link;

  /// Detailed error information if the request failed
  final List<String>? errorDetails;

  /// Additional metadata (pagination, timestamps, etc.)
  final Map<String, dynamic>? meta;

  /// Constructor for ApiResponse
  ///
  /// Parameters:
  /// - [data]: Response data of type T
  /// - [code]: HTTP status code
  /// - [message]: Response message
  /// - [link]: Link field (commonly for file uploads)
  /// - [meta]: Additional metadata
  /// - [errorDetails]: Detailed error information
  const ApiResponse({
    T? data,
    this.code,
    this.message,
    this.link,
    this.meta,
    this.errorDetails,
  }) : _data = data;

  /// Factory constructor to create ApiResponse from JSON
  ///
  /// This method parses JSON data and creates an ApiResponse instance.
  /// The [fromT] function is used to convert the JSON data to the desired type T.
  ///
  /// Parameters:
  /// - [json]: JSON data as Map<String, dynamic>
  /// - [fromT]: Function to convert JSON data to type T
  ///
  /// Returns: ApiResponse<T> instance
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromT,
  ) =>
      ApiResponse<T>(
        data: json['data'] == null ? null : fromT(json['data']),
        code: (json['code'] as num?)?.toInt(),
        message: json['message'] as String?,
        link: json['link'] as String?,
        errorDetails: (json['errorDetails'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      );

  /// Constructor for dynamic ApiResponse (used when data type is not important)
  ///
  /// This constructor is used when you need an ApiResponse but don't care about
  /// the specific data type, or when the response doesn't contain data.
  const ApiResponse.dynamic({
    this.code,
    this.message,
    this.link,
    this.meta,
    this.errorDetails,
  }) : _data = true as T?;

  /// Convert ApiResponse to JSON format
  ///
  /// This method serializes the ApiResponse back to JSON format.
  /// The [toJsonT] function is used to convert the data to JSON format.
  ///
  /// Parameters:
  /// - [toJsonT]: Function to convert data of type T to JSON
  ///
  /// Returns: Map<String, dynamic> representing the JSON data
  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      <String, dynamic>{
        'code': code,
        'message': message,
        'link': link,
        'errorDetails': errorDetails,
        'data': toJsonT(_data as T),
      };

  /// Get the response data with validation
  ///
  /// This getter returns the data and validates that the response is successful.
  /// Throws an ApiError if the response indicates an error.
  ///
  /// Returns: T - The response data
  ///
  /// Throws: ApiError if response indicates an error
  T get data => _getData();

  /// Get the raw data without validation
  ///
  /// This getter returns the raw data without any validation.
  /// Use this when you want to handle errors manually.
  ///
  /// Returns: T? - The raw response data (can be null)
  T? get getData => _data;

  /// Get the first error message from error details
  ///
  /// Returns: String? - The first error message, or null if no errors
  String? get errorMessage => errorDetails?.firstOrNull;

  /// Internal method to get data with validation
  ///
  /// This method validates the response and throws an error if the response
  /// indicates a failure (non-zero code with message or null data).
  ///
  /// Returns: T - The validated response data
  ///
  /// Throws: ApiError if response indicates an error
  T _getData() {
    if (0 != code && (message?.isNotEmpty ?? false || _data == null)) {
      throw ApiError(message: message!, type: ApiErrorType.unknown);
    }
    return _data as T;
  }
}
