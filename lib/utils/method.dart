/// [ApiMethod] - Enumeration of HTTP methods
///
/// This enum defines the standard HTTP methods supported by the API helper.
/// Each method has a corresponding string representation for use in HTTP requests.
enum ApiMethod {
  /// HTTP GET method - retrieve data
  get("GET"),

  /// HTTP POST method - create new data
  post("POST"),

  /// HTTP PUT method - update existing data
  put("PUT"),

  /// HTTP DELETE method - remove data
  delete("DELETE");

  /// String representation of the HTTP method
  final String name;

  /// Constructor for ApiMethod
  const ApiMethod(this.name);

  /// Get ApiMethod from string representation
  ///
  /// This method converts a string HTTP method to the corresponding ApiMethod enum.
  /// If the string doesn't match any known method, defaults to GET.
  ///
  /// Parameters:
  /// - [method]: String representation of HTTP method
  ///
  /// Returns: ApiMethod corresponding to the string, or GET if not found
  static ApiMethod fromString(String method) {
    return ApiMethod.values.firstWhere(
      (e) => e.name == method,
      orElse: () => ApiMethod.get,
    );
  }
}
