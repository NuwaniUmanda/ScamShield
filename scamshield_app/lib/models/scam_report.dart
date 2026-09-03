import 'package:flutter/material.dart';

class ScamReport {
  final String id;
  final String title;
  final String description;
  final String scamType;
  final String? targetPhone;
  final String? targetUrl;
  final String? targetWallet;
  final String? targetEmail;
  final double financialLoss;
  final String status; // pending, under_review, approved, rejected
  final int riskScore;
  final Map<String, dynamic> aiAnalysis;
  final String? blockchainTxHash;
  final DateTime? blockchainTimestamp;
  final List<String> evidenceUrls;
  final String? reporterId;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScamReport({
    required this.id,
    required this.title,
    required this.description,
    required this.scamType,
    this.targetPhone,
    this.targetUrl,
    this.targetWallet,
    this.targetEmail,
    this.financialLoss = 0.0,
    this.status = 'pending',
    this.riskScore = 0,
    this.aiAnalysis = const {},
    this.blockchainTxHash,
    this.blockchainTimestamp,
    this.evidenceUrls = const [],
    this.reporterId,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScamReport.fromJson(Map<String, dynamic> json) {
    return ScamReport(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Untitled Scam Report',
      description: json['description'] ?? '',
      scamType: json['scam_type'] ?? 'other',
      targetPhone: json['target_phone'],
      targetUrl: json['target_url'],
      targetWallet: json['target_wallet'],
      targetEmail: json['target_email'],
      financialLoss: (json['financial_loss'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      riskScore: (json['risk_score'] as num?)?.toInt() ?? 0,
      aiAnalysis: json['ai_analysis'] is Map 
          ? Map<String, dynamic>.from(json['ai_analysis']) 
          : {},
      blockchainTxHash: json['blockchain_tx_hash'],
      blockchainTimestamp: json['blockchain_timestamp'] != null
          ? DateTime.tryParse(json['blockchain_timestamp'].toString())
          : null,
      evidenceUrls: json['evidence_urls'] != null
          ? List<String>.from(json['evidence_urls'])
          : [],
      reporterId: json['reporter_id']?.toString(),
      adminNotes: json['admin_notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scam_type': scamType,
      'target_phone': targetPhone,
      'target_url': targetUrl,
      'target_wallet': targetWallet,
      'target_email': targetEmail,
      'financial_loss': financialLoss,
      'status': status,
      'risk_score': riskScore,
      'ai_analysis': aiAnalysis,
      'blockchain_tx_hash': blockchainTxHash,
      'blockchain_timestamp': blockchainTimestamp?.toIso8601String(),
      'evidence_urls': evidenceUrls,
      'reporter_id': reporterId,
      'admin_notes': adminNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // UI Helpers
  Color get riskColor {
    if (riskScore >= 85) return const Color(0xFFEF4444); // Critical Red
    if (riskScore >= 70) return const Color(0xFFF97316); // High Orange
    if (riskScore >= 45) return const Color(0xFFF59E0B); // Medium Amber
    return const Color(0xFF10B981); // Low Green
  }

  String get riskLevelText {
    if (riskScore >= 85) return 'CRITICAL';
    if (riskScore >= 70) return 'HIGH';
    if (riskScore >= 45) return 'MEDIUM';
    return 'LOW';
  }

  String get formattedScamType {
    switch (scamType) {
      case 'phishing': return 'Phishing Site';
      case 'crypto_investment': return 'Crypto Fraud';
      case 'impersonation': return 'Impersonation';
      case 'romance': return 'Romance Scam';
      case 'fake_store': return 'Fake E-Commerce';
      case 'job_scam': return 'Job / Recruitment';
      case 'caller_scam': return 'Phone / SMS Fraud';
      default: return 'General Scam';
    }
  }

  bool get isBlockchainVerified => blockchainTxHash != null && blockchainTxHash!.isNotEmpty;
}
