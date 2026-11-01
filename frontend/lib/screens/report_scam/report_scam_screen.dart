import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../providers/detection_provider.dart';
import '../../widgets/section_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../models/scam_report.dart';

class ReportScamScreen extends StatefulWidget {
  final Function(ScamReport)? onReportSubmitted;

  const ReportScamScreen({
    super.key,
    this.onReportSubmitted,
  });

  @override
  State<ReportScamScreen> createState() => _ReportScamScreenState();
}

class _ReportScamScreenState extends State<ReportScamScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers matching Figma fields
  final _accountNameController = TextEditingController();
  final _suspiciousUrlController = TextEditingController();
  final _messageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reporterNotesController = TextEditingController();

  String _selectedCategory = 'Phishing';
  bool _isAnalyzing = false;
  final List<String> _attachedFiles = ['evidence_screenshot_1.png'];

  final List<String> _categories = [
    'Phishing',
    'Fake Account',
    'Spam / Scam Message',
  ];

  @override
  void dispose() {
    _accountNameController.dispose();
    _suspiciousUrlController.dispose();
    _messageController.dispose();
    _descriptionController.dispose();
    _reporterNotesController.dispose();
    super.dispose();
  }

  Future<void> _handleAnalyzeScam() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields marked with *'),
          backgroundColor: AppColors.highRisk,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    // Prepare data payload for detection provider
    final stagedData = {
      'title': '$_selectedCategory: ${_accountNameController.text.trim()}',
      'category': _selectedCategory,
      'target_or_suspect': _suspiciousUrlController.text.trim().isNotEmpty
          ? _suspiciousUrlController.text.trim()
          : _accountNameController.text.trim(),
      'message': _messageController.text.trim(),
      'description': _descriptionController.text.trim(),
      'reporter_notes': _reporterNotesController.text.trim(),
      'severity': _selectedCategory == 'Phishing' ? RiskLevel.critical : RiskLevel.high,
      'evidence_files': List<String>.from(_attachedFiles),
    };

    final detectionProvider = context.read<DetectionProvider>();
    detectionProvider.stageReportForAnalysis(stagedData);

    // Analysis input prioritize URL, then message, then description
    final scanInput = _suspiciousUrlController.text.trim().isNotEmpty
        ? _suspiciousUrlController.text.trim()
        : (_messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : _descriptionController.text.trim());

    final result = await detectionProvider.scanInput(scanInput);

    if (mounted) {
      setState(() => _isAnalyzing = false);
      if (result != null) {
        context.go(AppRoutes.aiDetection, extra: result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to analyze content. Please verify input.'),
            backgroundColor: AppColors.highRisk,
          ),
        );
      }
    }
  }

  void _handleCancel() {
    _formKey.currentState?.reset();
    _accountNameController.clear();
    _suspiciousUrlController.clear();
    _messageController.clear();
    _descriptionController.clear();
    _reporterNotesController.clear();
    setState(() {
      _selectedCategory = 'Phishing';
      _attachedFiles.clear();
    });
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Card with exact requested heading & description
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x050F172A),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add_moderator_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Report Scam',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tell us about the suspicious account, link or message.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Form Section Card
                SectionCard(
                  title: 'Incident Information',
                  subtitle: 'Fill in details about the suspect entity, suspicious URL, or fraudulent content',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // What are you reporting? *
                      const Text(
                        'What are you reporting? *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCategory = cat);
                              }
                            },
                            selectedColor: AppColors.primarySoft,
                            backgroundColor: AppColors.card,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Account / Page Name *
                      const Text(
                        'Account / Page Name *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _accountNameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Chase Security Alert / ApexYield Crypto / HR Recruiter',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the suspect account, profile, or organization name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Suspicious URL
                      const Text(
                        'Suspicious URL',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _suspiciousUrlController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. http://secure-login-chase-auth92.com/verify or bit.ly/claim-bonus',
                          prefixIcon: Icon(Icons.link, size: 18, color: AppColors.textMuted),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Message
                      const Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Paste the exact text message, email body, or chat transcript received...',
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description *
                      const Text(
                        'Description *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Describe how the fraud occurred, what actions were requested, and any credentials or funds requested...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide a brief description of the incident';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Reporter Notes
                      const Text(
                        'Reporter Notes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _reporterNotesController,
                        decoration: const InputDecoration(
                          hintText: 'Optional internal notes, affected wallet/contact reference, or case ID...',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Evidence / Screenshot Upload Area
                SectionCard(
                  title: 'Evidence / Screenshot',
                  subtitle: 'Attach screenshots of fake pages, messages, or fraudulent transactions',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _attachedFiles.add('evidence_screenshot_${_attachedFiles.length + 1}.png');
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.inputBorder,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_upload_outlined, size: 38, color: AppColors.primary),
                              const SizedBox(height: 10),
                              const Text(
                                'Click or drag files here to upload evidence',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'PNG, JPG, PDF, TXT (Maximum file size 10MB)',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _attachedFiles.add('evidence_screenshot_${_attachedFiles.length + 1}.png');
                                  });
                                },
                                icon: const Icon(Icons.attach_file, size: 16),
                                label: const Text('Select File'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_attachedFiles.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _attachedFiles.map((file) {
                            return Chip(
                              label: Text(file, style: const TextStyle(fontSize: 12)),
                              avatar: const Icon(Icons.image_outlined, size: 16, color: AppColors.primary),
                              onDeleted: () {
                                setState(() {
                                  _attachedFiles.remove(file);
                                });
                              },
                              deleteIconColor: AppColors.highRisk,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bottom Action Buttons matching Figma
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SecondaryButton(
                      text: 'Cancel',
                      onPressed: _isAnalyzing ? null : _handleCancel,
                    ),
                    const SizedBox(width: 14),
                    PrimaryButton(
                      text: 'Analyze Scam',
                      icon: Icons.auto_awesome,
                      isLoading: _isAnalyzing,
                      onPressed: _handleAnalyzeScam,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
