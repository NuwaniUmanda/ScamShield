import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/scam_report.dart';
import 'risk_badge.dart';
import 'status_badge.dart';

class ScamDataTable extends StatelessWidget {
  final List<ScamReport> reports;
  final Function(ScamReport)? onReportSelected;

  const ScamDataTable({
    super.key,
    required this.reports,
    this.onReportSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'No scam reports found',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    String formatTimeAgo(DateTime dt) {
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 920),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
          headingTextStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
          dataRowMinHeight: 58,
          dataRowMaxHeight: 68,
          horizontalMargin: 20,
          columnSpacing: 20,
          dividerThickness: 1,
          columns: const [
            DataColumn(
              label: SizedBox(
                width: 240,
                child: Text('REPORT'),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 140,
                child: Text('CATEGORY'),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 130,
                child: Text('RISK'),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 140,
                child: Text('STATUS'),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 110,
                child: Text('TIME'),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 130,
                child: Text('ACTION'),
              ),
            ),
          ],
          rows: reports.map((report) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 240,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          report.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              report.id,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (report.targetOrSuspect.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  report.targetOrSuspect,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 140,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Text(
                          report.scamType,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 130,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: RiskBadge(
                        level: report.riskLevel,
                        score: report.riskScore,
                        showScore: true,
                        useFullLabel: true,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 140,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: StatusBadge(
                        status: report.status,
                        isBlockchainRecorded: report.isBlockchainVerified,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 110,
                    child: Text(
                      formatTimeAgo(report.reportedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 130,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: onReportSelected != null ? () => onReportSelected!(report) : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 13),
                        label: const Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

typedef ScamTable = ScamDataTable;
