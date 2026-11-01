import 'scam_report.dart';

class DetectionIndicator {
  final String title;
  final String description;
  final RiskLevel severity;
  final double shapValue;

  const DetectionIndicator({
    required this.title,
    this.description = '',
    this.severity = RiskLevel.high,
    this.shapValue = 0.0,
  });

  factory DetectionIndicator.fromJson(Map<String, dynamic> json) {
    return DetectionIndicator(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      severity: RiskLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['severity'] as String? ?? 'high').toLowerCase(),
        orElse: () => RiskLevel.high,
      ),
      shapValue: (json['shap_value'] as num?)?.toDouble() ??
          (json['shapValue'] as num?)?.toDouble() ??
          0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'severity': severity.name,
    'shap_value': shapValue,
  };
}

class DetectionResult {
  final String id;
  final String analyzedTextOrUrl;
  final String predictedType;
  final double scamProbability; // 0.0 to 100.0
  final RiskLevel riskLevel;
  final double aiConfidence; // 0.0 to 100.0
  final String explanation;
  final List<DetectionIndicator> indicators;
  final List<String> recommendations;
  final DateTime analyzedAt;
  final String? txHash;
  final bool isBlockchainRecorded;

  const DetectionResult({
    required this.id,
    required this.analyzedTextOrUrl,
    required this.predictedType,
    required this.scamProbability,
    required this.riskLevel,
    required this.aiConfidence,
    required this.explanation,
    this.indicators = const [],
    this.recommendations = const [],
    required this.analyzedAt,
    this.txHash,
    this.isBlockchainRecorded = false,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      id: json['id'] as String,
      analyzedTextOrUrl: json['analyzed_input'] as String? ?? '',
      predictedType: json['predicted_type'] as String? ?? 'Suspicious Activity',
      scamProbability: (json['scam_probability'] as num?)?.toDouble() ?? 0.0,
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['risk_level'] as String? ?? 'high').toLowerCase(),
        orElse: () => RiskLevel.high,
      ),
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble() ?? 95.0,
      explanation: json['explanation'] as String? ?? '',
      indicators: (json['indicators'] as List<dynamic>?)
              ?.map((item) => DetectionIndicator.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      analyzedAt: json['analyzed_at'] != null
          ? DateTime.parse(json['analyzed_at'] as String)
          : DateTime.now(),
      txHash: json['tx_hash'] as String?,
      isBlockchainRecorded: json['is_blockchain_recorded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'analyzed_input': analyzedTextOrUrl,
    'predicted_type': predictedType,
    'scam_probability': scamProbability,
    'risk_level': riskLevel.name,
    'ai_confidence': aiConfidence,
    'explanation': explanation,
    'indicators': indicators.map((e) => e.toJson()).toList(),
    'recommendations': recommendations,
    'analyzed_at': analyzedAt.toIso8601String(),
    'tx_hash': txHash,
    'is_blockchain_recorded': isBlockchainRecorded,
  };
}

typedef ScamDetectionResult = DetectionResult;
