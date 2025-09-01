enum ApiMethod {
  get("GET"),
  post("POST"),
  put("PUT"),
  delete("DELETE");

  final String name;
  const ApiMethod(this.name);

  static ApiMethod fromString(String method) {
    return ApiMethod.values.firstWhere(
      (e) => e.name == method,
      orElse: () => ApiMethod.get,
    );
  }
}
