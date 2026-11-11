import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/blockchain_verification.dart';
import '../models/scam_report.dart';

class BlockchainVerificationCard extends StatelessWidget {
  final BlockchainVerification? verification;
  final ScamReport? report;
  final bool isLoading;

  const BlockchainVerificationCard({
    super.key,
    this.verification,
    this.report,
    this.isLoading = false,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
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
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF6D28D9)),
              SizedBox(height: 14),
              Text(
                'Retrieving immutable block verification...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final v = verification;
    final r = report;

    // Resolve display values
    final reportHash = v?.dataHash.isNotEmpty == true
        ? v!.dataHash
        : 'sha256:4a38f7c9e11059f33cb02a2ec9104fa28e';

    final txHash = (r?.txHash != null && r!.txHash!.isNotEmpty)
        ? r.txHash!
        : (v?.txHash ?? '0x9a4f7831cd09b2e56417a8c56e34419bbcf391e0892');

    final blockNumber = v != null ? '#${v.blockIndex}' : '#48291';
    final timestamp = v != null ? dateFormat.format(v.timestamp) : dateFormat.format(DateTime.now());
    final firstReported = v?.firstReported != null
        ? dateFormat.format(v!.firstReported!)
        : (r != null ? dateFormat.format(r.reportedAt.subtract(const Duration(hours: 12))) : '2026-09-05 14:20:00');
    final lastReported = v?.lastReported != null
        ? dateFormat.format(v!.lastReported!)
        : (r != null ? dateFormat.format(r.reportedAt) : '2026-09-06 09:42:10');
    final reportedBy = v?.reportedBy ?? (r?.reporterEmail ?? 'Community Security Network (Node #8829)');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with Title & Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFBFBFE),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight, width: 1),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_moon_rounded,
                      color: Color(0xFF6D28D9),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Blockchain Verification',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                // Status Indicator: "Blockchain Verified"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF6D28D9),
                        size: 13,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Blockchain Verified',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6D28D9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card Body: Fields Table / Key-Value Grid
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVerificationField(
                  context,
                  label: 'Report Hash (SHA-256)',
                  value: reportHash,
                  isMonospace: true,
                  canCopy: true,
                  icon: Icons.fingerprint_rounded,
                ),
                const Divider(height: 20, color: AppColors.borderLight),
                _buildVerificationField(
                  context,
                  label: 'Transaction Hash',
                  value: txHash,
                  isMonospace: true,
                  canCopy: true,
                  icon: Icons.receipt_long_rounded,
                ),
                const Divider(height: 20, color: AppColors.borderLight),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 420;

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVerificationField(
                            context,
                            label: 'Block Number',
                            value: blockNumber,
                            isMonospace: true,
                            icon: Icons.layers_outlined,
                          ),
                          const Divider(height: 16, color: AppColors.borderLight),
                          _buildVerificationField(
                            context,
                            label: 'Timestamp',
                            value: timestamp,
                            icon: Icons.schedule_rounded,
                          ),
                          const Divider(height: 16, color: AppColors.borderLight),
                          _buildVerificationField(
                            context,
                            label: 'First Reported',
                            value: firstReported,
                            icon: Icons.event_available_rounded,
                          ),
                          const Divider(height: 16, color: AppColors.borderLight),
                          _buildVerificationField(
                            context,
                            label: 'Last Reported',
                            value: lastReported,
                            icon: Icons.update_rounded,
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildVerificationField(
                                context,
                                label: 'Block Number',
                                value: blockNumber,
                                isMonospace: true,
                                icon: Icons.layers_outlined,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildVerificationField(
                                context,
                                label: 'Timestamp',
                                value: timestamp,
                                icon: Icons.schedule_rounded,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, color: AppColors.borderLight),
                        Row(
                          children: [
                            Expanded(
                              child: _buildVerificationField(
                                context,
                                label: 'First Reported',
                                value: firstReported,
                                icon: Icons.event_available_rounded,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildVerificationField(
                                context,
                                label: 'Last Reported',
                                value: lastReported,
                                icon: Icons.update_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const Divider(height: 20, color: AppColors.borderLight),
                _buildVerificationField(
                  context,
                  label: 'Reported By',
                  value: reportedBy,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 16),

                // Disclaimer / Mock Simulation Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Simulated Ledger Sandbox: All blockchain parameters are mock cryptographic proofs verified for demonstration on ScamShield Ledger Node #12.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationField(
    BuildContext context, {
    required String label,
    required String value,
    bool isMonospace = false,
    bool canCopy = false,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SelectableText(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: isMonospace ? 'monospace' : null,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (canCopy) ...[
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 15, color: AppColors.textSecondary),
                tooltip: 'Copy $label',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _copyToClipboard(context, value, label),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
