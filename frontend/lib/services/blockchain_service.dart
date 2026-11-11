import '../models/blockchain_verification.dart';

abstract class BlockchainService {
  Future<BlockchainVerification> verifyReportOnChain(String reportId);
  Future<String> recordIncidentOnLedger({
    required String reportId,
    required String dataPayload,
  });
  Future<int> getLatestBlockHeight();
}

class MockBlockchainService implements BlockchainService {
  int _currentBlockHeight = 48292;

  @override
  Future<BlockchainVerification> verifyReportOnChain(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final now = DateTime.now();
    return BlockchainVerification(
      txHash: '0x9a4f7831cd09b2e56417a8c56e34419bbcf391e0892',
      blockIndex: _currentBlockHeight,
      timestamp: now.subtract(const Duration(minutes: 5)),
      reportId: reportId,
      dataHash: 'sha256:4a38f7c9e11059f33cb02a2ec9104fa28e',
      previousHash: '0x7e29b4009a82cd1554ef028e19c3b8813a',
      status: 'Blockchain Verified',
      network: 'ScamShield Security Ledger (Node #12)',
      confirmations: 24,
      firstReported: now.subtract(const Duration(days: 2, hours: 4)),
      lastReported: now.subtract(const Duration(minutes: 25)),
      reportedBy: 'Community Security Network (Node #8829)',
    );
  }

  @override
  Future<String> recordIncidentOnLedger({
    required String reportId,
    required String dataPayload,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentBlockHeight += 1;
    final hash = '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}${reportId.hashCode.abs().toRadixString(16)}';
    return hash.length > 20 ? hash.substring(0, 20) : hash;
  }

  @override
  Future<int> getLatestBlockHeight() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _currentBlockHeight;
  }
}
