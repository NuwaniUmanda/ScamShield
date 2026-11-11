import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/service_registry.dart';
import 'providers/auth_provider.dart';
import 'providers/scam_provider.dart';
import 'providers/detection_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/blockchain_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ServiceRegistry().initMock();
  runApp(const ScamShieldApp());
}

class ScamShieldApp extends StatelessWidget {
  const ScamShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    final services = ServiceRegistry();
    if (!services.isInitialized) {
      services.initMock();
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService: services.authService)),
        ChangeNotifierProvider(create: (_) => ScamProvider(scamService: services.scamService)),
        ChangeNotifierProvider(create: (_) => DetectionProvider(detectionService: services.detectionService)),
        ChangeNotifierProvider(create: (_) => StatsProvider(statisticsService: services.statisticsService)),
        ChangeNotifierProvider(create: (_) => BlockchainProvider(blockchainService: services.blockchainService)),
      ],
      child: MaterialApp.router(
        title: 'ScamShield - AI & Blockchain Scam Detection',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
