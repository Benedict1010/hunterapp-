class ApiConfig {
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  final String baseUrl;

  const ApiConfig({this.baseUrl = defaultBaseUrl});

  String endpoint(String path) {
    final sanitizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final sanitizedPath = path.startsWith('/') ? path : '/$path';
    return '$sanitizedBase$sanitizedPath';
  }

  Uri uri(String path, [Map<String, dynamic>? queryParameters]) {
    final fullUrl = endpoint(path);
    final baseUri = Uri.parse(fullUrl);
    if (queryParameters == null || queryParameters.isEmpty) {
      return baseUri;
    }
    final formattedQueryParams = queryParameters.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    return baseUri.replace(
      queryParameters: {...baseUri.queryParameters, ...formattedQueryParams},
    );
  }
}
