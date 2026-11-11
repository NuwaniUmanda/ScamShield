import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../providers/scam_provider.dart';
import '../../widgets/breadcrumb.dart';
import '../../widgets/risk_badge.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../models/scam_report.dart';

class SearchScamScreen extends StatefulWidget {
  final Function(ScamReport)? onReportSelected;

  const SearchScamScreen({
    super.key,
    this.onReportSelected,
  });

  @override
  State<SearchScamScreen> createState() => _SearchScamScreenState();
}

class _SearchScamScreenState extends State<SearchScamScreen> {
  late final TextEditingController _searchController;
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy • hh:mm a');

  final List<String> _categories = [
    'All Categories',
    'Phishing Link',
    'Phishing SMS',
    'Investment Scam',
    'Job Scam',
    'Delivery Phishing',
    'Tech Support',
    'Fake Account',
    'E-commerce',
  ];

  final List<String> _riskLevels = [
    'All Risk Levels',
    'Critical Risk',
    'High Risk',
    'Medium Risk',
    'Low Risk',
  ];

  @override
  void initState() {
    super.initState();
    final scamProvider = context.read<ScamProvider>();
    _searchController = TextEditingController(text: scamProvider.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    context.read<ScamProvider>().searchScams(query: _searchController.text);
  }

  void _navigateToDetails(ScamReport report) {
    if (widget.onReportSelected != null) {
      widget.onReportSelected!(report);
    } else {
      context.go(AppRoutes.scamDetailsPath(report.id));
    }
  }

  String _getRiskLevelDropdownValue(RiskLevel? risk) {
    switch (risk) {
      case RiskLevel.critical:
        return 'Critical Risk';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.low:
        return 'Low Risk';
      case null:
        return 'All Risk Levels';
    }
  }

  RiskLevel? _parseRiskLevelFromDropdown(String value) {
    switch (value) {
      case 'Critical Risk':
        return RiskLevel.critical;
      case 'High Risk':
        return RiskLevel.high;
      case 'Medium Risk':
        return RiskLevel.medium;
      case 'Low Risk':
        return RiskLevel.low;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scamProvider = context.watch<ScamProvider>();
    final results = scamProvider.searchResults;
    final isLoading = scamProvider.isLoadingSearch;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Breadcrumbs and Page Heading
              _buildPageHeader(),

              const SizedBox(height: 20),

              // 2. Search Box and Filters Section (Matching Figma)
              _buildSearchAndFiltersCard(scamProvider),

              const SizedBox(height: 24),

              // 3. Search Results Header Bar
              _buildResultsSummaryBar(results.length, isLoading, scamProvider),

              const SizedBox(height: 16),

              // 4. Results List / Empty State / Loading State
              if (isLoading)
                _buildLoadingState()
              else if (results.isEmpty)
                _buildEmptyState(scamProvider)
              else
                _buildResultsList(results),
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
            const BreadcrumbItem(label: 'Search Scam'),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Search Scam',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Search verified threats, suspect domain names, phishing links, and blockchain-recorded scam incidents.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFiltersCard(ScamProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          // Search Input Field with Search Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Enter a URL, account name or keyword...',
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              provider.searchScams(query: '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    // Realtime search update
                    provider.searchScams(query: val);
                  },
                  onSubmitted: (_) => _handleSearch(),
                ),
              ),
              const SizedBox(width: 12),
              PrimaryButton(
                text: 'Search',
                icon: Icons.search_rounded,
                onPressed: _handleSearch,
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),

          // Filters Section (All Categories, All Risk Levels, Reset)
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Category Filter Dropdown
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Category:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _categories.contains(provider.selectedCategory)
                            ? provider.selectedCategory
                            : 'All Categories',
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (newCat) {
                          if (newCat != null) {
                            provider.setCategoryFilter(newCat);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // Risk Level Filter Dropdown
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Risk Level:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _getRiskLevelDropdownValue(provider.selectedRiskFilter),
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        items: _riskLevels.map((risk) {
                          return DropdownMenuItem(
                            value: risk,
                            child: Text(risk),
                          );
                        }).toList(),
                        onChanged: (newRisk) {
                          if (newRisk != null) {
                            final parsed = _parseRiskLevelFromDropdown(newRisk);
                            provider.setRiskFilter(parsed);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // Reset Filter Button if any filter is active
              if (provider.searchQuery.isNotEmpty ||
                  provider.selectedCategory != 'All Categories' ||
                  provider.selectedRiskFilter != null)
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    provider.clearFilters();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 15, color: AppColors.primary),
                  label: const Text(
                    'Reset Filters',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSummaryBar(int count, bool isLoading, ScamProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'Matched Scam Records',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        if (provider.searchQuery.isNotEmpty)
          Flexible(
            child: Text(
              'Filtering by: "${provider.searchQuery}"',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Searching verified threat database & blockchain records...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ScamProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 54, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No scams found matching your query',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try checking for spelling errors, using different keywords, or resetting active filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SecondaryButton(
            text: 'Clear All Filters',
            icon: Icons.refresh_rounded,
            onPressed: () {
              _searchController.clear();
              provider.clearFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<ScamReport> reports) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final report = reports[index];
        return _buildScamResultCard(report);
      },
    );
  }

  Widget _buildScamResultCard(ScamReport report) {
    final formattedDate = _dateFormat.format(report.reportedAt);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 650;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: Details, Badges, Title, Report count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Title / URL & Category
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              report.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Category Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              report.scamType,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      if (report.targetOrSuspect.isNotEmpty && report.targetOrSuspect != report.title) ...[
                        Text(
                          report.targetOrSuspect,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Middle Badges: High Risk, Report count, Blockchain Verified, Date
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Risk Level Badge (e.g. High Risk)
                          RiskBadge(level: report.riskLevel),

                          // Report Count Badge (e.g. 27 Reports)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_alt_outlined, size: 13, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  '${report.reportCount} Reports',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Blockchain Verified Badge
                          if (report.isBlockchainVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFDDD6FE)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_user_rounded, size: 13, color: Color(0xFF6D28D9)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Blockchain Verified',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6D28D9),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Date
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Right Column: Risk Score & View Details Button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Risk Score Display (e.g. Risk Score: 94%)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: report.riskLevel == RiskLevel.critical || report.riskLevel == RiskLevel.high
                            ? AppColors.riskHighBg
                            : AppColors.riskMediumBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: report.riskLevel == RiskLevel.critical || report.riskLevel == RiskLevel.high
                              ? AppColors.riskHighBorder
                              : AppColors.riskMediumBorder,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Risk Score:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${report.riskScore.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: report.riskLevel == RiskLevel.critical || report.riskLevel == RiskLevel.high
                                  ? AppColors.highRisk
                                  : AppColors.mediumRisk,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // View Details Button
                    ElevatedButton.icon(
                      onPressed: () => _navigateToDetails(report),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primarySoft,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          // Mobile / Narrow Layout
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      report.scamType,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  RiskBadge(level: report.riskLevel),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${report.reportCount} Reports',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                  ),
                  if (report.isBlockchainVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Blockchain Verified',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6D28D9)),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Risk Score: ',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${report.riskScore.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: report.riskLevel == RiskLevel.critical || report.riskLevel == RiskLevel.high
                              ? AppColors.highRisk
                              : AppColors.mediumRisk,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _navigateToDetails(report),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySoft,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
