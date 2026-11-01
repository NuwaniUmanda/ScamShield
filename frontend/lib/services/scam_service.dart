import '../models/scam_report.dart';
import '../data/mock_data.dart';

abstract class ScamService {
  Future<List<ScamReport>> getAllReports({
    String? query,
    String? category,
    RiskLevel? riskFilter,
    ReportStatus? statusFilter,
  });
  Future<ScamReport?> getReportById(String id);
  Future<ScamReport> submitReport({
    required String title,
    required String scamType,
    required String targetOrSuspect,
    required String description,
    required RiskLevel riskLevel,
    double riskScore,
    List<String> evidenceFiles,
    String? email,
  });
  Future<List<ScamReport>> getMyReports(String userEmail);
}

class MockScamService implements ScamService {
  final List<ScamReport> _reports = List.from(MockData.mockReports);
  final Duration latency;

  MockScamService({this.latency = Duration.zero});

  @override
  Future<List<ScamReport>> getAllReports({
    String? query,
    String? category,
    RiskLevel? riskFilter,
    ReportStatus? statusFilter,
  }) async {
    if (latency > Duration.zero) await Future.delayed(latency);
    var results = List<ScamReport>.from(_reports);

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      results = results.where((r) =>
        r.title.toLowerCase().contains(q) ||
        r.scamType.toLowerCase().contains(q) ||
        r.targetOrSuspect.toLowerCase().contains(q) ||
        r.description.toLowerCase().contains(q) ||
        r.id.toLowerCase().contains(q)
      ).toList();
    }

    if (category != null && category.trim().isNotEmpty && category != 'All Categories') {
      results = results.where((r) => r.scamType.toLowerCase().contains(category.toLowerCase())).toList();
    }

    if (riskFilter != null) {
      results = results.where((r) => r.riskLevel == riskFilter).toList();
    }

    if (statusFilter != null) {
      results = results.where((r) => r.status == statusFilter).toList();
    }

    return results;
  }

  @override
  Future<ScamReport?> getReportById(String id) async {
    if (latency > Duration.zero) await Future.delayed(latency);
    try {
      return _reports.firstWhere((r) => r.id.toLowerCase() == id.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ScamReport> submitReport({
    required String title,
    required String scamType,
    required String targetOrSuspect,
    required String description,
    required RiskLevel riskLevel,
    double riskScore = 88.0,
    List<String> evidenceFiles = const [],
    String? email,
  }) async {
    if (latency > Duration.zero) await Future.delayed(latency);
    final newId = 'REP-${(84921 + _reports.length)}';
    final report = ScamReport(
      id: newId,
      title: title,
      scamType: scamType,
      targetOrSuspect: targetOrSuspect,
      description: description,
      riskLevel: riskLevel,
      status: ReportStatus.pending,
      riskScore: riskScore,
      reportedAt: DateTime.now(),
      txHash: '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}8f31',
      isBlockchainVerified: true,
      evidenceFiles: evidenceFiles,
      reporterEmail: email ?? 'officer@scamshield.io',
    );
    _reports.insert(0, report);
    return report;
  }

  @override
  Future<List<ScamReport>> getMyReports(String userEmail) async {
    if (latency > Duration.zero) await Future.delayed(latency);
    return _reports.where((r) =>
      r.reporterEmail != null && r.reporterEmail!.toLowerCase() == userEmail.toLowerCase()
    ).toList();
  }
}
