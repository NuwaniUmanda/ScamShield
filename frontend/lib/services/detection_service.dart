import '../models/detection_result.dart';
import '../models/scam_report.dart';
import '../data/mock_data.dart';

abstract class DetectionService {
  Future<ScamDetectionResult> scanTextOrUrl(String input);
  ScamDetectionResult getDefaultResult();
}

class MockDetectionService implements DetectionService {
  @override
  ScamDetectionResult getDefaultResult() => MockData.mockDetectionResult;

  @override
  Future<ScamDetectionResult> scanTextOrUrl(String input) async {
    // Simulate AI neural network processing delay
    await Future.delayed(const Duration(milliseconds: 500));

    final lower = input.toLowerCase().trim();

    if (lower.contains('chase') || lower.contains('bank') || lower.contains('verify') || lower.contains('account') || lower.contains('secure-login')) {
      return MockData.mockDetectionResult;
    }

    if (lower.contains('crypto') || lower.contains('usdt') || lower.contains('investment') || lower.contains('return') || lower.contains('yield')) {
      return DetectionResult(
        id: 'DET-AI-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        analyzedTextOrUrl: input,
        predictedType: 'High-Yield Cryptocurrency Scam',
        scamProbability: 92.5,
        riskLevel: RiskLevel.critical,
        aiConfidence: 96.8,
        explanation:
            'The content exhibits signature social engineering flags associated with high-yield investment programs (HYIP) and unhosted crypto wallet draining operations.',
        indicators: const [
          DetectionIndicator(
            title: 'Unrealistic Yield Promises',
            description: 'Guarantees abnormal zero-risk returns on digital asset transfers.',
            severity: RiskLevel.critical,
            shapValue: 0.46,
          ),
          DetectionIndicator(
            title: 'Non-Custodial Deposit Solicitation',
            description: 'Directs payments to unregulated smart contract addresses.',
            severity: RiskLevel.high,
            shapValue: 0.35,
          ),
          DetectionIndicator(
            title: 'Unverifiable Smart Contract',
            description: 'Source bytecode contains unverified proxy withdrawal functions.',
            severity: RiskLevel.high,
            shapValue: 0.22,
          ),
        ],
        recommendations: const [
          'Do not click the link or provide your personal information.',
          'Do NOT deposit funds or share private seed phrases.',
          'Verify official registration on securities/banking regulator registries.',
          'Threat hash flagged on ScamShield distributed block ledger.',
        ],
        analyzedAt: DateTime.now(),
        txHash: '0x39ba...e881',
        isBlockchainRecorded: true,
      );
    }

    if (lower.contains('job') || lower.contains('remote') || lower.contains('salary') || lower.contains('telegram')) {
      return DetectionResult(
        id: 'DET-AI-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        analyzedTextOrUrl: input,
        predictedType: 'Advance-Fee Employment Fraud',
        scamProbability: 84.0,
        riskLevel: RiskLevel.high,
        aiConfidence: 91.2,
        explanation:
            'The submitted content contains several characteristics commonly associated with scam messages.',
        indicators: const [
          DetectionIndicator(
            title: 'Off-Platform Migration',
            description: 'Urges communication move to untraceable Telegram/WhatsApp channels.',
            severity: RiskLevel.high,
            shapValue: 0.38,
          ),
          DetectionIndicator(
            title: 'Upfront Payment Demands',
            description: 'Requires candidate to purchase software licenses or equipment vouchers.',
            severity: RiskLevel.high,
            shapValue: 0.32,
          ),
          DetectionIndicator(
            title: 'Urgent Response Requirement',
            description: 'Demands immediate identity document upload within 2 hours.',
            severity: RiskLevel.medium,
            shapValue: 0.19,
          ),
        ],
        recommendations: const [
          'Do not click the link or provide your personal information.',
          'Never pay money or buy gift cards for any legitimate employer.',
          'Verify corporate domain email address directly with company HR.',
        ],
        analyzedAt: DateTime.now(),
        txHash: '0x88f1...4a2b',
        isBlockchainRecorded: true,
      );
    }

    // Default high-probability suspicious pattern
    return DetectionResult(
      id: 'DET-AI-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      analyzedTextOrUrl: input,
      predictedType: 'Phishing Link',
      scamProbability: 92.0,
      riskLevel: RiskLevel.high,
      aiConfidence: 92.0,
      explanation:
          'The submitted content contains several characteristics commonly associated with scam messages.',
      indicators: const [
        DetectionIndicator(
          title: 'Suspicious URL',
          description: 'URL pattern matches known deceptive domain spoofing tactics.',
          severity: RiskLevel.high,
          shapValue: 0.42,
        ),
        DetectionIndicator(
          title: 'Urgent Language',
          description: 'Employs artificial time pressure and threats of immediate restriction.',
          severity: RiskLevel.high,
          shapValue: 0.31,
        ),
        DetectionIndicator(
          title: 'Credential Request',
          description: 'Prompts input of sensitive banking credentials and security questions.',
          severity: RiskLevel.high,
          shapValue: 0.28,
        ),
        DetectionIndicator(
          title: 'Low Trust Source',
          description: 'Originating domain has low registration age and zero trust reputation.',
          severity: RiskLevel.medium,
          shapValue: 0.18,
        ),
        DetectionIndicator(
          title: 'External Redirect',
          description: 'Contains obfuscated redirection headers navigating to third-party endpoints.',
          severity: RiskLevel.medium,
          shapValue: 0.15,
        ),
      ],
      recommendations: const [
        'Do not click the link or provide your personal information.',
        'Block the sender and report the domain to ScamShield ledger.',
      ],
      analyzedAt: DateTime.now(),
      txHash: '0x41ab...cc12',
      isBlockchainRecorded: true,
    );
  }
}
