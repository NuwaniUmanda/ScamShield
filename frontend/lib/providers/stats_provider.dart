import 'package:flutter/material.dart';
import '../models/statistics.dart';
import '../models/scam_report.dart';
import '../services/statistics_service.dart';

class StatsProvider extends ChangeNotifier {
  final StatisticsService _statisticsService;
  DashboardStatistics? _statistics;
  bool _isLoading = false;
  String? _errorMessage;

  StatsProvider({StatisticsService? statisticsService})
      : _statisticsService = statisticsService ?? MockStatisticsService();

  DashboardStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> updateStatistics(List<ScamReport> currentReports) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _statistics = await _statisticsService.getStatistics(currentReports);
    } catch (e) {
      _errorMessage = 'Unable to compute platform statistics.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
