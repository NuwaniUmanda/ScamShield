import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/scam_report.dart';
import 'package:frontend/models/blockchain_verification.dart';
import 'package:frontend/providers/scam_provider.dart';
import 'package:frontend/providers/blockchain_provider.dart';
import 'package:frontend/screens/scam_details/scam_details_screen.dart';
import 'package:frontend/widgets/blockchain_verification_card.dart';

void main() {
  final testReport = ScamReport(
    id: 'REP-84921',
    title: 'facebook-security-login.com',
    scamType: 'Phishing Link',
    targetOrSuspect: 'https://facebook-security-login.com',
    description: 'Deceptive Facebook security verification portal stealing user account credentials and 2FA tokens.',
    riskLevel: RiskLevel.high,
    status: ReportStatus.verified,
    riskScore: 94.0,
    reportedAt: DateTime(2026, 9, 6, 9, 42, 10),
    txHash: '0x9a4f7831cd09b2e56417a8c56e34419bbcf391e0892',
    isBlockchainVerified: true,
    evidenceFiles: const ['facebook_spoof.png'],
    reporterEmail: 'victim_fb@example.com',
    reportCount: 27,
  );

  Widget createTestableWidget({ScamReport? report}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScamProvider()),
        ChangeNotifierProvider(create: (_) => BlockchainProvider()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ScamDetailsScreen(report: report ?? testReport),
        ),
      ),
    );
  }

  testWidgets('Scam Details screen displays all Figma fields and BlockchainVerificationCard',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // 1. Breadcrumb
    expect(find.text('Scam Details'), findsWidgets);

    // 2. Scam Information Section
    expect(find.text('Scam Information'), findsOneWidget);
    expect(find.text('facebook-security-login.com'), findsOneWidget);
    expect(find.text('High Risk'), findsWidgets);
    expect(find.text('Verified'), findsWidgets);
    expect(find.text('Phishing Link'), findsWidgets);
    expect(find.text('Reported 27 times'), findsOneWidget);

    // 3. Risk Score 94%
    expect(find.text('Risk Score'), findsOneWidget);
    expect(find.text('94%'), findsOneWidget);

    // 4. Description, Detection Indicators & AI Explanation
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Detection Indicators & AI Explanation'), findsOneWidget);
    expect(find.text('Suspicious URL'), findsOneWidget);
    expect(find.text('Urgent Language'), findsOneWidget);

    // 5. Blockchain Verification Card
    expect(find.byType(BlockchainVerificationCard), findsOneWidget);
    expect(find.text('Blockchain Verification'), findsOneWidget);
    expect(find.text('Blockchain Verified'), findsWidgets);
    expect(find.text('Report Hash (SHA-256)'), findsOneWidget);
    expect(find.text('Transaction Hash'), findsOneWidget);
    expect(find.text('Block Number'), findsOneWidget);
    expect(find.text('Timestamp'), findsOneWidget);
    expect(find.text('First Reported'), findsOneWidget);
    expect(find.text('Last Reported'), findsOneWidget);
    expect(find.text('Reported By'), findsOneWidget);
  });

  testWidgets('BlockchainVerificationCard renders mock blockchain fields and status indicator',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final verification = BlockchainVerification(
      txHash: '0x9a4f7831cd09b2e56417a8c56e34419bbcf391e0892',
      blockIndex: 48291,
      timestamp: DateTime(2026, 9, 6, 9, 42, 10),
      reportId: 'REP-84921',
      dataHash: 'sha256:4a38f7c9e11059f33cb02a2ec9104fa28e',
      previousHash: '0x7e29b4009a82cd1554ef028e19c3b8813a',
      status: 'Blockchain Verified',
      network: 'ScamShield Security Ledger (Node #12)',
      confirmations: 24,
      firstReported: DateTime(2026, 9, 5, 14, 20, 0),
      lastReported: DateTime(2026, 9, 6, 9, 42, 10),
      reportedBy: 'Community Security Network (Node #8829)',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BlockchainVerificationCard(
              verification: verification,
              report: testReport,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blockchain Verification'), findsOneWidget);
    expect(find.text('Blockchain Verified'), findsOneWidget);
    expect(find.text('sha256:4a38f7c9e11059f33cb02a2ec9104fa28e'), findsOneWidget);
    expect(find.text('#48291'), findsOneWidget);
    expect(find.text('Community Security Network (Node #8829)'), findsOneWidget);
  });
}
