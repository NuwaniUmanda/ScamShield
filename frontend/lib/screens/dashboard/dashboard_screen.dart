import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../providers/scam_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/section_card.dart';
import '../../widgets/scam_data_table.dart';
import '../../models/scam_report.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
    final scamProvider = context.watch<ScamProvider>();
    final statsProvider = context.watch<StatsProvider>();

    if (scamProvider.isLoadingReports && scamProvider.allReports.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: () async {
        await scamProvider.loadReports();
        if (context.mounted) {
          await context.read<StatsProvider>().updateStatistics(scamProvider.allReports);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome & Security Banner matching Figma
            Container(
              padding: const EdgeInsets.all(22),
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 18),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi.! AI + Blockchain Security',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Stay Safe Online',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.reportScam),
                    icon: const Icon(Icons.add_moderator_rounded, size: 18),
                    label: const Text('Report Incident'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Main Stat Cards Grid (Total Reports, Phishing Links, Fake Accounts, Scam Messages, Verified Reports)
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 1050
                    ? 5
                    : (constraints.maxWidth >= 700
                        ? 3
                        : (constraints.maxWidth >= 480 ? 2 : 1));

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
                      value: totalReports.toString(),
                      changePercentage: '+14.8%',
                      subtitle: 'vs last month',
                      isPositive: true,
                      icon: Icons.analytics_outlined,
                      iconColor: AppColors.primary,
                      iconBgColor: AppColors.primarySoft,
                    ),
                    StatCard(
                      title: 'Phishing Links',
                      value: phishingLinks.toString(),
                      changePercentage: '+9.2%',
                      subtitle: 'URLs analyzed',
                      isPositive: false,
                      icon: Icons.link_off_rounded,
                      iconColor: AppColors.highRisk,
                      iconBgColor: AppColors.riskHighBg,
                    ),
                    StatCard(
                      title: 'Fake Accounts',
                      value: fakeAccounts.toString(),
                      changePercentage: '-3.1%',
                      subtitle: 'Suspect profiles',
                      isPositive: true,
                      icon: Icons.no_accounts_outlined,
                      iconColor: AppColors.chartOrange,
                      iconBgColor: const Color(0xFFFFF7ED),
                    ),
                    StatCard(
                      title: 'Scam Messages',
                      value: scamMessages.toString(),
                      changePercentage: '+12.4%',
                      subtitle: 'SMS & emails',
                      isPositive: false,
                      icon: Icons.mark_email_unread_outlined,
                      iconColor: AppColors.chartPurple,
                      iconBgColor: const Color(0xFFFAF5FF),
                    ),
                    StatCard(
                      title: 'Verified Reports',
                      value: verifiedReports.toString(),
                      changePercentage: '+22.5%',
                      subtitle: 'Ledger anchored',
                      isPositive: true,
                      icon: Icons.verified_user_outlined,
                      iconColor: AppColors.statusBlockchainText,
                      iconBgColor: AppColors.statusBlockchainBg,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Scam Statistics Section
            SectionCard(
              title: 'Scam Statistics',
              subtitle: 'AI detection rate & threat category volume across 12,000+ incidents',
              trailing: TextButton.icon(
                onPressed: () => context.go(AppRoutes.statistics),
                icon: const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                label: const Text(
                  'View Threat Analytics',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 750;

                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category progress bars
                      Expanded(
                        flex: isWide ? 6 : 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (stats?.typeDistributions ?? []).take(4).map((dist) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        dist.typeName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${dist.count} (${dist.percentage}%)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: dist.percentage / 100.0,
                                      minHeight: 6,
                                      backgroundColor: AppColors.surfaceMuted,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        dist.percentage > 30 ? AppColors.primary : AppColors.chartOrange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      if (isWide) const SizedBox(width: 24) else const SizedBox(height: 20),

                      // AI Model Performance Badge
                      Expanded(
                        flex: isWide ? 4 : 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'AI Model Accuracy',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                '98.6%',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Multi-vector NLP Transformer + Smart Contract verification accuracy on test sets.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Recent Reports Section
            SectionCard(
              title: 'Recent Reports',
              subtitle: 'Latest scam incidents verified by ScamShield and anchored on ledger',
              trailing: TextButton.icon(
                onPressed: () => context.go(AppRoutes.searchScam),
                icon: const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                label: const Text(
                  'View All Reports',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              padding: EdgeInsets.zero,
              child: ScamDataTable(
                reports: scamProvider.recentReports,
                onReportSelected: _navigateToDetails,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
