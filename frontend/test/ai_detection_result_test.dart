import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/detection_result.dart';
import 'package:frontend/models/scam_report.dart';
import 'package:frontend/providers/detection_provider.dart';
import 'package:frontend/providers/scam_provider.dart';
import 'package:frontend/providers/stats_provider.dart';
import 'package:frontend/screens/ai_detection/ai_detection_screen.dart';
import 'package:frontend/widgets/ai_indicator_bar.dart';
import 'package:frontend/widgets/visual_risk_score.dart';

void main() {
  Widget createTestableWidget({ScamDetectionResult? result}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DetectionProvider()),
        ChangeNotifierProvider(create: (_) => ScamProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: AiDetectionScreen(result: result),
        ),
      ),
    );
  }

  testWidgets('AI Detection Result Screen displays all required Figma elements and mock data',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // 1. Heading
    expect(find.text('AI Detection Result'), findsOneWidget);

    // 2. Verdict & Risk Level
    expect(find.text('Potential Scam Detected'), findsOneWidget);
    expect(find.text('HIGH RISK'), findsOneWidget);

    // 3. Risk Score, AI Confidence & Category
    expect(find.text('Risk Score:'), findsOneWidget);
    expect(find.text('AI Confidence:'), findsOneWidget);
    expect(find.text('Category:'), findsOneWidget);
    expect(find.text('Phishing Link'), findsOneWidget);

    // 4. Reusable AI Indicator cards/bars with SHAP values
    expect(find.text('Suspicious URL'), findsOneWidget);
    expect(find.text('+0.42'), findsOneWidget);

    expect(find.text('Urgent Language'), findsOneWidget);
    expect(find.text('+0.31'), findsOneWidget);

    expect(find.text('Credential Request'), findsOneWidget);
    expect(find.text('+0.28'), findsOneWidget);

    expect(find.text('Low Trust Source'), findsOneWidget);
    expect(find.text('+0.18'), findsOneWidget);

    expect(find.text('External Redirect'), findsOneWidget);
    expect(find.text('+0.15'), findsOneWidget);

    // 5. AI Explanation (SHAP)
    expect(find.text('AI Explanation (SHAP)'), findsOneWidget);
    expect(
      find.text('The submitted content contains several characteristics commonly associated with scam messages.'),
      findsOneWidget,
    );

    // 6. Recommended Action
    expect(find.text('Recommended Action'), findsOneWidget);
    expect(
      find.text('Do not click the link or provide your personal information.'),
      findsOneWidget,
    );

    // 7. Action Buttons
    expect(find.text('Report This Scam'), findsOneWidget);
    expect(find.text('Scam Details'), findsOneWidget);
    expect(find.text('Scan Another Item'), findsNothing);
  });

  testWidgets('AI Detection Result Screen accepts custom ScamDetectionResult model dynamically',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final customResult = ScamDetectionResult(
      id: 'DET-CUSTOM-001',
      analyzedTextOrUrl: 'https://fake-login-bank.xyz',
      predictedType: 'Phishing Link',
      scamProbability: 92.0,
      riskLevel: RiskLevel.high,
      aiConfidence: 92.0,
      explanation: 'The submitted content contains several characteristics commonly associated with scam messages.',
      indicators: [
        DetectionIndicator(
          title: 'Suspicious URL',
          description: 'URL pattern matches known deceptive domain spoofing tactics.',
          severity: RiskLevel.high,
          shapValue: 0.42,
        ),
        DetectionIndicator(
          title: 'Urgent Language',
          description: 'Employs artificial time pressure.',
          severity: RiskLevel.high,
          shapValue: 0.31,
        ),
      ],
      recommendations: [
        'Do not click the link or provide your personal information.',
      ],
      analyzedAt: DateTime(2026, 9, 6),
      txHash: '0x123abc',
      isBlockchainRecorded: true,
    );

    await tester.pumpWidget(createTestableWidget(result: customResult));
    await tester.pumpAndSettle();

    expect(find.text('AI Detection Result'), findsOneWidget);
    expect(find.text('Potential Scam Detected'), findsOneWidget);
    expect(find.text('HIGH RISK'), findsOneWidget);
    expect(find.byType(VisualRiskScore), findsOneWidget);
    expect(find.byType(AiIndicatorBar), findsNWidgets(2));
    expect(find.text('+0.42'), findsOneWidget);
    expect(find.text('+0.31'), findsOneWidget);
    expect(find.text('Report This Scam'), findsOneWidget);
  });
}
