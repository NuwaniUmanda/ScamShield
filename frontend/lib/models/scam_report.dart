enum RiskLevel { low, medium, high, critical }

enum ReportStatus { pending, verified, investigating, resolved, rejected }

class ScamReport {
  final String id;
  final String title;
  final String scamType;
  final String targetOrSuspect;
  final String description;
  final RiskLevel riskLevel;
  final ReportStatus status;
  final double riskScore; // 0.0 to 100.0
  final DateTime reportedAt;
  final String? txHash;
  final bool isBlockchainVerified;
  final List<String> evidenceFiles;
  final String? reporterEmail;
  final int reportCount;

  const ScamReport({
    required this.id,
    required this.title,
    required this.scamType,
    required this.targetOrSuspect,
    required this.description,
    required this.riskLevel,
    required this.status,
    required this.riskScore,
    required this.reportedAt,
    this.txHash,
    this.isBlockchainVerified = false,
    this.evidenceFiles = const [],
    this.reporterEmail,
    this.reportCount = 1,
  });

  factory ScamReport.fromJson(Map<String, dynamic> json) {
    return ScamReport(
      id: json['id'] as String,
      title: json['title'] as String,
      scamType: json['scam_type'] as String? ?? 'General Scam',
      targetOrSuspect: json['target_suspect'] as String? ?? '',
      description: json['description'] as String? ?? '',
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['risk_level'] as String? ?? 'low').toLowerCase(),
        orElse: () => RiskLevel.low,
      ),
      status: ReportStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['status'] as String? ?? 'pending').toLowerCase(),
        orElse: () => ReportStatus.pending,
      ),
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      reportedAt: json['reported_at'] != null 
          ? DateTime.parse(json['reported_at'] as String)
          : DateTime.now(),
      txHash: json['tx_hash'] as String?,
      isBlockchainVerified: json['is_blockchain_verified'] as bool? ?? false,
      evidenceFiles: (json['evidence_files'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      reporterEmail: json['reporter_email'] as String?,
      reportCount: (json['report_count'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'scam_type': scamType,
      'target_suspect': targetOrSuspect,
      'description': description,
      'risk_level': riskLevel.name,
      'status': status.name,
      'risk_score': riskScore,
      'reported_at': reportedAt.toIso8601String(),
      'tx_hash': txHash,
      'is_blockchain_verified': isBlockchainVerified,
      'evidence_files': evidenceFiles,
      'reporter_email': reporterEmail,
      'report_count': reportCount,
    };
  }
}
