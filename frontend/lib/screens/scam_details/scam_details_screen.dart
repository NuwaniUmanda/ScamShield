import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../providers/scam_provider.dart';
import '../../providers/blockchain_provider.dart';
import '../../models/scam_report.dart';
import '../../models/blockchain_verification.dart';
import '../../models/detection_result.dart';
import '../../widgets/section_card.dart';
import '../../widgets/risk_badge.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/breadcrumb.dart';
import '../../widgets/ai_indicator_bar.dart';
import '../../widgets/blockchain_verification_card.dart';

class ScamDetailsScreen extends StatefulWidget {
  final String? reportId;
  final ScamReport? report;
  final VoidCallback? onBack;

  const ScamDetailsScreen({
    super.key,
    this.reportId,
    this.report,
    this.onBack,
  });

  @override
  State<ScamDetailsScreen> createState() => _ScamDetailsScreenState();
}

class _ScamDetailsScreenState extends State<ScamDetailsScreen> {
  ScamReport? _report;
  BlockchainVerification? _blockchainVerification;
  bool _isLoadingReport = true;
  bool _isLoadingBlockchain = true;

  final DateFormat _dateFormat = DateFormat('MMMM d, yyyy • hh:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadReportDetails();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ScamDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reportId != oldWidget.reportId || widget.report != oldWidget.report) {
      _loadReportDetails();
    }
  }

  Future<void> _loadReportDetails() async {
    setState(() {
      _isLoadingReport = true;
      _isLoadingBlockchain = true;
    });

    final scamProvider = context.read<ScamProvider>();
    final blockchainProvider = context.read<BlockchainProvider>();

    if (widget.report != null) {
      _report = widget.report;
      _isLoadingReport = false;
    } else {
      final id = widget.reportId ?? 'REP-84921';
      final r = await scamProvider.getReportById(id);
      if (mounted) {
        setState(() {
          _report = r ?? (scamProvider.allReports.isNotEmpty ? scamProvider.allReports.first : null);
          _isLoadingReport = false;
        });
      }
    }

    if (_report != null) {
      final verification = await blockchainProvider.verifyReport(_report!.id);
      if (mounted) {
        setState(() {
          _blockchainVerification = verification;
          _isLoadingBlockchain = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingBlockchain = false;
        });
      }
    }
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingReport) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final scamProvider = context.watch<ScamProvider>();
    final r = _report ?? (scamProvider.allReports.isNotEmpty ? scamProvider.allReports.first : null);

    if (r == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'Scam report not found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Breadcrumb and Action Header
              _buildPageHeader(r),

              const SizedBox(height: 20),

              // 2. Main Scam Information Hero Card
              _buildScamInformationCard(r),

              const SizedBox(height: 24),

              // 3. Responsive Two-Column Layout: Details / Indicators & Blockchain Verification Card
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 850;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Description, Indicators & AI Explanation
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDescriptionCard(r),
                              const SizedBox(height: 20),
                              _buildIndicatorsAndAiCard(r),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column: Reusable Blockchain Verification Card & Metadata
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BlockchainVerificationCard(
                                verification: _blockchainVerification,
                                report: r,
                                isLoading: _isLoadingBlockchain,
                              ),
                              const SizedBox(height: 20),
                              _buildEvidenceCard(r),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // Mobile / Narrow Layout
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDescriptionCard(r),
                      const SizedBox(height: 20),
                      _buildIndicatorsAndAiCard(r),
                      const SizedBox(height: 20),
                      BlockchainVerificationCard(
                        verification: _blockchainVerification,
                        report: r,
                        isLoading: _isLoadingBlockchain,
                      ),
                      const SizedBox(height: 20),
                      _buildEvidenceCard(r),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(ScamReport r) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Breadcrumb(
          items: [
            BreadcrumbItem(
              label: 'Home',
              onTap: () => context.go(AppRoutes.dashboard),
            ),
            const BreadcrumbItem(label: 'Scam Details'),
          ],
        ),
        SecondaryButton(
          text: 'Back to Search',
          icon: Icons.arrow_back_rounded,
          onPressed: _handleBack,
        ),
      ],
    );
  }

  Widget _buildScamInformationCard(ScamReport r) {
    final isHighRisk = r.riskLevel == RiskLevel.critical || r.riskLevel == RiskLevel.high;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Subtitle
          const Text(
            'Scam Information',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Title Row & Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Badges row matching Figma: High Risk, Verified, Phishing Link, Reported 27 times
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        RiskBadge(
                          level: r.riskLevel,
                          useFullLabel: true,
                        ),
                        StatusBadge(
                          status: r.status,
                          isBlockchainRecorded: r.isBlockchainVerified,
                        ),
                        // Category Badge (e.g. Phishing Link)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            r.scamType,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        // Report count badge: Reported 27 times
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 5),
                              Text(
                                'Reported ${r.reportCount} times',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Visual Risk Score Box: Risk Score 94%
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isHighRisk ? AppColors.riskHighBg : AppColors.riskMediumBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHighRisk ? AppColors.riskHighBorder : AppColors.riskMediumBorder,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Risk Score',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.riskScore.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isHighRisk ? AppColors.highRisk : AppColors.mediumRisk,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(ScamReport r) {
    return SectionCard(
      title: 'Description',
      subtitle: 'Incident overview and target details recorded during verification',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Target / Suspect', r.targetOrSuspect),
          const Divider(height: 20, color: AppColors.borderLight),
          _buildInfoRow('First Logged', _dateFormat.format(r.reportedAt)),
          const Divider(height: 20, color: AppColors.borderLight),
          const Text(
            'Incident Summary:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            r.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorsAndAiCard(ScamReport r) {
    final mockIndicators = [
      const DetectionIndicator(
        title: 'Suspicious URL',
        description: 'URL pattern matches known deceptive domain spoofing tactics.',
        severity: RiskLevel.high,
        shapValue: 0.42,
      ),
      const DetectionIndicator(
        title: 'Urgent Language',
        description: 'Employs artificial time pressure and threats of immediate restriction.',
        severity: RiskLevel.high,
        shapValue: 0.31,
      ),
      const DetectionIndicator(
        title: 'Credential Request',
        description: 'Prompts input of sensitive banking credentials and security questions.',
        severity: RiskLevel.high,
        shapValue: 0.28,
      ),
      const DetectionIndicator(
        title: 'Low Trust Source',
        description: 'Originating domain has low registration age and zero trust reputation.',
        severity: RiskLevel.medium,
        shapValue: 0.18,
      ),
      const DetectionIndicator(
        title: 'External Redirect',
        description: 'Contains obfuscated redirection headers navigating to third-party endpoints.',
        severity: RiskLevel.medium,
        shapValue: 0.15,
      ),
    ];

    return SectionCard(
      title: 'Detection Indicators & AI Explanation',
      subtitle: 'Explainable AI feature weights and social engineering flags',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Explanation Text Callout
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.psychology_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI Explanation: The analyzed target exhibits high lexical similarity to authentic login portals with credential harvesting forms and anomalous redirection chains.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Detection Indicators (SHAP Weights):',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...mockIndicators.map((ind) {
            return AiIndicatorBar(
              title: ind.title,
              shapValue: ind.shapValue,
              description: ind.description,
              severity: ind.severity,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(ScamReport r) {
    return SectionCard(
      title: 'Evidence & Attachments',
      subtitle: 'Recorded cryptographic hashes and submitted proof',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.evidenceFiles.isEmpty)
            const Text(
              'No public evidence files attached.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )
          else
            ...r.evidenceFiles.map((file) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      'Verified Hash',
                      style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
