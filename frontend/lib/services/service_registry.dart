import 'scam_service.dart';
import 'detection_service.dart';
import 'statistics_service.dart';
import 'blockchain_service.dart';
import 'auth_service.dart';

/// Centralized Service Registry & Dependency Injection container.
/// Allows swapping between mock services and real backend APIs (REST/GraphQL/Web3)
/// seamlessly without altering any UI components.
class ServiceRegistry {
  static final ServiceRegistry _instance = ServiceRegistry._internal();
  factory ServiceRegistry() => _instance;
  ServiceRegistry._internal();

  late ScamService scamService;
  late DetectionService detectionService;
  late StatisticsService statisticsService;
  late BlockchainService blockchainService;
  late AuthService authService;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize with Mock Services (Default development mode)
  void initMock({Duration defaultLatency = Duration.zero}) {
    scamService = MockScamService(latency: defaultLatency);
    detectionService = MockDetectionService();
    statisticsService = MockStatisticsService();
    blockchainService = MockBlockchainService();
    authService = MockAuthService();
    _isInitialized = true;
  }

  /// Configure custom or future real API / Web3 services
  void configure({
    ScamService? customScamService,
    DetectionService? customDetectionService,
    StatisticsService? customStatisticsService,
    BlockchainService? customBlockchainService,
    AuthService? customAuthService,
  }) {
    if (customScamService != null) scamService = customScamService;
    if (customDetectionService != null) detectionService = customDetectionService;
    if (customStatisticsService != null) statisticsService = customStatisticsService;
    if (customBlockchainService != null) blockchainService = customBlockchainService;
    if (customAuthService != null) authService = customAuthService;
    _isInitialized = true;
  }
}
