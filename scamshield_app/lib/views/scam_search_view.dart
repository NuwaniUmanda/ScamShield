import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/scam_report.dart';
import '../services/supabase_service.dart';
import '../services/api_service.dart';

class ScamSearchView extends StatefulWidget {
  const ScamSearchView({super.key});

  @override
  State<ScamSearchView> createState() => _ScamSearchViewState();
}

class _ScamSearchViewState extends State<ScamSearchView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  List<ScamReport> _reports = [];
  bool _isLoading = false;

  final List<Map<String, String>> _categories = [
    {'key': 'all', 'label': 'All Categories'},
    {'key': 'phishing', 'label': 'Phishing'},
    {'key': 'crypto_investment', 'label': 'Crypto Fraud'},
    {'key': 'impersonation', 'label': 'Impersonation'},
    {'key': 'job_scam', 'label': 'Job Fraud'},
    {'key': 'fake_store', 'label': 'Fake Store'},
  ];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    final results = await SupabaseService.instance.getApprovedReports(
      query: _searchController.text,
      scamType: _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _reports = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scam Database Search',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Search phone numbers, website URLs, wallet addresses & scam patterns',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _performSearch(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type URL, phone (+1800...), wallet (0x...), or keyword',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF818CF8)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Category Filter Chips
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(cat['label']!),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        selectedColor: const Color(0xFF4F46E5),
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF4F46E5) : Colors.white10,
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = cat['key']!;
                          });
                          _performSearch();
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Results Count
              Row(
                children: [
                  Text(
                    'Found ${_reports.length} Verified Records',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF818CF8)),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Results List
              Expanded(
                child: _reports.isEmpty && !_isLoading
                    ? _buildNoResults()
                    : ListView.builder(
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return _buildSearchResultTile(report);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultTile(ScamReport report) {
    return GestureDetector(
      onTap: () => _showReportDetailsModal(report),
      child: Container(
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
                    '${report.riskScore}% RISK',
                    style: TextStyle(color: report.riskColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.formattedScamType,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.title,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Target Attributes Badges
            Row(
              children: [
                if (report.targetUrl != null)
                  Expanded(
                    child: _buildAttributeBadge(Icons.link_rounded, report.targetUrl!),
                  ),
                if (report.targetPhone != null)
                  Expanded(
                    child: _buildAttributeBadge(Icons.phone_rounded, report.targetPhone!),
                  ),
                if (report.targetWallet != null)
                  Expanded(
                    child: _buildAttributeBadge(Icons.account_balance_wallet_rounded, report.targetWallet!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributeBadge(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF818CF8)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDetailsModal(ScamReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Risk Tag
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: report.riskColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: report.riskColor),
                            ),
                            child: Text(
                              'RISK SCORE: ${report.riskScore}/100 (${report.riskLevelText})',
                              style: TextStyle(color: report.riskColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        report.title,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Category: ${report.formattedScamType} • Financial Loss: \$${report.financialLoss.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      const SizedBox(height: 16),

                      const Text('Description:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(report.description, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                      const SizedBox(height: 20),

                      // Target Identifiers Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Target Identifiers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const Divider(color: Colors.white10, height: 20),
                            if (report.targetUrl != null)
                              _buildCopyableRow('Website URL', report.targetUrl!),
                            if (report.targetPhone != null)
                              _buildCopyableRow('Phone Number', report.targetPhone!),
                            if (report.targetWallet != null)
                              _buildCopyableRow('Crypto Wallet', report.targetWallet!),
                            if (report.targetEmail != null)
                              _buildCopyableRow('Email', report.targetEmail!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // AI Analysis Breakdown Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.psychology_rounded, color: Color(0xFF818CF8)),
                                SizedBox(width: 8),
                                Text('AI Risk Evaluation Breakdown', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              report.aiAnalysis['summary'] ?? 'AI Engine scanned and verified fraud indicators.',
                              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            if (report.aiAnalysis['signals'] is List)
                              ...((report.aiAnalysis['signals'] as List).map((sig) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFF59E0B)),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(sig.toString(), style: const TextStyle(color: Colors.white, fontSize: 12))),
                                      ],
                                    ),
                                  ))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Blockchain Verification Card
                      _buildBlockchainVerificationCard(report),
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

  Widget _buildCopyableRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.white54),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied $label to clipboard'), duration: const Duration(seconds: 2)),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildBlockchainVerificationCard(ScamReport report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('Blockchain Immutability Proof', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            report.isBlockchainVerified
                ? 'This scam record has been cryptographically signed and registered on-chain. It cannot be tampered with or deleted.'
                : 'Pending final admin block seal to record hash on-chain.',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (report.isBlockchainVerified) ...[
            const SizedBox(height: 12),
            Text('Transaction Hash:', style: const TextStyle(color: Colors.white60, fontSize: 11)),
            SelectableText(
              report.blockchainTxHash!,
              style: const TextStyle(color: Color(0xFF34D399), fontFamily: 'monospace', fontSize: 11),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await ApiService.instance.verifyBlockchainHash(report.blockchainTxHash!);
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E293B),
                      title: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                          SizedBox(width: 8),
                          Text('On-Chain Verified', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${result['status']}', style: const TextStyle(color: Colors.white70)),
                          Text('Block #: ${result['block_number']}', style: const TextStyle(color: Colors.white70)),
                          Text('Contract: ${result['contract_address']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close', style: TextStyle(color: Color(0xFF818CF8))),
                        )
                      ],
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.shield_rounded, size: 16),
              label: const Text('Verify Cryptographic Proof', style: TextStyle(fontSize: 12)),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 50, color: Colors.white24),
          const SizedBox(height: 12),
          const Text('No matching scam records found', style: TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 6),
          const Text('Try searching with different keywords, URL, or phone number', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
