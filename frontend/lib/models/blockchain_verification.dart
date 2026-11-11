class BlockchainVerification {
  final String txHash;
  final int blockIndex;
  final DateTime timestamp;
  final String reportId;
  final String dataHash; // Report Hash (SHA-256)
  final String previousHash;
  final String status; // 'Verified', 'Blockchain Verified'
  final String network;
  final int confirmations;
  final DateTime? firstReported;
  final DateTime? lastReported;
  final String? reportedBy;

  const BlockchainVerification({
    required this.txHash,
    required this.blockIndex,
    required this.timestamp,
    required this.reportId,
    required this.dataHash,
    required this.previousHash,
    this.status = 'Blockchain Verified',
    this.network = 'ScamShield Security Ledger (Node #12)',
    this.confirmations = 24,
    this.firstReported,
    this.lastReported,
    this.reportedBy,
  });

  factory BlockchainVerification.fromJson(Map<String, dynamic> json) {
    return BlockchainVerification(
      txHash: json['tx_hash'] as String? ?? '',
      blockIndex: json['block_index'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      reportId: json['report_id'] as String? ?? '',
      dataHash: json['data_hash'] as String? ?? '',
      previousHash: json['previous_hash'] as String? ?? '',
      status: json['status'] as String? ?? 'Blockchain Verified',
      network: json['network'] as String? ?? 'ScamShield Security Ledger (Node #12)',
      confirmations: json['confirmations'] as int? ?? 1,
      firstReported: json['first_reported'] != null
          ? DateTime.parse(json['first_reported'] as String)
          : null,
      lastReported: json['last_reported'] != null
          ? DateTime.parse(json['last_reported'] as String)
          : null,
      reportedBy: json['reported_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'tx_hash': txHash,
    'block_index': blockIndex,
    'timestamp': timestamp.toIso8601String(),
    'report_id': reportId,
    'data_hash': dataHash,
    'previous_hash': previousHash,
    'status': status,
    'network': network,
    'confirmations': confirmations,
    'first_reported': firstReported?.toIso8601String(),
    'last_reported': lastReported?.toIso8601String(),
    'reported_by': reportedBy,
  };
}
