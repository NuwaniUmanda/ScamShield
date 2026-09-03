import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/scam_report.dart';
import '../services/supabase_service.dart';
import '../services/api_service.dart';

class ReportSubmissionView extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;
  const ReportSubmissionView({super.key, this.onNavigateTab});

  @override
  State<ReportSubmissionView> createState() => _ReportSubmissionViewState();
}

class _ReportSubmissionViewState extends State<ReportSubmissionView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _walletController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _lossController = TextEditingController();

  String _selectedScamType = 'phishing';
  bool _isSubmitting = false;
  bool _isAnalyzingAI = false;

  Map<String, dynamic>? _aiPreviewResult;
  final List<PlatformFile> _selectedFiles = [];
  final List<String> _uploadedEvidenceUrls = [];

  final List<Map<String, String>> _scamTypes = [
    {'value': 'phishing', 'label': 'Phishing Website / Link'},
    {'value': 'crypto_investment', 'label': 'Crypto / Ponzi Fraud'},
    {'value': 'impersonation', 'label': 'Bank / Official Impersonation'},
    {'value': 'caller_scam', 'label': 'Phone Call / SMS Fraud'},
    {'value': 'job_scam', 'label': 'Job / Recruitment Fraud'},
    {'value': 'fake_store', 'label': 'Fake E-Commerce Store'},
    {'value': 'romance', 'label': 'Romance / Social Engineering'},
    {'value': 'other', 'label': 'Other Scam Type'},
  ];

  Future<void> _pickEvidenceFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf', 'jpeg'],
      );
      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File selection fallback active')),
        );
      }
    }
  }

  Future<void> _runInstantAIPreview() async {
    if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least a title and description for AI analysis')),
      );
      return;
    }

    setState(() => _isAnalyzingAI = true);
    final loss = double.tryParse(_lossController.text) ?? 0.0;

    final aiResult = await ApiService.instance.analyzeReportWithAI(
      title: _titleController.text,
      description: _descriptionController.text,
      scamType: _selectedScamType,
      targetUrl: _urlController.text.isNotEmpty ? _urlController.text : null,
      targetPhone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      targetWallet: _walletController.text.isNotEmpty ? _walletController.text : null,
      targetEmail: _emailController.text.isNotEmpty ? _emailController.text : null,
      financialLoss: loss,
    );

    if (mounted) {
      setState(() {
        _aiPreviewResult = aiResult;
        _isAnalyzingAI = false;
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final loss = double.tryParse(_lossController.text) ?? 0.0;

    // Upload evidence files to Supabase Storage if selected
    _uploadedEvidenceUrls.clear();
    for (var file in _selectedFiles) {
      if (file.bytes != null) {
        final url = await SupabaseService.instance.uploadEvidence(file.bytes!, file.name);
        if (url != null) {
          _uploadedEvidenceUrls.add(url);
        }
      }
    }

    // Run AI Evaluation if not run yet
    final aiResult = _aiPreviewResult ?? await ApiService.instance.analyzeReportWithAI(
      title: _titleController.text,
      description: _descriptionController.text,
      scamType: _selectedScamType,
      targetUrl: _urlController.text.isNotEmpty ? _urlController.text : null,
      targetPhone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      targetWallet: _walletController.text.isNotEmpty ? _walletController.text : null,
      targetEmail: _emailController.text.isNotEmpty ? _emailController.text : null,
      financialLoss: loss,
    );

    final newReport = ScamReport(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      scamType: _selectedScamType,
      targetUrl: _urlController.text.trim().isNotEmpty ? _urlController.text.trim() : null,
      targetPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      targetWallet: _walletController.text.trim().isNotEmpty ? _walletController.text.trim() : null,
      targetEmail: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      financialLoss: loss,
      status: 'pending',
      riskScore: aiResult['risk_score'] ?? 50,
      aiAnalysis: aiResult,
      evidenceUrls: _uploadedEvidenceUrls,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await SupabaseService.instance.createReport(newReport);

    if (mounted) {
      setState(() => _isSubmitting = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Report Submitted Successfully!',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your scam report has been analyzed by AI and sent to the Admin Review Panel. Once approved, it will be cryptographically registered on the Blockchain.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onNavigateTab?.call(0); // Return to Dashboard
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Return to Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submit Scam Report',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Report suspicious links, calls, or fraud to protect the community.',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Title Input
                _buildLabel('Scam Title / Headline *'),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a descriptive title' : null,
                  decoration: _buildInputDecoration('e.g. Fake Bank Account Suspension SMS'),
                ),
                const SizedBox(height: 16),

                // Scam Type Dropdown
                _buildLabel('Scam Category *'),
                DropdownButtonFormField<String>(
                  initialValue: _selectedScamType,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration('Select Scam Category'),
                  items: _scamTypes.map((type) {
                    return DropdownMenuItem(
                      value: type['value'],
                      child: Text(type['label']!),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedScamType = val);
                  },
                ),
                const SizedBox(height: 16),

                // Incident Description
                _buildLabel('Detailed Incident Description *'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please describe what happened' : null,
                  decoration: _buildInputDecoration('Describe the message received, trick used, and interactions...'),
                ),
                const SizedBox(height: 20),

                // Target Identifiers Section Header
                const Text(
                  'Scammer Details & Target Info',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _buildLabel('Website URL (if applicable)'),
                TextFormField(
                  controller: _urlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration('e.g. http://secure-login-bank.xyz'),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Phone Number'),
                          TextFormField(
                            controller: _phoneController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('+1800...'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Financial Loss (\$)'),
                          TextFormField(
                            controller: _lossController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('0.00'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildLabel('Crypto Wallet Address (if applicable)'),
                TextFormField(
                  controller: _walletController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration('e.g. 0x32Be343B94f860124dC...'),
                ),
                const SizedBox(height: 20),

                // Evidence Attachments Picker
                _buildLabel('Evidence Screenshots / Documents'),
                GestureDetector(
                  onTap: _pickEvidenceFiles,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4), style: BorderStyle.solid),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload_outlined, color: Color(0xFF818CF8)),
                        const SizedBox(width: 10),
                        Text(
                          _selectedFiles.isEmpty ? 'Attach Screenshots or Evidence Files' : '${_selectedFiles.length} file(s) selected',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // AI Risk Preview Button & Card
                OutlinedButton.icon(
                  onPressed: _isAnalyzingAI ? null : _runInstantAIPreview,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF818CF8),
                    side: const BorderSide(color: Color(0xFF818CF8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isAnalyzingAI
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF818CF8)))
                      : const Icon(Icons.psychology_rounded),
                  label: const Text('Preview Instant AI Risk Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
                ),

                if (_aiPreviewResult != null) ...[
                  const SizedBox(height: 16),
                  _buildAIPreviewCard(_aiPreviewResult!),
                ],

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Submit Report to Admin Queue',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildAIPreviewCard(Map<String, dynamic> result) {
    final score = result['risk_score'] ?? 50;
    final level = result['risk_level'] ?? 'MEDIUM';
    final signals = (result['signals'] as List?) ?? [];

    Color levelColor = const Color(0xFF10B981);
    if (score >= 85) {
      levelColor = const Color(0xFFEF4444);
    } else if (score >= 70) {
      levelColor = const Color(0xFFF97316);
    } else if (score >= 45) {
      levelColor = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: levelColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: levelColor, size: 20),
              const SizedBox(width: 8),
              Text('AI Risk Estimate: $score/100 ($level Risk)', style: TextStyle(color: levelColor, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(result['summary'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          if (signals.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...signals.map((sig) => Text('• $sig', style: const TextStyle(color: Colors.white60, fontSize: 11))),
          ]
        ],
      ),
    );
  }
}
