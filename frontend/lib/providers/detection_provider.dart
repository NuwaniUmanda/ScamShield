import 'package:flutter/material.dart';
import '../models/detection_result.dart';
import '../services/detection_service.dart';

class DetectionProvider extends ChangeNotifier {
  final DetectionService _detectionService;

  ScamDetectionResult? _lastResult;
  bool _isScanning = false;
  String? _errorMessage;
  String _currentInput = 'http://secure-login-chase-auth92.com/verify?account=8829';

  // Staging data for reports being submitted via the wizard
  Map<String, dynamic>? _stagedReportData;

  DetectionProvider({DetectionService? detectionService})
      : _detectionService = detectionService ?? MockDetectionService() {
    // Run initial scan so AI Result screen has realistic data ready
    scanInput(_currentInput);
  }

  ScamDetectionResult get defaultResult => _detectionService.getDefaultResult();
  ScamDetectionResult? get lastResult => _lastResult ?? defaultResult;
  bool get isScanning => _isScanning;
  String? get errorMessage => _errorMessage;
  String get currentInput => _currentInput;
  Map<String, dynamic>? get stagedReportData => _stagedReportData;

  void stageReportForAnalysis(Map<String, dynamic> data) {
    _stagedReportData = data;
    _currentInput = (data['target_or_suspect'] as String? ?? '').isNotEmpty
        ? data['target_or_suspect'] as String
        : (data['description'] as String? ?? '');
    notifyListeners();
  }

  void clearStagedReport() {
    _stagedReportData = null;
    notifyListeners();
  }

  Future<ScamDetectionResult?> scanInput(String input) async {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) return null;

    _currentInput = cleanInput;
    _isScanning = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _detectionService.scanTextOrUrl(cleanInput);
      _lastResult = result;
      return result;
    } catch (e) {
      _errorMessage = 'Unable to analyze the submitted content. Please check the input format.';
      return null;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }
}
