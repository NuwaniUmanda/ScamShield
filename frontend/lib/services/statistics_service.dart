import '../models/statistics.dart';
import '../models/scam_report.dart';
import '../data/mock_data.dart';

abstract class StatisticsService {
  Future<DashboardStatistics> getStatistics(List<ScamReport> currentReports);
}

class MockStatisticsService implements StatisticsService {
  @override
  Future<DashboardStatistics> getStatistics(List<ScamReport> currentReports) async {
    await Future.delayed(const Duration(milliseconds: 150));

    // Dynamically calculate based on live reports if available
    final totalCount = currentReports.isNotEmpty ? currentReports.length + 12474 : MockData.mockStats.totalReports;
    final phishingCount = currentReports.where((r) => r.scamType.toLowerCase().contains('phishing')).length + 4316;
    final fakeAccountsCount = currentReports.where((r) => r.scamType.toLowerCase().contains('job') || r.scamType.toLowerCase().contains('impersonation')).length + 2838;
    final scamMessagesCount = currentReports.where((r) => r.scamType.toLowerCase().contains('sms') || r.scamType.toLowerCase().contains('crypto')).length + 3447;
    final verifiedCount = currentReports.where((r) => r.isBlockchainVerified).length + 8534;
    final highRiskCount = currentReports.where((r) => r.riskLevel == RiskLevel.critical || r.riskLevel == RiskLevel.high).length + 9814;
    final resolvedCount = currentReports.where((r) => r.status == ReportStatus.resolved).length + 7608;

    return DashboardStatistics(
      totalReports: totalCount,
      phishingLinks: phishingCount,
      fakeAccounts: fakeAccountsCount,
      scamMessages: scamMessagesCount,
      verifiedReports: verifiedCount,
      detectedScams: highRiskCount,
      blockchainVerified: verifiedCount,
      resolvedCases: resolvedCount,
      aiAccuracyRate: 98.6,
      growthRate: 14.8,
      typeDistributions: MockData.mockStats.typeDistributions,
      monthlyTrends: MockData.mockStats.monthlyTrends,
    );
  }
}
