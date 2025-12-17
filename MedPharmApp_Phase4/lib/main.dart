import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/services/database_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/services/biometric_service.dart';
import 'core/services/audit_trail_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/session_manager.dart';

import 'features/authentication/services/auth_service.dart';
import 'features/authentication/providers/auth_provider.dart';

import 'features/assessment/services/assessment_service.dart';
import 'features/assessment/providers/assessment_provider.dart';

import 'features/gamification/services/gamification_service.dart';
import 'features/gamification/providers/gamification_provider.dart';

import 'core/network/api_client.dart';
import 'features/sync/services/sync_service.dart';
import 'features/sync/services/network_service.dart';
import 'features/sync/providers/sync_provider.dart';

import 'app/theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'app/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Starting MedPharm Pain Assessment App...');
  print('Platform: ${kIsWeb ? "Web" : "Native"}');

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      print('Firebase initialized');
    } catch (e) {
      print('Firebase initialization failed: $e');
      // App can still work without Firebase (local mode)
    }
  } else {
    print('Firebase skipped on web (requires configuration)');
  }

  DatabaseService? databaseService;

  if (!kIsWeb) {
    try {
      databaseService = DatabaseService();

      await databaseService.database;
      print('Database initialized');
    } catch (e) {
      print('Database initialization failed: $e');
    }
  } else {
    print('SQLite database not available on web platform');
    print('Using mock mode for web demo');
  }

  SecureStorageService? secureStorage;
  BiometricService? biometricService;

  if (!kIsWeb) {
    secureStorage = SecureStorageService();
    biometricService = BiometricService();

    final isSecureStorageAvailable = await secureStorage.isAvailable();
    print('Secure storage available: $isSecureStorageAvailable');
  } else {
    print('Secure storage/biometrics not available on web');
  }

  PushNotificationService? pushNotificationService;

  if (!kIsWeb) {
    pushNotificationService = PushNotificationService();
    try {
      await pushNotificationService.initialize();
      print('Push notifications initialized');
    } catch (e) {
      print('Push notifications initialization failed: $e');
    }
  } else {
    print('Push notifications not available on web');
  }

  if (kIsWeb) {
    runApp(const MedPharmWebApp());
  } else {
    runApp(MedPharmApp(
      databaseService: databaseService!,
      secureStorage: secureStorage!,
      biometricService: biometricService!,
      pushNotificationService: pushNotificationService!,
    ));
  }
}

class MedPharmApp extends StatelessWidget {
  final DatabaseService databaseService;
  final SecureStorageService secureStorage;
  final BiometricService biometricService;
  final PushNotificationService pushNotificationService;

  const MedPharmApp({
    super.key,
    required this.databaseService,
    required this.secureStorage,
    required this.biometricService,
    required this.pushNotificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>.value(
          value: databaseService,
        ),
        Provider<SecureStorageService>.value(
          value: secureStorage,
        ),
        Provider<BiometricService>.value(
          value: biometricService,
        ),
        Provider<PushNotificationService>.value(
          value: pushNotificationService,
        ),
        Provider<AuditTrailService>(
          create: (context) => AuditTrailService(
            context.read<DatabaseService>(),
            context.read<SecureStorageService>(),
          ),
        ),
        Provider<SessionManager>(
          create: (context) => SessionManager(
            secureStorage: context.read<SecureStorageService>(),
            auditService: context.read<AuditTrailService>(),
          ),
        ),
        Provider<AuthService>(
          create: (context) => AuthService(
            context.read<DatabaseService>(), // Get database service
          ),
        ),
        Provider<AssessmentService>(
          create: (context) => AssessmentService(
            context.read<DatabaseService>(),
          ),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthService>(), // Get auth service
          ),
        ),
        ChangeNotifierProvider<AssessmentProvider>(
          create: (context) => AssessmentProvider(
            context.read<AssessmentService>(),
          ),
        ),
        Provider<GamificationService>(
          create: (context) => GamificationService(
            context.read<DatabaseService>(),
            context.read<AssessmentService>(),
          ),
        ),
        ChangeNotifierProvider<GamificationProvider>(
          create: (context) => GamificationProvider(
            context.read<GamificationService>(),
          ),
        ),
        Provider<ApiClient>(
          create: (context) => ApiClient(),
        ),
        Provider<NetworkService>(
          create: (context) => NetworkService(),
        ),
        Provider<SyncService>(
          create: (context) => SyncService(
            context.read<DatabaseService>(),
            context.read<ApiClient>(),
          ),
        ),
        ChangeNotifierProvider<SyncProvider>(
          create: (context) => SyncProvider(
            context.read<SyncService>(),
            context.read<NetworkService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'MedPharm Pain Assessment',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.enrollment,
        onUnknownRoute: AppRoutes.onUnknownRoute,
      ),
    );
  }
}

class MedPharmWebApp extends StatelessWidget {
  const MedPharmWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedPharm Pain Assessment (Web Demo)',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const WebDemoHomeScreen(),
    );
  }
}

class WebDemoHomeScreen extends StatefulWidget {
  const WebDemoHomeScreen({super.key});

  @override
  State<WebDemoHomeScreen> createState() => _WebDemoHomeScreenState();
}

class _WebDemoHomeScreenState extends State<WebDemoHomeScreen> {
  int _nrsScore = 5;
  int _vasScore = 50;
  final List<Map<String, dynamic>> _assessments = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MedPharm Pain Assessment'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.web, size: 48, color: Colors.blue.shade700),
                    const SizedBox(height: 8),
                    Text(
                      'Web Demo Mode',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.blue.shade700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ta wersja działa w przeglądarce bez bazy danych.\n'
                      'Dla pełnej funkcjonalności uruchom na urządzeniu mobilnym.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // NRS Score
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NRS Pain Score (0-10)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('0'),
                        Expanded(
                          child: Slider(
                            value: _nrsScore.toDouble(),
                            min: 0,
                            max: 10,
                            divisions: 10,
                            label: _nrsScore.toString(),
                            onChanged: (value) {
                              setState(() => _nrsScore = value.round());
                            },
                          ),
                        ),
                        const Text('10'),
                      ],
                    ),
                    Center(
                      child: Text(
                        'Score: $_nrsScore',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // VAS Score
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VAS Pain Score (0-100)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('0'),
                        Expanded(
                          child: Slider(
                            value: _vasScore.toDouble(),
                            min: 0,
                            max: 100,
                            divisions: 100,
                            label: _vasScore.toString(),
                            onChanged: (value) {
                              setState(() => _vasScore = value.round());
                            },
                          ),
                        ),
                        const Text('100'),
                      ],
                    ),
                    Center(
                      child: Text(
                        'Score: $_vasScore',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton.icon(
              onPressed: _submitAssessment,
              icon: const Icon(Icons.check),
              label: const Text('Submit Assessment'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // History
            if (_assessments.isNotEmpty) ...[
              Text(
                'Assessment History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ..._assessments.reversed.map((a) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getScoreColor(a['nrs']),
                        child: Text('${a['nrs']}'),
                      ),
                      title: Text('NRS: ${a['nrs']} | VAS: ${a['vas']}'),
                      subtitle: Text(a['time']),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  void _submitAssessment() {
    setState(() {
      _assessments.add({
        'nrs': _nrsScore,
        'vas': _vasScore,
        'time': DateTime.now().toString().substring(0, 19),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Assessment submitted (demo mode)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score <= 3) return Colors.green;
    if (score <= 6) return Colors.orange;
    return Colors.red;
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About This Demo'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This is a web demo of the MedPharm Clinical Trial App.'),
            SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
