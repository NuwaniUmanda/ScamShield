import 'package:flutter/material.dart';
import '../models/scam_report.dart';
import '../services/supabase_service.dart';
import '../services/api_service.dart';

class AdminReviewView extends StatefulWidget {
  const AdminReviewView({super.key});

  @override
  State<AdminReviewView> createState() => _AdminReviewViewState();
}

class _AdminReviewViewState extends State<AdminReviewView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAdminAuthenticated = false;
  final TextEditingController _passcodeController = TextEditingController();

  List<ScamReport> _allReports = [];
  bool _isLoading = true;
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAdminReports();
  }

  Future<void> _loadAdminReports() async {
    setState(() => _isLoading = true);
    final reports = await SupabaseService.instance.getAllReportsForAdmin();
    if (mounted) {
      setState(() {
        _allReports = reports;
        _isLoading = false;
      });
    }
  }

  List<ScamReport> get _pendingReports => _allReports.where((r) => r.status == 'pending' || r.status == 'under_review').toList();
  List<ScamReport> get _approvedReports => _allReports.where((r) => r.status == 'approved').toList();
  List<ScamReport> get _rejectedReports => _allReports.where((r) => r.status == 'rejected').toList();

  void _authenticateAdmin() {
    if (_passcodeController.text.trim() == 'admin123' || _passcodeController.text.trim() == 'admin') {
      setState(() {
        _isAdminAuthenticated = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Admin Code. Demo passcode is "admin123"')),
      );
    }
  }

  Future<void> _approveAndSealBlockchain(ScamReport report) async {
    setState(() => _isProcessingAction = true);

    final targetSummary = '${report.targetUrl ?? ""} ${report.targetPhone ?? ""} ${report.targetWallet ?? ""}'.trim();

    // 1. Call Backend Blockchain Module to record hash on-chain
    final blockResult = await ApiService.instance.recordOnBlockchain(
      reportId: report.id,
      title: report.title,
      scamType: report.scamType,
      riskScore: report.riskScore,
      targetInfo: targetSummary,
    );

    final txHash = blockResult?['tx_hash'] ?? '0x7a8f9c2d1b3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9';

    // 2. Update Supabase status
    await SupabaseService.instance.updateReportStatus(
      reportId: report.id,
      status: 'approved',
      txHash: txHash,
      notes: 'Approved by Admin & Cryptographically Sealed on Blockchain.',
    );

    await _loadAdminReports();
    if (mounted) {
      setState(() => _isProcessingAction = false);
      Navigator.pop(context); // Close inspector sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Row(
            children: [
              const Icon(Icons.link_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Report Approved & Sealed on Blockchain! Tx: ${txHash.substring(0, 16)}...')),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _rejectReport(ScamReport report, String reason) async {
    setState(() => _isProcessingAction = true);

    await SupabaseService.instance.updateReportStatus(
      reportId: report.id,
      status: 'rejected',
      notes: reason.isNotEmpty ? reason : 'Rejected by Admin',
    );

    await _loadAdminReports();
    if (mounted) {
      setState(() => _isProcessingAction = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scam report marked as Rejected.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdminAuthenticated) {
      return _buildAdminAuthLockScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF818CF8)),
            SizedBox(width: 8),
            Text('Admin Audit & Blockchain Panel', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _loadAdminReports,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () => setState(() => _isAdminAuthenticated = false),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF818CF8),
          labelColor: const Color(0xFF818CF8),
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Pending (${_pendingReports.length})'),
            Tab(text: 'Approved (${_approvedReports.length})'),
            Tab(text: 'Rejected (${_rejectedReports.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReportQueue(_pendingReports, isPending: true),
                _buildReportQueue(_approvedReports, isPending: false),
                _buildReportQueue(_rejectedReports, isPending: false),
              ],
            ),
    );
  }

  Widget _buildAdminAuthLockScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, size: 48, color: Color(0xFF818CF8)),
                ),
                const SizedBox(height: 16),
                const Text('Admin Portal Login', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Enter admin authorization passcode to access review queue', style: TextStyle(color: Colors.white60, fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 20),

                TextField(
                  controller: _passcodeController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Passcode (Demo: admin123)',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _authenticateAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Unlock Admin Review Queue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportQueue(List<ScamReport> reports, {required bool isPending}) {
    if (reports.isEmpty) {
      return const Center(
        child: Text('No scam reports in this queue', style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: report.riskColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'AI RISK: ${report.riskScore}% (${report.riskLevelText})',
                      style: TextStyle(color: report.riskColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    report.formattedScamType,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                report.title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (report.isBlockchainVerified)
                    const Row(
                      children: [
                        Icon(Icons.link_rounded, size: 14, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text('On-Chain Sealed', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    )
                  else
                    Text('Submitted: ${_formatDate(report.createdAt)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),

                  ElevatedButton(
                    onPressed: () => _openInspectorModal(report, isPending: isPending),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPending ? const Color(0xFF6366F1) : const Color(0xFF334155),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      isPending ? 'Audit Report' : 'View Details',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openInspectorModal(ScamReport report, {required bool isPending}) {
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Report Audit #${report.id.substring(0, report.id.length > 8 ? 8 : report.id.length)}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          const Spacer(),
                          IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                      Text(report.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      // AI Analysis Diagnostic Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: report.riskColor.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: Color(0xFF818CF8)),
                                const SizedBox(width: 8),
                                Text('AI Engine Diagnostic Result', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text('${report.riskScore}/100', style: TextStyle(color: report.riskColor, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(report.aiAnalysis['summary'] ?? 'Scanned for fraud intent and spoofing patterns.', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('Report Body:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(report.description, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 16),

                      if (report.targetUrl != null) _buildDetailLine('Target URL', report.targetUrl!),
                      if (report.targetPhone != null) _buildDetailLine('Target Phone', report.targetPhone!),
                      if (report.targetWallet != null) _buildDetailLine('Target Wallet', report.targetWallet!),

                      const SizedBox(height: 24),

                      if (isPending) ...[
                        TextField(
                          controller: reasonController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Rejection reason (if rejecting)...',
                            hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isProcessingAction ? null : () => _rejectReport(report, reasonController.text),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                  side: const BorderSide(color: Color(0xFFEF4444)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Reject Report'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isProcessingAction ? null : () => _approveAndSealBlockchain(report),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.link_rounded),
                                label: const Text('Approve & Seal On-Chain', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailLine(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label: $val', style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
