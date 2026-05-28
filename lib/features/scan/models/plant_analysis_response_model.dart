 
class PlantAnalysisResponseModel {
   final String? diseaseName;

  /// Confidence of the prediction, expressed as a fraction [0.0 – 1.0].
  final double? confidenceScore;

  /// Treatment / action recommendation from the model.
  final String? recommendation;

  /// Severity level (e.g. "Low", "Medium", "High", "Critical").
  final String? severity;

  /// Raw message returned by the backend (may duplicate diseaseName).
  final String? message;

  /// Whether the backend considers this a successful analysis.
  final bool succeeded;

  const PlantAnalysisResponseModel({
    this.diseaseName,
    this.confidenceScore,
    this.recommendation,
    this.severity,
    this.message,
    this.succeeded = false,
  });

  factory PlantAnalysisResponseModel.fromJson(Map<String, dynamic> json) {
    // The actual payload may sit inside a `data` envelope or at the root.
    final Map<String, dynamic> data =
        (json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : null) ??
        json;

    // ── confidence: accept decimal [0-1] or percentage [0-100] ──────────────
    double? confidence;
    final rawConf =
        data['confidenceScore'] ??
        data['ConfidenceScore'] ??
        data['confidence'] ??
        data['Confidence'];
    if (rawConf != null) {
      final parsed =
          rawConf is num
              ? rawConf.toDouble()
              : double.tryParse(rawConf.toString());
      if (parsed != null) {
        // Normalise percentages to [0, 1]
        confidence = parsed > 1.0 ? parsed / 100.0 : parsed;
      }
    }

    // ── succeeded flag ───────────────────────────────────────────────────────
    final succeededRaw =
        json['succeeded'] ??
        json['success'] ??
        json['isSuccess'] ??
        json['IsSuccess'];
    final succeeded = succeededRaw == true || succeededRaw == 1;

    return PlantAnalysisResponseModel(
      diseaseName: (data['diseaseName'] ??
              data['DiseaseName'] ??
              data['disease'] ??
              data['Disease'] ??
              data['label'] ??
              data['Label'] ??
              json['message'] ??
              json['Message'])
          ?.toString(),
      confidenceScore: confidence,
      recommendation: (data['recommendation'] ??
              data['Recommendation'] ??
              data['treatment'] ??
              data['Treatment'] ??
              data['advice'] ??
              data['Advice'])
          ?.toString(),
      severity: (data['severity'] ??
              data['Severity'] ??
              data['level'] ??
              data['Level'])
          ?.toString(),
      message: (json['message'] ?? json['Message'])?.toString(),
      succeeded: succeeded,
    );
  }

  /// Confidence expressed as a percentage string (e.g. "87.3%").
  String get confidencePercent {
    if (confidenceScore == null) return 'N/A';
    return '${(confidenceScore! * 100).toStringAsFixed(1)}%';
  }

  @override
  String toString() =>
      'PlantAnalysisResponseModel(diseaseName: $diseaseName, '
      'confidence: $confidencePercent, severity: $severity, '
      'recommendation: $recommendation)';
}
