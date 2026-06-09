const String kBaseUrl = 'https://root2route.runasp.net';

extension ImageUrlHelper on String? {
  String get fullImageUrl {
    if (this == null || this!.isEmpty) {
      return ''; // Or return a default placeholder URL here
    }
    
    if (this!.startsWith('http')) {
      return this!;
    }
    
    // Ensure proper slash formatting
    if (this!.startsWith('/')) {
      return '$kBaseUrl${this!}';
    } else {
      return '$kBaseUrl/${this!}';
    }
  }
}
