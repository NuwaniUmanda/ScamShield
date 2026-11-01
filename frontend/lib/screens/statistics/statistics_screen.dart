import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../providers/scam_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/section_card.dart';
import '../../widgets/risk_badge.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/breadcrumb.dart';
import '../../widgets/charts/reports_by_category_chart.dart';
import '../../widgets/charts/reports_over_time_chart.dart';
import '../../models/scam_report.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final NumberFormat _numFormat = NumberFormat('#,###');
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy • hh:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scamProvider = context.read<ScamProvider>();
      context.read<StatsProvider>().updateStatistics(scamProvider.allReports);
    });
  }

  void _navigateToDetails(ScamReport report) {
    context.go(AppRoutes.scamDetailsPath(report.id));
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = context.watch<StatsProvider>();
    final scamProvider = context.watch<ScamProvider>();

    if (statsProvider.isLoading && statsProvider.statistics == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final stats = statsProvider.statistics;
    final totalReports = stats?.totalReports ?? (scamProvider.allReports.length + 12474);
    final phishingLinks = stats?.phishingLinks ?? 4320;
    final fakeAccounts = stats?.fakeAccounts ?? 2840;
    final scamMessages = stats?.scamMessages ?? 3450;
    final verifiedReports = stats?.verifiedReports ?? 8540;

    final totalChange = stats?.totalReportsChange ?? 12.5;
    final phishingChange = stats?.phishingLinksChange ?? 18.7;
    final fakeAccountsChange = stats?.fakeAccountsChange ?? 8.2;
    final scamMessagesChange = stats?.scamMessagesChange ?? -4.3;
    final verifiedChange = stats?.verifiedReportsChange ?? 15.6;

    final recentReports = scamProvider.allReports.take(6).toList();

    return RefreshIndicator(
      onRefresh: () async {
        final statsProvider = context.read<StatsProvider>();
        await scamProvider.loadReports();
        await statsProvider.updateStatistics(scamProvider.allReports);
      },
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
                _buildPageHeader(),

                const SizedBox(height: 20),

                // 2. 5 Statistic Cards Grid (Total, Phishing, Fake Accounts, Scam Messages, Verified)
                _buildStatisticCardsGrid(
                  totalReports: totalReports,
                  phishingLinks: phishingLinks,
                  fakeAccounts: fakeAccounts,
                  scamMessages: scamMessages,
                  verifiedReports: verifiedReports,
                  totalChange: totalChange,
                  phishingChange: phishingChange,
                  fakeAccountsChange: fakeAccountsChange,
                  scamMessagesChange: scamMessagesChange,
                  verifiedChange: verifiedChange,
                ),

                const SizedBox(height: 24),

                // 3. Two Charts Row: Reports by Category (Donut) & Reports Over Time (Line Chart)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reports by Category (Donut/Pie Chart)
                          Expanded(
                            flex: 5,
                            child: SectionCard(
                              title: 'Reports by Category',
                              subtitle: 'Distribution of verified scam types across threat database',
                              child: ReportsByCategoryChart(
                                distributions: stats?.typeDistributions ?? [],
                                totalCount: totalReports,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Reports Over Time (Line Chart)
                          Expanded(
                            flex: 6,
                            child: SectionCard(
                              title: 'Reports Over Time',
                              subtitle: 'Monthly reported vs neutralized threats (H1 2026)',
                              child: ReportsOverTimeChart(
                                trends: stats?.monthlyTrends ?? [],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // Mobile / Tablet Column Layout
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionCard(
                          title: 'Reports by Category',
                          subtitle: 'Distribution of verified scam types across threat database',
                          child: ReportsByCategoryChart(
                            distributions: stats?.typeDistributions ?? [],
                            totalCount: totalReports,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SectionCard(
                          title: 'Reports Over Time',
                          subtitle: 'Monthly reported vs neutralized threats (H1 2026)',
                          child: ReportsOverTimeChart(
                            trends: stats?.monthlyTrends ?? [],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 4. Recent Reports Table Section
                SectionCard(
                  title: 'Recent Reports & Threat Intelligence',
                  subtitle: 'Latest scam incidents verified and permanently registered on ledger',
                  padding: EdgeInsets.zero,
                  trailing: TextButton.icon(
                    onPressed: () => context.go(AppRoutes.searchScam),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('View All Scams'),
                  ),
                  child: _buildRecentReportsTable(recentReports),
                ),
              ],
            ),
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
            const BreadcrumbItem(label: 'Statistics'),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Analytics & Threat Intelligence',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Real-time scam statistics, category distributions, monthly resolution velocity, and blockchain verification analytics.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticCardsGrid({
    required int totalReports,
    required int phishingLinks,
    required int fakeAccounts,
    required int scamMessages,
    required int verifiedReports,
    required double totalChange,
    required double phishingChange,
    required double fakeAccountsChange,
    required double scamMessagesChange,
    required double verifiedChange,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1050
            ? 5
            : (constraints.maxWidth >= 700 ? 3 : (constraints.maxWidth >= 480 ? 2 : 1));

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: crossAxisCount >= 5 ? 1.35 : (crossAxisCount >= 3 ? 1.55 : 1.75),
          children: [
            StatCard(
              title: 'Total Reports',
              value: _numFormat.format(totalReports),
              changePercentage: '${totalChange >= 0 ? "+" : ""}${totalChange.toStringAsFixed(1)}%',
              isPositive: totalChange >= 0,
              subtitle: 'vs last month',
              icon: Icons.assignment_outlined,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primarySoft,
            ),
            StatCard(
              title: 'Phishing Links',
              value: _numFormat.format(phishingLinks),
              changePercentage: '${phishingChange >= 0 ? "+" : ""}${phishingChange.toStringAsFixed(1)}%',
              isPositive: phishingChange >= 0,
              subtitle: 'vs last month',
              icon: Icons.link_off_rounded,
              iconColor: const Color(0xFFEA580C),
              iconBgColor: const Color(0xFFFFF7ED),
            ),
            StatCard(
              title: 'Fake Accounts',
              value: _numFormat.format(fakeAccounts),
              changePercentage: '${fakeAccountsChange >= 0 ? "+" : ""}${fakeAccountsChange.toStringAsFixed(1)}%',
              isPositive: fakeAccountsChange >= 0,
              subtitle: 'vs last month',
              icon: Icons.no_accounts_outlined,
              iconColor: const Color(0xFF6366F1),
              iconBgColor: const Color(0xFFEEF2FF),
            ),
            StatCard(
              title: 'Scam Messages',
              value: _numFormat.format(scamMessages),
              changePercentage: '${scamMessagesChange >= 0 ? "+" : ""}${scamMessagesChange.toStringAsFixed(1)}%',
              isPositive: scamMessagesChange >= 0,
              subtitle: 'vs last month',
              icon: Icons.mark_chat_unread_outlined,
              iconColor: const Color(0xFFF59E0B),
              iconBgColor: const Color(0xFFFEF3C7),
            ),
            StatCard(
              title: 'Verified Reports',
              value: _numFormat.format(verifiedReports),
              changePercentage: '${verifiedChange >= 0 ? "+" : ""}${verifiedChange.toStringAsFixed(1)}%',
              isPositive: verifiedChange >= 0,
              subtitle: 'vs last month',
              icon: Icons.verified_user_rounded,
              iconColor: AppColors.success,
              iconBgColor: AppColors.statusVerifiedBg,
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentReportsTable(List<ScamReport> reports) {
    if (reports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No recent threat reports available.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 850),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
          headingTextStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
          dataRowMinHeight: 56,
          dataRowMaxHeight: 64,
          horizontalMargin: 20,
          columnSpacing: 16,
          dividerThickness: 1,
          columns: const [
            DataColumn(label: SizedBox(width: 100, child: Text('ID'))),
            DataColumn(label: SizedBox(width: 220, child: Text('TARGET / TITLE'))),
            DataColumn(label: SizedBox(width: 140, child: Text('CATEGORY'))),
            DataColumn(label: SizedBox(width: 120, child: Text('RISK LEVEL'))),
            DataColumn(label: SizedBox(width: 130, child: Text('STATUS'))),
            DataColumn(label: SizedBox(width: 140, child: Text('DATE'))),
            DataColumn(label: SizedBox(width: 90, child: Text('ACTION'))),
          ],
          rows: reports.map((report) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    report.id,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: AppColors.primary,
                    ),
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        report.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (report.targetOrSuspect.isNotEmpty && report.targetOrSuspect != report.title)
                        Text(
                          report.targetOrSuspect,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Text(
                      report.scamType,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  RiskBadge(level: report.riskLevel, useFullLabel: true),
                ),
                DataCell(
                  StatusBadge(
                    status: report.status,
                    isBlockchainRecorded: report.isBlockchainVerified,
                  ),
                ),
                DataCell(
                  Text(
                    _dateFormat.format(report.reportedAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                    tooltip: 'View Details',
                    onPressed: () => _navigateToDetails(report),
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
