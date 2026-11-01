import 'package:flutter/material.dart';
import '../models/scam_report.dart';
import '../services/scam_service.dart';
import '../data/mock_data.dart';

class ScamProvider extends ChangeNotifier {
  final ScamService _scamService;

  List<ScamReport> _allReports = List.from(MockData.mockReports);
  List<ScamReport> _searchResults = List.from(MockData.mockReports);
  List<ScamReport> _myReports = List.from(MockData.mockMyReports);

  bool _isLoadingReports = false;
  bool _isLoadingSearch = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedCategory = 'All Categories';
  RiskLevel? _selectedRiskFilter;
  ReportStatus? _selectedStatusFilter;

  ScamProvider({ScamService? scamService})
      : _scamService = scamService ?? MockScamService() {
    loadReports();
  }

  // Getters
  List<ScamReport> get allReports => _allReports;
  List<ScamReport> get recentReports => _allReports.take(6).toList();
  List<ScamReport> get searchResults => _searchResults;
  List<ScamReport> get myReports => _myReports;

  bool get isLoadingReports => _isLoadingReports;
  bool get isLoadingSearch => _isLoadingSearch;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  RiskLevel? get selectedRiskFilter => _selectedRiskFilter;
  ReportStatus? get selectedStatusFilter => _selectedStatusFilter;

  Future<void> loadReports() async {
    _isLoadingReports = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allReports = await _scamService.getAllReports();
      _searchResults = List.from(_allReports);
      _myReports = await _scamService.getMyReports('officer@scamshield.io');
    } catch (e) {
      _errorMessage = 'Unable to load scam reports. Please try again.';
    } finally {
      _isLoadingReports = false;
      notifyListeners();
    }
  }

  Future<void> searchScams({
    String? query,
    String? category,
    RiskLevel? risk,
    ReportStatus? status,
  }) async {
    if (query != null) _searchQuery = query;
    if (category != null) _selectedCategory = category;
    if (risk != null) _selectedRiskFilter = risk;
    if (status != null) _selectedStatusFilter = status;

    _isLoadingSearch = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _scamService.getAllReports(
        query: _searchQuery,
        category: _selectedCategory == 'All Categories' ? null : _selectedCategory,
        riskFilter: _selectedRiskFilter,
        statusFilter: _selectedStatusFilter,
      );
    } catch (e) {
      _errorMessage = 'Error searching scam records. Please try again.';
    } finally {
      _isLoadingSearch = false;
      notifyListeners();
    }
  }

  void setRiskFilter(RiskLevel? risk) {
    _selectedRiskFilter = risk;
    searchScams();
  }

  void setCategoryFilter(String category) {
    _selectedCategory = category;
    searchScams();
  }

  void setStatusFilter(ReportStatus? status) {
    _selectedStatusFilter = status;
    searchScams();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All Categories';
    _selectedRiskFilter = null;
    _selectedStatusFilter = null;
    searchScams();
  }

  Future<ScamReport?> getReportById(String id) async {
    // First check memory cache
    try {
      final cached = _allReports.firstWhere((r) => r.id.toLowerCase() == id.toLowerCase());
      return cached;
    } catch (_) {
      return await _scamService.getReportById(id);
    }
  }

  Future<ScamReport> submitReport({
    required String title,
    required String scamType,
    required String targetOrSuspect,
    required String description,
    required RiskLevel riskLevel,
    double riskScore = 88.0,
    List<String> evidenceFiles = const [],
    String? email,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final report = await _scamService.submitReport(
        title: title,
        scamType: scamType,
        targetOrSuspect: targetOrSuspect,
        description: description,
        riskLevel: riskLevel,
        riskScore: riskScore,
        evidenceFiles: evidenceFiles,
        email: email ?? 'officer@scamshield.io',
      );

      _allReports.insert(0, report);
      _myReports.insert(0, report);
      _searchResults.insert(0, report);

      return report;
    } catch (e) {
      _errorMessage = 'Failed to submit scam report to the ledger.';
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
