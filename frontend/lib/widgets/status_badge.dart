import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/scam_report.dart';

class StatusBadge extends StatelessWidget {
  final ReportStatus status;
  final bool isBlockchainRecorded;

  const StatusBadge({
    super.key,
    required this.status,
    this.isBlockchainRecorded = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    switch (status) {
      case ReportStatus.verified:
        bg = AppColors.statusVerifiedBg;
        text = AppColors.statusVerifiedText;
        label = 'Verified';
        icon = Icons.check_circle_outline;
        break;
      case ReportStatus.pending:
        bg = AppColors.statusPendingBg;
        text = AppColors.statusPendingText;
        label = 'Pending';
        icon = Icons.hourglass_empty;
        break;
      case ReportStatus.investigating:
        bg = AppColors.statusFlaggedBg;
        text = AppColors.statusFlaggedText;
        label = 'Investigating';
        icon = Icons.warning_amber_rounded;
        break;
      case ReportStatus.resolved:
        bg = AppColors.statusVerifiedBg;
        text = AppColors.statusVerifiedText;
        label = 'Resolved';
        icon = Icons.done_all;
        break;
      case ReportStatus.rejected:
        bg = const Color(0xFFF1F5F9);
        text = AppColors.textSecondary;
        label = 'Dismissed';
        icon = Icons.close;
        break;
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: text),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (isBlockchainRecorded)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.statusBlockchainBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link, size: 11, color: AppColors.statusBlockchainText),
                const SizedBox(width: 2),
                const Text(
                  'Ledger',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusBlockchainText,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
