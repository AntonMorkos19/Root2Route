const String kBaseUrl = 'https://root2route.runasp.net';

extension ImageUrlHelper on String? {
  /// Converts any image URL to a full, production-ready URL.
  /// - Replaces localhost references with the production domain
  /// - Prepends the base URL for relative paths
  String get fullImageUrl {
    if (this == null || this!.isEmpty) {
      return '';
    }

    String url = this!;

    // Fix localhost URLs from backend
    url = url
        .replaceAll('http://localhost:8081', kBaseUrl)
        .replaceAll('http://localhost', kBaseUrl);

    if (url.startsWith('http')) {
      return url;
    }

    // Ensure proper slash formatting for relative paths
    if (url.startsWith('/')) {
      return '$kBaseUrl$url';
    } else {
      return '$kBaseUrl/$url';
    }
  }
}
