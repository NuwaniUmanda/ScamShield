import 'package:flutter/material.dart';
import '../models/blockchain_verification.dart';
import '../services/blockchain_service.dart';

class BlockchainProvider extends ChangeNotifier {
  final BlockchainService _blockchainService;

  final Map<String, BlockchainVerification> _verificationCache = {};
  bool _isLoading = false;
  String? _errorMessage;
  int _currentBlockHeight = 48292;

  BlockchainProvider({BlockchainService? blockchainService})
      : _blockchainService = blockchainService ?? MockBlockchainService();

  BlockchainService get service => _blockchainService;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentBlockHeight => _currentBlockHeight;

  BlockchainVerification? getCachedVerification(String reportId) => _verificationCache[reportId];

  Future<BlockchainVerification?> verifyReport(String reportId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final verification = await _blockchainService.verifyReportOnChain(reportId);
      _verificationCache[reportId] = verification;
      _currentBlockHeight = verification.blockIndex;
      return verification;
    } catch (e) {
      _errorMessage = 'Failed to verify cryptographic proof on blockchain ledger.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> recordIncident({
    required String reportId,
    required String dataPayload,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final txHash = await _blockchainService.recordIncidentOnLedger(
        reportId: reportId,
        dataPayload: dataPayload,
      );
      return txHash;
    } catch (e) {
      _errorMessage = 'Failed to record incident onto blockchain ledger.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
