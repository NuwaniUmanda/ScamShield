import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../providers/detection_provider.dart';
import '../../providers/scam_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/section_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/breadcrumb.dart';
import '../../widgets/visual_risk_score.dart';
import '../../widgets/ai_indicator_bar.dart';
import '../../models/detection_result.dart';
import '../../models/scam_report.dart';

class AiDetectionScreen extends StatefulWidget {
  /// The screen can receive a ScamDetectionResult directly (optional).
  /// If not provided, it reads from DetectionProvider or fallback mock data.
  final ScamDetectionResult? result;

  const AiDetectionScreen({
    super.key,
    this.result,
  });

  @override
  State<AiDetectionScreen> createState() => _AiDetectionScreenState();
}

class _AiDetectionScreenState extends State<AiDetectionScreen> {
  late final TextEditingController _inputController;
  bool _isSubmittingReport = false;
  ScamDetectionResult? _customResult;

  @override
  void initState() {
    super.initState();
    _customResult = widget.result;
    final detectionProvider = context.read<DetectionProvider>();
    _inputController = TextEditingController(
      text: _customResult?.analyzedTextOrUrl ?? detectionProvider.currentInput,
    );
  }

  @override
  void didUpdateWidget(covariant AiDetectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.result != oldWidget.result && widget.result != null) {
      setState(() {
        _customResult = widget.result;
        _inputController.text = widget.result!.analyzedTextOrUrl;
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _handleScan() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    
    // Clear custom passed result to show newly scanned provider result
    setState(() => _customResult = null);
    await context.read<DetectionProvider>().scanInput(text);
  }

  Future<void> _handleReportThisScam(ScamDetectionResult res) async {
    setState(() => _isSubmittingReport = true);

    final detectionProvider = context.read<DetectionProvider>();
    final scamProvider = context.read<ScamProvider>();
    final staged = detectionProvider.stagedReportData;

    try {
      final report = await scamProvider.submitReport(
        title: (staged?['title'] as String?)?.isNotEmpty == true
            ? staged!['title'] as String
            : 'AI Flagged: ${res.predictedType}',
        scamType: staged?['category'] as String? ?? res.predictedType,
        targetOrSuspect: (staged?['target_or_suspect'] as String?)?.isNotEmpty == true
            ? staged!['target_or_suspect'] as String
            : res.analyzedTextOrUrl,
        description: (staged?['description'] as String?)?.isNotEmpty == true
            ? staged!['description'] as String
            : res.explanation,
        riskLevel: res.riskLevel,
        riskScore: res.scamProbability,
        evidenceFiles: staged?['evidence_files'] != null
            ? List<String>.from(staged!['evidence_files'] as List)
            : ['ai_shap_analysis_evidence.json'],
        email: staged?['email'] as String? ?? 'victim_protection@scamshield.io',
      );

      if (mounted) {
        context.read<StatsProvider>().updateStatistics(scamProvider.allReports);
        detectionProvider.clearStagedReport();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Scam incident ${report.id} successfully recorded and secured on blockchain ledger!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        context.go(AppRoutes.scamDetailsPath(report.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit report. Please try again.'),
            backgroundColor: AppColors.highRisk,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReport = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detectionProvider = context.watch<DetectionProvider>();
    final res = _customResult ?? detectionProvider.lastResult ?? detectionProvider.defaultResult;
    final isScanning = detectionProvider.isScanning;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header & Breadcrumbs
              _buildPageHeader(),

              const SizedBox(height: 20),

              // Live Scanner Input Bar
              _buildScannerBar(isScanning),

              const SizedBox(height: 24),

              // Scanning Loader
              if (isScanning)
                _buildScanningState()
              else if (detectionProvider.errorMessage != null && _customResult == null)
                _buildErrorState(detectionProvider.errorMessage!)
              else
                _buildResultContent(res),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Breadcrumb(
          items: [
            BreadcrumbItem(
              label: 'Home',
              onTap: () => context.go(AppRoutes.dashboard),
            ),
            BreadcrumbItem(
              label: 'AI Detection',
              onTap: () => context.go(AppRoutes.aiDetection),
            ),
            const BreadcrumbItem(label: 'Result'),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            const Text(
              'AI Detection Result',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'SHAP Explainable AI Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScannerBar(bool isScanning) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: 'Enter URL, suspicious SMS, or email text to re-evaluate...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                suffixIcon: _inputController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                        onPressed: () => _inputController.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppColors.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _handleScan(),
            ),
          ),
          const SizedBox(width: 12),
          PrimaryButton(
            text: 'Analyze',
            icon: Icons.auto_awesome,
            isLoading: isScanning,
            onPressed: _handleScan,
          ),
        ],
      ),
    );
  }

  Widget _buildScanningState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          SizedBox(height: 20),
          Text(
            'Analyzing content with Multi-Vector SHAP AI...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Extracting lexical features, urgency triggers, domain trust, and redirection chains',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.riskHighBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.riskHighBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.highRisk, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.highRisk,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent(ScamDetectionResult res) {
    final isPotentialScam = res.riskLevel == RiskLevel.high ||
        res.riskLevel == RiskLevel.critical ||
        res.scamProbability >= 70;

    final verdictText = isPotentialScam ? 'Potential Scam Detected' : 'Content Verified Safe';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Visual Risk Score Section (Figma specification)
        VisualRiskScore(
          score: res.scamProbability,
          confidence: res.aiConfidence,
          category: res.predictedType,
          riskLevel: res.riskLevel,
          verdict: verdictText,
        ),

        const SizedBox(height: 24),

        // 2. Analyzed Input Card
        _buildAnalyzedInputCard(res),

        const SizedBox(height: 24),

        // 3. AI Explanation (SHAP) Section
        _buildShapExplanationSection(res),

        const SizedBox(height: 24),

        // 4. Recommended Action Section
        _buildRecommendedActionSection(res),

        const SizedBox(height: 28),

        // 5. Action Buttons (Report This Scam, Scan Another, Blockchain Proof)
        _buildFooterActions(res),
      ],
    );
  }

  Widget _buildAnalyzedInputCard(ScamDetectionResult res) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.terminal_rounded, size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    'Analyzed Target Content',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textSecondary),
                tooltip: 'Copy content',
                onPressed: () => _copyToClipboard(res.analyzedTextOrUrl, 'Analyzed content'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: SelectableText(
              res.analyzedTextOrUrl.isNotEmpty
                  ? res.analyzedTextOrUrl
                  : 'http://secure-login-chase-auth92.com/verify?account=8829',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapExplanationSection(ScamDetectionResult res) {
    // List of SHAP indicators from the model
    final indicators = res.indicators;

    final explanationText = res.explanation.isNotEmpty
        ? res.explanation
        : 'The submitted content contains several characteristics commonly associated with scam messages.';

    return SectionCard(
      title: 'AI Explanation (SHAP)',
      subtitle: 'Feature contribution weights determined by TreeSHAP interpretability model',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9FE),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Model: XGBoost + NLP-v4',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6D28D9),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Explanation Text Callout
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    explanationText,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Text(
                'Key Risk Indicators & SHAP Impact',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Feature Weight (Δ Risk)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Reusable AI indicator cards/bars
          ...indicators.map((ind) {
            return AiIndicatorBar(
              title: ind.title,
              shapValue: ind.shapValue != 0.0 ? ind.shapValue : 0.25,
              description: ind.description,
              severity: ind.severity,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecommendedActionSection(ScamDetectionResult res) {
    final primaryRecommendation = res.recommendations.isNotEmpty
        ? res.recommendations.first
        : 'Do not click the link or provide your personal information.';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Warm warning light amber
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFFB45309),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recommended Action',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Highlighted Action Text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.pan_tool_rounded,
                  color: AppColors.highRisk,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    primaryRecommendation,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF991B1B),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (res.recommendations.length > 1) ...[
            const SizedBox(height: 14),
            ...res.recommendations.skip(1).map((rec) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFFD97706),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rec,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF78350F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildFooterActions(ScamDetectionResult res) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 680;

          final reportButton = SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              icon: _isSubmittingReport
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
              label: Text(
                _isSubmittingReport ? 'Anchoring Report...' : 'Report This Scam',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.highRisk,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _isSubmittingReport ? null : () => _handleReportThisScam(res),
            ),
          );

          final scamDetailsButton = SecondaryButton(
            text: 'Scam Details',
            icon: Icons.visibility_outlined,
            onPressed: () {
              final scamProvider = context.read<ScamProvider>();
              final matches = scamProvider.allReports.where(
                (r) =>
                    r.id == res.id ||
                    r.targetOrSuspect == res.analyzedTextOrUrl ||
                    r.title.toLowerCase().contains('facebook') ||
                    r.scamType.toLowerCase() == res.predictedType.toLowerCase(),
              );
              final matched = matches.isNotEmpty
                  ? matches.first
                  : (scamProvider.allReports.isNotEmpty ? scamProvider.allReports.first : null);
              if (matched != null) {
                context.go(AppRoutes.scamDetailsPath(matched.id));
              }
            },
          );

          final String hashDisplay = res.txHash != null
              ? (res.txHash!.length > 18
                  ? '${res.txHash!.substring(0, 8)}...${res.txHash!.substring(res.txHash!.length - 6)}'
                  : res.txHash!)
              : '0x9a4f...391e';

          final blockchainProofInfo = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_moon_outlined, size: 16, color: Color(0xFF6D28D9)),
              const SizedBox(width: 6),
              Text(
                'Proof: $hashDisplay',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6D28D9),
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                reportButton,
                const SizedBox(height: 12),
                scamDetailsButton,
                const SizedBox(height: 14),
                Center(child: blockchainProofInfo),
              ],
            );
          }

          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 14,
            children: [
              blockchainProofInfo,
              Wrap(
                spacing: 14,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  scamDetailsButton,
                  reportButton,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
