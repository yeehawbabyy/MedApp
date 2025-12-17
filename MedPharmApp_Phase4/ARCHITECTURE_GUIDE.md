# Architecture Guide for Students
## MedPharm Pain Assessment App

**Course:** Mobile Apps in Surgery and Medicine 4.0 (AGH University)
**Lab:** Lab 3 - Clinical Trial Application Development

**Student Level:** Intermediate Flutter (7+ months experience)
**Architecture:** Feature-First with Simplified Clean Architecture
**State Management:** Provider
**Database:** SQLite (sqflite)

**Important:** This is an educational project. MedPharm Corporation and the "Painkiller Forte" trial are fictional, but the architecture and requirements mirror real-world medical software development.

---

## Learning Objectives

By building this app, students will learn:

1. ✅ **Feature-first project organization** - How to structure real-world apps
2. ✅ **SOLID principles** - Professional coding standards (explained simply)
3. ✅ **Provider pattern** - State management in Flutter
4. ✅ **SQLite database** - Persistent data storage
5. ✅ **Offline-first architecture** - Apps that work without internet
6. ✅ **Separation of concerns** - UI vs Data vs Business Logic
7. ✅ **Testing basics** - How to write unit and widget tests

---

## Architecture Overview

### Simple 2-Layer Architecture

Instead of complex 3-layer Clean Architecture, we use a simplified 2-layer approach:

```
┌─────────────────────────────────────┐
│      PRESENTATION LAYER              │
│   (Screens, Widgets, Providers)     │
│                                     │
│   - User Interface (UI)             │
│   - State Management (Provider)     │
│   - Business Logic (simple)         │
└─────────────────┬───────────────────┘
                  │
                  │ talks to
                  │
┌─────────────────▼───────────────────┐
│         DATA LAYER                   │
│   (Services, Database, Models)      │
│                                     │
│   - Database Access (SQLite)        │
│   - API Calls (Future)              │
│   - Data Models                     │
└─────────────────────────────────────┘
```

**Why this approach?**
- ✅ Easier to understand than 3-layer architecture
- ✅ Still follows good separation of concerns
- ✅ Can evolve to full Clean Architecture later
- ✅ Practical for real apps

---

## SOLID Principles (Simple Explanation)

### S - Single Responsibility Principle
**"Each class should do ONE thing and do it well"**

❌ **Bad:** A screen that also handles database and API calls
```dart
class HomeScreen extends StatefulWidget {
  // Screen handles EVERYTHING - BAD!
  void saveToDatabase() { /* database code */ }
  void callAPI() { /* API code */ }
  void updateUI() { /* UI code */ }
}
```

✅ **Good:** Separate responsibilities
```dart
// Screen only handles UI
class HomeScreen extends StatefulWidget { ... }

// Service handles data
class AssessmentService {
  void saveToDatabase() { ... }
  void callAPI() { ... }
}
```

### O - Open/Closed Principle
**"Open for extension, closed for modification"**

Use inheritance and interfaces to extend behavior without changing existing code.

✅ **Good:** Abstract class for data sources
```dart
abstract class DataSource {
  Future<void> save(Assessment data);
}

class LocalDataSource extends DataSource { ... }
class RemoteDataSource extends DataSource { ... }
```

### L - Liskov Substitution Principle
**"Subtypes should be replaceable with their base types"**

If you use a parent class, you should be able to use child class too.

### I - Interface Segregation Principle
**"Don't force classes to implement methods they don't need"**

Make small, specific interfaces instead of one big interface.

### D - Dependency Inversion Principle
**"Depend on abstractions, not concrete implementations"**

This is the MOST IMPORTANT for our architecture!

❌ **Bad:** Screen depends on concrete service
```dart
class HomeScreen {
  final DatabaseService db = DatabaseService(); // Hard-coded!
}
```

✅ **Good:** Screen depends on abstraction, injected via Provider
```dart
class HomeScreen {
  // Provided via Provider - can swap implementations!
}
```

---

## Project Structure (Feature-First)

```
lib/
│
├── main.dart                       # App entry point
│
├── app/
│   ├── theme.dart                  # App theme (colors, text styles)
│   └── routes.dart                 # Navigation routes
│
├── core/                           # Shared code across features
│   ├── models/                     # Shared data models
│   ├── services/                   # Shared services
│   │   └── database_service.dart   # SQLite database singleton
│   ├── widgets/                    # Reusable widgets
│   │   ├── custom_button.dart
│   │   ├── loading_indicator.dart
│   │   └── error_message.dart
│   └── utils/
│       ├── date_helper.dart
│       └── validators.dart
│
└── features/                       # Feature modules
    │
    ├── authentication/             # Feature 1: User enrollment
    │   ├── models/
    │   │   └── user_model.dart
    │   ├── services/
    │   │   └── auth_service.dart
    │   ├── providers/
    │   │   └── auth_provider.dart
    │   └── screens/
    │       ├── enrollment_screen.dart
    │       ├── consent_screen.dart
    │       └── tutorial_screen.dart
    │
    ├── assessment/                 # Feature 2: Pain assessments
    │   ├── models/
    │   │   ├── assessment_model.dart
    │   │   └── pain_score_model.dart
    │   ├── services/
    │   │   ├── assessment_service.dart
    │   │   └── questionnaire_service.dart
    │   ├── providers/
    │   │   ├── assessment_provider.dart
    │   │   └── questionnaire_provider.dart
    │   └── screens/
    │       ├── assessment_home_screen.dart
    │       ├── nrs_screen.dart
    │       ├── vas_screen.dart
    │       └── mcgill_screen.dart
    │
    ├── sync/                       # Feature 3: Data synchronization
    │   ├── models/
    │   │   └── sync_status_model.dart
    │   ├── services/
    │   │   └── sync_service.dart
    │   ├── providers/
    │   │   └── sync_provider.dart
    │   └── widgets/
    │       └── sync_indicator.dart
    │
    └── gamification/               # Feature 4: Points & badges
        ├── models/
        │   ├── badge_model.dart
        │   └── progress_model.dart
        ├── services/
        │   └── gamification_service.dart
        ├── providers/
        │   └── gamification_provider.dart
        └── screens/
            ├── progress_screen.dart
            └── badge_gallery_screen.dart
```

### Why Feature-First?

✅ **Easier to navigate** - All related code is together
✅ **Team-friendly** - Different developers can work on different features
✅ **Scalable** - Easy to add new features without touching existing code
✅ **Real-world** - This is how professional apps are organized

---

## Layer Details

### 1. Presentation Layer (UI + State)

**What goes here:**
- Screens (pages)
- Widgets (UI components)
- Providers (state management)
- Simple UI logic

**Example: Assessment Screen**
```dart
// lib/features/assessment/screens/nrs_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/assessment_provider.dart';

class NRSScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get provider (state management)
    final provider = Provider.of<AssessmentProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Pain Rating (0-10)')),
      body: Column(
        children: [
          // Display pain scale
          Text('How much pain do you feel right now?'),

          // Pain scale buttons (0-10)
          Wrap(
            children: List.generate(11, (index) {
              return PainScaleButton(
                score: index,
                isSelected: provider.currentNRSScore == index,
                onTap: () => provider.selectNRSScore(index),
              );
            }),
          ),

          // Next button
          ElevatedButton(
            onPressed: provider.currentNRSScore != null
                ? () => Navigator.pushNamed(context, '/vas')
                : null,
            child: Text('Next'),
          ),
        ],
      ),
    );
  }
}
```

**Example: Assessment Provider (State Management)**
```dart
// lib/features/assessment/providers/assessment_provider.dart

import 'package:flutter/foundation.dart';
import '../models/assessment_model.dart';
import '../services/assessment_service.dart';

class AssessmentProvider extends ChangeNotifier {
  final AssessmentService _service;

  AssessmentProvider(this._service);

  // State variables
  int? currentNRSScore;
  int? currentVASScore;
  bool isLoading = false;
  String? errorMessage;

  // Select NRS score (0-10)
  void selectNRSScore(int score) {
    currentNRSScore = score;
    notifyListeners(); // Tell UI to rebuild
  }

  // Select VAS score (0-100)
  void selectVASScore(int score) {
    currentVASScore = score;
    notifyListeners();
  }

  // Submit assessment
  Future<void> submitAssessment() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Create assessment model
      final assessment = AssessmentModel(
        nrsScore: currentNRSScore!,
        vasScore: currentVASScore!,
        timestamp: DateTime.now(),
      );

      // Save via service
      await _service.saveAssessment(assessment);

      // Reset state
      currentNRSScore = null;
      currentVASScore = null;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to save assessment';
      isLoading = false;
      notifyListeners();
    }
  }
}
```

### 2. Data Layer (Services + Database)

**What goes here:**
- Services (business logic + data access)
- Database operations
- API calls
- Data models

**Example: Assessment Service**
```dart
// lib/features/assessment/services/assessment_service.dart

import '../models/assessment_model.dart';
import '../../../core/services/database_service.dart';

class AssessmentService {
  final DatabaseService _db;

  AssessmentService(this._db);

  // Save assessment to local database
  Future<void> saveAssessment(AssessmentModel assessment) async {
    final db = await _db.database;

    await db.insert(
      'assessments',
      assessment.toMap(),
    );
  }

  // Get today's assessment (if exists)
  Future<AssessmentModel?> getTodayAssessment() async {
    final db = await _db.database;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final results = await db.query(
      'assessments',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
    );

    if (results.isEmpty) return null;
    return AssessmentModel.fromMap(results.first);
  }

  // Get assessment history
  Future<List<AssessmentModel>> getAssessmentHistory({
    int limit = 30,
  }) async {
    final db = await _db.database;

    final results = await db.query(
      'assessments',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return results.map((map) => AssessmentModel.fromMap(map)).toList();
  }
}
```

**Example: Assessment Model**
```dart
// lib/features/assessment/models/assessment_model.dart

class AssessmentModel {
  final String id;
  final int nrsScore;      // 0-10
  final int vasScore;      // 0-100
  final DateTime timestamp;
  final bool isSynced;

  AssessmentModel({
    String? id,
    required this.nrsScore,
    required this.vasScore,
    required this.timestamp,
    this.isSynced = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nrs_score': nrsScore,
      'vas_score': vasScore,
      'timestamp': timestamp.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  // Create from Map (from database)
  factory AssessmentModel.fromMap(Map<String, dynamic> map) {
    return AssessmentModel(
      id: map['id'],
      nrsScore: map['nrs_score'],
      vasScore: map['vas_score'],
      timestamp: DateTime.parse(map['timestamp']),
      isSynced: map['is_synced'] == 1,
    );
  }

  // Copy with (for updates)
  AssessmentModel copyWith({
    String? id,
    int? nrsScore,
    int? vasScore,
    DateTime? timestamp,
    bool? isSynced,
  }) {
    return AssessmentModel(
      id: id ?? this.id,
      nrsScore: nrsScore ?? this.nrsScore,
      vasScore: vasScore ?? this.vasScore,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
```

---

## Database Layer (SQLite)

### Database Service (Singleton Pattern)

```dart
// lib/core/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // Singleton pattern - only one instance exists
  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  // Get database (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'medpharm.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    // Assessments table
    await db.execute('''
      CREATE TABLE assessments (
        id TEXT PRIMARY KEY,
        nrs_score INTEGER NOT NULL,
        vas_score INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Add indexes for faster queries
    await db.execute('''
      CREATE INDEX idx_assessments_timestamp
      ON assessments(timestamp)
    ''');

    // User session table
    await db.execute('''
      CREATE TABLE user_session (
        id INTEGER PRIMARY KEY,
        study_id TEXT NOT NULL,
        enrollment_code TEXT NOT NULL,
        enrolled_at TEXT NOT NULL
      )
    ''');

    // Add more tables as needed...
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add migration logic here when database schema changes
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE assessments ADD COLUMN new_field TEXT');
    // }
  }

  // Close database (call when app closes)
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
```

### Simplified Database Schema

**For students, we'll start with these essential tables:**

```sql
-- 1. User Session (stores enrollment info)
CREATE TABLE user_session (
  id INTEGER PRIMARY KEY,
  study_id TEXT NOT NULL,
  enrollment_code TEXT NOT NULL,
  enrolled_at TEXT NOT NULL
);

-- 2. Assessments (daily pain assessments)
CREATE TABLE assessments (
  id TEXT PRIMARY KEY,
  nrs_score INTEGER NOT NULL,         -- Pain rating 0-10
  vas_score INTEGER NOT NULL,         -- Visual analog 0-100
  timestamp TEXT NOT NULL,
  is_synced INTEGER DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 3. Gamification Progress
CREATE TABLE gamification_progress (
  id INTEGER PRIMARY KEY,
  total_points INTEGER DEFAULT 0,
  current_level INTEGER DEFAULT 1,
  assessments_completed INTEGER DEFAULT 0
);

-- 4. Sync Queue (for offline-first)
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY,
  assessment_id TEXT NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  retry_count INTEGER DEFAULT 0
);
```

**Students will learn:**
- Table design
- Primary keys
- Foreign keys (later)
- Indexes for performance
- Timestamps
- Boolean as INTEGER (SQLite doesn't have BOOLEAN)

---

## Provider Setup (Dependency Injection)

### main.dart - App Entry Point

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core services
import 'core/services/database_service.dart';

// Feature services
import 'features/assessment/services/assessment_service.dart';
import 'features/gamification/services/gamification_service.dart';

// Feature providers
import 'features/assessment/providers/assessment_provider.dart';
import 'features/gamification/providers/gamification_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final dbService = DatabaseService();
  await dbService.database; // Force initialization

  runApp(MedPharmApp(dbService: dbService));
}

class MedPharmApp extends StatelessWidget {
  final DatabaseService dbService;

  const MedPharmApp({required this.dbService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Provide services (these create the data layer)
        Provider<DatabaseService>.value(value: dbService),

        Provider<AssessmentService>(
          create: (_) => AssessmentService(dbService),
        ),

        Provider<GamificationService>(
          create: (_) => GamificationService(dbService),
        ),

        // 2. Provide state managers (these manage UI state)
        ChangeNotifierProvider<AssessmentProvider>(
          create: (context) => AssessmentProvider(
            context.read<AssessmentService>(),
          ),
        ),

        ChangeNotifierProvider<GamificationProvider>(
          create: (context) => GamificationProvider(
            context.read<GamificationService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'MedPharm Pain Assessment',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: HomeScreen(),
      ),
    );
  }
}
```

### Understanding Provider Pattern

**Provider Pattern = Dependency Injection for Flutter**

1. **Provider** - Gives access to objects down the widget tree
2. **ChangeNotifierProvider** - For objects that change and notify listeners
3. **Consumer** - Widget that listens to changes
4. **context.read()** - Get provider without listening
5. **context.watch()** - Get provider and listen for changes

**Example: Using Provider in a Widget**

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Option 1: Watch for changes (rebuilds when state changes)
    final assessmentProvider = context.watch<AssessmentProvider>();

    // Option 2: Read without watching (doesn't rebuild)
    // final assessmentProvider = context.read<AssessmentProvider>();

    return Scaffold(
      body: Column(
        children: [
          Text('Current Score: ${assessmentProvider.currentNRSScore}'),

          ElevatedButton(
            onPressed: () {
              // Call method on provider
              assessmentProvider.selectNRSScore(7);
            },
            child: Text('Select Score 7'),
          ),
        ],
      ),
    );
  }
}
```

**Consumer Widget (Alternative)**

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AssessmentProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Text('Score: ${provider.currentNRSScore}'),
              // ... rest of UI
            ],
          );
        },
      ),
    );
  }
}
```

---

## Offline-First Architecture (Simplified)

### Concept: Local Database First, Sync Later

```
┌──────────────┐
│  User Action │
│ (Submit Form)│
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│ Save to SQLite   │  ← Always succeeds (offline-first)
│  (Local First)   │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Add to Sync Queue│  ← Mark for later sync
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Background Sync  │  ← When internet available
│  (Future Feature)│
└──────────────────┘
```

### Simple Sync Service (Students Build This Later)

```dart
// lib/features/sync/services/sync_service.dart

import '../../../core/services/database_service.dart';

class SyncService {
  final DatabaseService _db;

  SyncService(this._db);

  // Get unsynced assessments
  Future<List<Map<String, dynamic>>> getUnsyncedAssessments() async {
    final db = await _db.database;

    return await db.query(
      'assessments',
      where: 'is_synced = ?',
      whereArgs: [0], // 0 = false in SQLite
    );
  }

  // Mark assessment as synced
  Future<void> markAsSynced(String assessmentId) async {
    final db = await _db.database;

    await db.update(
      'assessments',
      {'is_synced': 1}, // 1 = true
      where: 'id = ?',
      whereArgs: [assessmentId],
    );
  }

  // Sync all pending assessments
  Future<void> syncAll() async {
    final unsynced = await getUnsyncedAssessments();

    for (var assessment in unsynced) {
      try {
        // TODO: Send to API (students implement later)
        // await _apiService.sendAssessment(assessment);

        // Mark as synced
        await markAsSynced(assessment['id']);
      } catch (e) {
        print('Sync failed for ${assessment['id']}: $e');
        // Continue to next assessment
      }
    }
  }
}
```

---

## Step-by-Step Learning Path for Students

### Phase 1: Setup & Basic UI (Week 1-2)
**Learning:** Flutter basics, navigation, simple UI

**Tasks:**
1. ✅ Create project structure (folders)
2. ✅ Build enrollment screen (TextInput, Button)
3. ✅ Build consent screen (Checkbox, ScrollView)
4. ✅ Add navigation between screens
5. ✅ Create custom widgets (buttons, cards)

**No database yet - use StatefulWidget with setState()**

### Phase 2: State Management with Provider (Week 3-4)
**Learning:** Provider pattern, ChangeNotifier, state management

**Tasks:**
1. ✅ Create first Provider (AuthProvider)
2. ✅ Replace setState() with Provider
3. ✅ Build assessment screens with Provider
4. ✅ Learn Consumer vs context.watch()
5. ✅ Handle loading states and errors

**Still no database - data lives in Provider**

### Phase 3: Database Integration (Week 5-6)
**Learning:** SQLite, CRUD operations, data persistence

**Tasks:**
1. ✅ Create DatabaseService (singleton)
2. ✅ Design database schema
3. ✅ Create AssessmentService
4. ✅ Learn SQL: INSERT, SELECT, UPDATE
5. ✅ Save assessments to database
6. ✅ Load history from database

**Now data persists across app restarts!**

### Phase 4: Offline-First & Sync (Week 7-8)
**Learning:** Offline-first architecture, background sync

**Tasks:**
1. ✅ Add sync_queue table
2. ✅ Create SyncService
3. ✅ Implement sync queue logic
4. ✅ Add sync indicators in UI
5. ✅ Handle sync errors gracefully

### Phase 5: Gamification (Week 9-10)
**Learning:** Complex state, calculated values, animations

**Tasks:**
1. ✅ Create gamification database tables
2. ✅ Implement points calculation
3. ✅ Build progress screen with charts
4. ✅ Add badge system
5. ✅ Create achievement animations

### Phase 6: Polish & Testing (Week 11-12)
**Learning:** Testing, accessibility, performance

**Tasks:**
1. ✅ Write unit tests for services
2. ✅ Write widget tests for screens
3. ✅ Add accessibility labels
4. ✅ Optimize database queries
5. ✅ Add error handling everywhere

---

## Testing Strategy (Simplified for Students)

### Unit Tests (Test Services)

```dart
// test/features/assessment/services/assessment_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:med_pharm_app/features/assessment/services/assessment_service.dart';
import 'package:med_pharm_app/features/assessment/models/assessment_model.dart';

void main() {
  // Initialize SQLite for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AssessmentService Tests', () {
    late AssessmentService service;

    setUp(() async {
      // Create service with test database
      final dbService = DatabaseService();
      service = AssessmentService(dbService);
    });

    test('should save assessment to database', () async {
      // Arrange - create test data
      final assessment = AssessmentModel(
        nrsScore: 7,
        vasScore: 65,
        timestamp: DateTime.now(),
      );

      // Act - call the method
      await service.saveAssessment(assessment);

      // Assert - check it was saved
      final saved = await service.getTodayAssessment();
      expect(saved, isNotNull);
      expect(saved!.nrsScore, equals(7));
      expect(saved.vasScore, equals(65));
    });

    test('should get assessment history', () async {
      // Test getting multiple assessments...
    });
  });
}
```

### Widget Tests (Test UI)

```dart
// test/features/assessment/screens/nrs_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:med_pharm_app/features/assessment/screens/nrs_screen.dart';
import 'package:med_pharm_app/features/assessment/providers/assessment_provider.dart';

void main() {
  testWidgets('NRS screen displays pain scale buttons', (tester) async {
    // Create mock provider
    final provider = AssessmentProvider(MockAssessmentService());

    // Build widget
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: provider,
          child: NRSScreen(),
        ),
      ),
    );

    // Verify buttons 0-10 are displayed
    expect(find.text('0'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);

    // Tap button 7
    await tester.tap(find.text('7'));
    await tester.pump();

    // Verify selection
    expect(provider.currentNRSScore, equals(7));
  });
}
```

---

## Required Packages (Minimal)

```yaml
# pubspec.yaml

dependencies:
  flutter:
    sdk: flutter

  # State Management
  provider: ^6.1.0

  # Database
  sqflite: ^2.3.0
  path: ^1.8.3

  # UI
  intl: ^0.18.1                    # Date formatting

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^3.0.0

  # Testing
  sqflite_common_ffi: ^2.3.0      # For testing SQLite
```

**That's it!** Simple, minimal dependencies. Students learn core concepts.

---

## Common Pitfalls & How to Avoid Them

### 1. "Provider not found" Error

❌ **Problem:**
```dart
context.read<AssessmentProvider>(); // Error: Provider not found!
```

✅ **Solution:** Make sure provider is above widget in tree
```dart
runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AssessmentProvider()),
    ],
    child: MaterialApp(home: HomeScreen()),
  ),
);
```

### 2. Forgot to call notifyListeners()

❌ **Problem:** UI doesn't update when state changes
```dart
void selectScore(int score) {
  currentScore = score;
  // Forgot notifyListeners()!
}
```

✅ **Solution:** Always call notifyListeners() after state changes
```dart
void selectScore(int score) {
  currentScore = score;
  notifyListeners(); // UI rebuilds!
}
```

### 3. Database not initialized

❌ **Problem:**
```dart
void main() {
  runApp(MyApp()); // Database not initialized!
}
```

✅ **Solution:** Use async main and await database
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();
  await db.database; // Wait for DB to initialize
  runApp(MyApp());
}
```

### 4. SQL Injection Risk

❌ **Dangerous:**
```dart
db.rawQuery('SELECT * FROM users WHERE id = $userId'); // SQL INJECTION!
```

✅ **Safe:** Use parameterized queries
```dart
db.query('users', where: 'id = ?', whereArgs: [userId]);
```

---

## Assessment Rubric for Students

### Code Quality (40%)
- ✅ Proper folder structure (feature-first)
- ✅ Single responsibility (each class has one job)
- ✅ No hardcoded values (use constants)
- ✅ Meaningful variable names
- ✅ Comments on complex logic

### Architecture (30%)
- ✅ Separation of UI and Data layers
- ✅ Correct use of Provider
- ✅ Services handle data access
- ✅ Models for data structures
- ✅ No business logic in widgets

### Functionality (20%)
- ✅ App works correctly
- ✅ Data persists in database
- ✅ Offline-first implementation
- ✅ Error handling
- ✅ User-friendly UI

### Testing (10%)
- ✅ Unit tests for services
- ✅ Widget tests for key screens
- ✅ Test coverage > 50%

---

## Next Steps

Ready to start implementing? Follow this order:

1. **Review the scaffolded code** - Most of the structure is already in place
2. **Start with Phase 1** - Complete the TODOs in authentication feature
3. **Follow the patterns** - Look at complete examples, then implement similar methods
4. **Test frequently** - Run the app after each major change
5. **Read the PRD** - Understand what each feature should do
6. **Ask questions** - Your instructor is here to help!

The project is intentionally scaffolded with different levels of completion:
- Phase 1 (Authentication): 80% complete - learn by filling in TODOs
- Phase 2 (Assessment): 50% complete - use Phase 1 patterns as a guide
- Phase 3 (Gamification): 30% complete - more independence

This gradual reduction in scaffolding helps you build confidence and understanding.
