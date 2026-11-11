import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../providers/scam_provider.dart';
import '../../widgets/section_card.dart';
import '../../widgets/scam_data_table.dart';
import '../../widgets/breadcrumb.dart';
import '../../models/scam_report.dart';

class MyReportsScreen extends StatefulWidget {
  final Function(ScamReport)? onReportSelected;

  const MyReportsScreen({
    super.key,
    this.onReportSelected,
  });

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  ReportStatus? _selectedStatus;

  void _onDetails(ScamReport report) {
    if (widget.onReportSelected != null) {
      widget.onReportSelected!(report);
    } else {
      context.go(AppRoutes.scamDetailsPath(report.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scamProvider = context.watch<ScamProvider>();
    var reports = scamProvider.myReports;

    if (_selectedStatus != null) {
      reports = reports.where((r) => r.status == _selectedStatus).toList();
    }

    return RefreshIndicator(
      onRefresh: () => scamProvider.loadReports(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Breadcrumb and Header
                Breadcrumb(
                  items: [
                    BreadcrumbItem(
                      label: 'Home',
                      onTap: () => context.go(AppRoutes.dashboard),
                    ),
                    const BreadcrumbItem(label: 'My Reports'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Reports',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'View and monitor the verification status of your submitted scam reports.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.go(AppRoutes.reportScam),
                      icon: const Icon(Icons.add_moderator_rounded, size: 16),
                      label: const Text('Submit New Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. Filter Bar Card
                SectionCard(
                  title: 'Filter Submissions',
                  subtitle: 'Filter your reports by verification & investigation status',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Status:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      _buildStatusChip(null, 'All Submissions (${scamProvider.myReports.length})'),
                      _buildStatusChip(ReportStatus.verified, 'Verified'),
                      _buildStatusChip(ReportStatus.investigating, 'Investigating'),
                      _buildStatusChip(ReportStatus.pending, 'Pending Review'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Reports Data Table Card
                SectionCard(
                  title: 'Submitted Reports',
                  subtitle: 'Showing ${reports.length} records submitted from your account',
                  padding: EdgeInsets.zero,
                  child: reports.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.folder_open_outlined, size: 54, color: AppColors.textMuted),
                                const SizedBox(height: 14),
                                const Text(
                                  'No reports found in your submission history',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'When you submit suspicious scams, they will be tracked and anchored here.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => context.go(AppRoutes.reportScam),
                                  icon: const Icon(Icons.add_moderator_rounded, size: 16),
                                  label: const Text('Report a Scam Incident'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ScamDataTable(
                          reports: reports,
                          onReportSelected: _onDetails,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ReportStatus? status, String label) {
    final isSelected = _selectedStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedStatus = status);
      },
      selectedColor: AppColors.primarySoft,
      backgroundColor: AppColors.card,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}
