class ScamTypeDistribution {
  final String typeName;
  final int count;
  final double percentage;

  const ScamTypeDistribution({
    required this.typeName,
    required this.count,
    required this.percentage,
  });

  factory ScamTypeDistribution.fromJson(Map<String, dynamic> json) {
    return ScamTypeDistribution(
      typeName: json['type_name'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'type_name': typeName,
    'count': count,
    'percentage': percentage,
  };
}

class MonthlyTrendPoint {
  final String month;
  final int reportedCount;
  final int blockedCount;

  const MonthlyTrendPoint({
    required this.month,
    required this.reportedCount,
    required this.blockedCount,
  });

  factory MonthlyTrendPoint.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendPoint(
      month: json['month'] as String? ?? '',
      reportedCount: json['reported_count'] as int? ?? 0,
      blockedCount: json['blocked_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'month': month,
    'reported_count': reportedCount,
    'blocked_count': blockedCount,
  };
}

class DashboardStatistics {
  final int totalReports;
  final int phishingLinks;
  final int fakeAccounts;
  final int scamMessages;
  final int verifiedReports;
  final double totalReportsChange;
  final double phishingLinksChange;
  final double fakeAccountsChange;
  final double scamMessagesChange;
  final double verifiedReportsChange;
  final int detectedScams;
  final int blockchainVerified;
  final int resolvedCases;
  final double aiAccuracyRate;
  final double growthRate;
  final List<ScamTypeDistribution> typeDistributions;
  final List<MonthlyTrendPoint> monthlyTrends;

  const DashboardStatistics({
    required this.totalReports,
    this.phishingLinks = 4320,
    this.fakeAccounts = 2840,
    this.scamMessages = 3450,
    this.verifiedReports = 8540,
    this.totalReportsChange = 12.5,
    this.phishingLinksChange = 18.7,
    this.fakeAccountsChange = 8.2,
    this.scamMessagesChange = -4.3,
    this.verifiedReportsChange = 15.6,
    this.detectedScams = 9820,
    this.blockchainVerified = 8540,
    this.resolvedCases = 7610,
    this.aiAccuracyRate = 98.6,
    this.growthRate = 14.8,
    this.typeDistributions = const [],
    this.monthlyTrends = const [],
  });

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) {
    return DashboardStatistics(
      totalReports: json['total_reports'] as int? ?? 0,
      phishingLinks: json['phishing_links'] as int? ?? 4320,
      fakeAccounts: json['fake_accounts'] as int? ?? 2840,
      scamMessages: json['scam_messages'] as int? ?? 3450,
      verifiedReports: json['verified_reports'] as int? ?? 8540,
      totalReportsChange: (json['total_reports_change'] as num?)?.toDouble() ?? 12.5,
      phishingLinksChange: (json['phishing_links_change'] as num?)?.toDouble() ?? 18.7,
      fakeAccountsChange: (json['fake_accounts_change'] as num?)?.toDouble() ?? 8.2,
      scamMessagesChange: (json['scam_messages_change'] as num?)?.toDouble() ?? -4.3,
      verifiedReportsChange: (json['verified_reports_change'] as num?)?.toDouble() ?? 15.6,
      detectedScams: json['detected_scams'] as int? ?? 0,
      blockchainVerified: json['blockchain_verified'] as int? ?? 0,
      resolvedCases: json['resolved_cases'] as int? ?? 0,
      aiAccuracyRate: (json['ai_accuracy_rate'] as num?)?.toDouble() ?? 99.4,
      growthRate: (json['growth_rate'] as num?)?.toDouble() ?? 12.5,
      typeDistributions: (json['type_distributions'] as List<dynamic>?)
              ?.map((e) => ScamTypeDistribution.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      monthlyTrends: (json['monthly_trends'] as List<dynamic>?)
              ?.map((e) => MonthlyTrendPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'total_reports': totalReports,
    'phishing_links': phishingLinks,
    'fake_accounts': fakeAccounts,
    'scam_messages': scamMessages,
    'verified_reports': verifiedReports,
    'total_reports_change': totalReportsChange,
    'phishing_links_change': phishingLinksChange,
    'fake_accounts_change': fakeAccountsChange,
    'scam_messages_change': scamMessagesChange,
    'verified_reports_change': verifiedReportsChange,
    'detected_scams': detectedScams,
    'blockchain_verified': blockchainVerified,
    'resolved_cases': resolvedCases,
    'ai_accuracy_rate': aiAccuracyRate,
    'growth_rate': growthRate,
    'type_distributions': typeDistributions.map((e) => e.toJson()).toList(),
    'monthly_trends': monthlyTrends.map((e) => e.toJson()).toList(),
  };
}

typedef StatisticsData = DashboardStatistics;
