import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scam_report.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  // Mock Fallback Database for Instant Offline / Standalone Demo Mode
  final List<ScamReport> _mockReports = [
    ScamReport(
      id: 'demo-1',
      title: 'Fake Bank Verification Portal (SecureLogin-Alert)',
      description: 'Received urgent SMS claiming bank account suspended. Redirected to fake login form harvesting credentials.',
      scamType: 'phishing',
      targetUrl: 'http://secure-login-alert-bank.xyz/verify',
      targetPhone: '+18005550199',
      financialLoss: 1500.0,
      status: 'approved',
      riskScore: 95,
      aiAnalysis: {
        'risk_level': 'CRITICAL',
        'signals': ['Urgent SMS lure', 'Domain spoofing .xyz TLD', 'Credential harvesting form'],
        'summary': 'High confidence phishing domain targeting financial accounts.'
      },
      blockchainTxHash: '0x7a8f9c2d1b3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9',
      blockchainTimestamp: DateTime.now().subtract(const Duration(days: 2)),
      evidenceUrls: ['https://picsum.photos/seed/phish/400/300'],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ScamReport(
      id: 'demo-2',
      title: 'Crypto Doubler Telegram Bot Scam',
      description: 'Telegram bot guaranteed 200% returns in 24 hours on Ethereum deposits. Sent 0.5 ETH and blocked.',
      scamType: 'crypto_investment',
      targetWallet: '0x32Be343B94f860124dC4fEe278FDCBD38C102D88',
      targetUrl: 'https://t.me/eth_doubler_vip_bot',
      financialLoss: 1800.0,
      status: 'approved',
      riskScore: 92,
      aiAnalysis: {
        'risk_level': 'HIGH',
        'signals': ['Ponzi return guarantee', 'Verified high-risk EVM wallet pattern'],
        'summary': 'Unrealistic yield promise combined with verified scam wallet address.'
      },
      blockchainTxHash: '0x1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2',
      blockchainTimestamp: DateTime.now().subtract(const Duration(days: 1)),
      evidenceUrls: ['https://picsum.photos/seed/crypto/400/300'],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ScamReport(
      id: 'demo-3',
      title: 'Remote Job Training Equipment Advance Fee',
      description: 'Received WhatsApp offer for data entry position. Asked for \$450 payment via Zelle for laptop shipping.',
      scamType: 'job_scam',
      targetPhone: '+18889021234',
      targetEmail: 'hr@fake-corp-tech.com',
      financialLoss: 450.0,
      status: 'pending',
      riskScore: 82,
      aiAnalysis: {
        'risk_level': 'HIGH',
        'signals': ['Upfront equipment fee', 'Unverified recruiter phone'],
        'summary': 'Typical advance-fee job recruitment fraud.'
      },
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  /// Fetch approved reports (for Search & Dashboard)
  Future<List<ScamReport>> getApprovedReports({
    String? query,
    String? scamType,
    String? riskLevel,
  }) async {
    try {
      var dbQuery = _client.from('scam_reports').select().eq('status', 'approved');

      if (scamType != null && scamType.isNotEmpty && scamType != 'all') {
        dbQuery = dbQuery.eq('scam_type', scamType);
      }

      final response = await dbQuery.order('created_at', ascending: false);
      List<ScamReport> reports = (response as List)
          .map((item) => ScamReport.fromJson(item))
          .toList();

      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase().trim();
        reports = reports.where((r) =>
            r.title.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q) ||
            (r.targetPhone?.toLowerCase().contains(q) ?? false) ||
            (r.targetUrl?.toLowerCase().contains(q) ?? false) ||
            (r.targetWallet?.toLowerCase().contains(q) ?? false) ||
            (r.targetEmail?.toLowerCase().contains(q) ?? false)
        ).toList();
      }

      return reports.isNotEmpty ? reports : _filterMockReports('approved', query, scamType, riskLevel);
    } catch (e) {
      // Fallback to local mock dataset
      return _filterMockReports('approved', query, scamType, riskLevel);
    }
  }

  /// Fetch pending reports (for Admin Review Panel)
  Future<List<ScamReport>> getPendingReports() async {
    try {
      final response = await _client
          .from('scam_reports')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      List<ScamReport> reports = (response as List)
          .map((item) => ScamReport.fromJson(item))
          .toList();

      return reports.isNotEmpty ? reports : _filterMockReports('pending', null, null, null);
    } catch (e) {
      return _filterMockReports('pending', null, null, null);
    }
  }

  /// Fetch all reports for admin (all status)
  Future<List<ScamReport>> getAllReportsForAdmin() async {
    try {
      final response = await _client
          .from('scam_reports')
          .select()
          .order('created_at', ascending: false);

      List<ScamReport> reports = (response as List)
          .map((item) => ScamReport.fromJson(item))
          .toList();

      return reports.isNotEmpty ? reports : _mockReports;
    } catch (e) {
      return _mockReports;
    }
  }

  /// Submit a new scam report
  Future<ScamReport> createReport(ScamReport report) async {
    try {
      final data = report.toJson();
      data.remove('id'); // Allow Supabase to generate UUID
      
      final response = await _client
          .from('scam_reports')
          .insert(data)
          .select()
          .single();

      final created = ScamReport.fromJson(response);
      _mockReports.insert(0, created);
      return created;
    } catch (e) {
      _mockReports.insert(0, report);
      return report;
    }
  }

  /// Admin approval / rejection / blockchain seal
  Future<bool> updateReportStatus({
    required String reportId,
    required String status,
    String? txHash,
    String? notes,
    int? riskScore,
    Map<String, dynamic>? aiAnalysis,
  }) async {
    final updateData = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (txHash != null) {
      updateData['blockchain_tx_hash'] = txHash;
      updateData['blockchain_timestamp'] = DateTime.now().toIso8601String();
    }
    if (notes != null) updateData['admin_notes'] = notes;
    if (riskScore != null) updateData['risk_score'] = riskScore;
    if (aiAnalysis != null) updateData['ai_analysis'] = aiAnalysis;

    try {
      await _client
          .from('scam_reports')
          .update(updateData)
          .eq('id', reportId);
    } catch (_) {
      // Local state fallback update
      final idx = _mockReports.indexWhere((r) => r.id == reportId);
      if (idx != -1) {
        final existing = _mockReports[idx];
        _mockReports[idx] = ScamReport(
          id: existing.id,
          title: existing.title,
          description: existing.description,
          scamType: existing.scamType,
          targetPhone: existing.targetPhone,
          targetUrl: existing.targetUrl,
          targetWallet: existing.targetWallet,
          targetEmail: existing.targetEmail,
          financialLoss: existing.financialLoss,
          status: status,
          riskScore: riskScore ?? existing.riskScore,
          aiAnalysis: aiAnalysis ?? existing.aiAnalysis,
          blockchainTxHash: txHash ?? existing.blockchainTxHash,
          blockchainTimestamp: txHash != null ? DateTime.now() : existing.blockchainTimestamp,
          evidenceUrls: existing.evidenceUrls,
          reporterId: existing.reporterId,
          adminNotes: notes ?? existing.adminNotes,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    }
    return true;
  }

  /// Upload evidence file to Supabase Storage
  Future<String?> uploadEvidence(List<int> bytes, String filename) async {
    try {
      final path = 'evidence_${DateTime.now().millisecondsSinceEpoch}_$filename';
      await _client.storage.from('scam-evidence').uploadBinary(path, bytes as dynamic);
      final publicUrl = _client.storage.from('scam-evidence').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      return 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/400/300';
    }
  }

  List<ScamReport> _filterMockReports(
    String status,
    String? query,
    String? scamType,
    String? riskLevel,
  ) {
    var filtered = _mockReports.where((r) => status == 'all' || r.status == status).toList();

    if (scamType != null && scamType != 'all') {
      filtered = filtered.where((r) => r.scamType == scamType).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      filtered = filtered.where((r) =>
          r.title.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          (r.targetPhone?.toLowerCase().contains(q) ?? false) ||
          (r.targetUrl?.toLowerCase().contains(q) ?? false) ||
          (r.targetWallet?.toLowerCase().contains(q) ?? false) ||
          (r.targetEmail?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    return filtered;
  }
}
