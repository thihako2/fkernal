/// HTTP methods supported by the framework.
enum HttpMethod {
  /// GET request for fetching data.
  get,

  /// POST request for creating resources.
  post,

  /// PUT request for replacing resources.
  put,

  /// PATCH request for partial updates.
  patch,

  /// DELETE request for removing resources.
  delete,
}

/// Extension methods for HttpMethod.
extension HttpMethodX on HttpMethod {
  /// Returns the HTTP method string.
  String get value {
    switch (this) {
      case HttpMethod.get:
        return 'GET';
      case HttpMethod.post:
        return 'POST';
      case HttpMethod.put:
        return 'PUT';
      case HttpMethod.patch:
        return 'PATCH';
      case HttpMethod.delete:
        return 'DELETE';
    }
  }

  /// Whether this method typically has a request body.
  bool get hasBody {
    switch (this) {
      case HttpMethod.get:
      case HttpMethod.delete:
        return false;
      case HttpMethod.post:
      case HttpMethod.put:
      case HttpMethod.patch:
        return true;
    }
  }

  /// Whether this is a read-only method (safe for caching).
  bool get isReadOnly => this == HttpMethod.get;
}
