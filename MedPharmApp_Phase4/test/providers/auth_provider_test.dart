// ============================================================================
// AUTH PROVIDER VALIDATION TESTS
// ============================================================================
//
// These tests validate that students have correctly implemented AuthProvider
// Students: Run with `flutter test test/providers/auth_provider_test.dart`
//
// Tests verify:
// - loadCurrentUser() - already implemented (example)
// - enrollUser() - handle enrollment with validation
// - acceptConsent() - handle consent acceptance
// - completeTutorial() - handle tutorial completion
// - State management (loading, errors, notifyListeners)

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:med_pharm_app/core/services/database_service.dart';
import 'package:med_pharm_app/features/authentication/models/user_model.dart';
import 'package:med_pharm_app/features/authentication/services/auth_service.dart';
import 'package:med_pharm_app/features/authentication/providers/auth_provider.dart';

void main() {
  // Initialize FFI for testing
  sqfliteFfiInit();

  group('AuthProvider Validation Tests', () {
    late DatabaseService databaseService;
    late AuthService authService;
    late AuthProvider authProvider;
    late Database database;

    // ========================================================================
    // SETUP & TEARDOWN
    // ========================================================================
    setUp(() async {
      // Use in-memory database for testing
      databaseFactory = databaseFactoryFfi;
      database = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE user_session (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                study_id TEXT NOT NULL UNIQUE,
                enrollment_code TEXT NOT NULL,
                enrolled_at TEXT NOT NULL,
                consent_accepted INTEGER NOT NULL DEFAULT 0,
                consent_accepted_at TEXT,
                tutorial_completed INTEGER NOT NULL DEFAULT 0
              )
            ''');
          },
        ),
      );

      databaseService = DatabaseService();
      authService = AuthService(databaseService);
      authProvider = AuthProvider(authService);
    });

    tearDown(() async {
      await database.close();
    });

    // ========================================================================
    // TEST 1: Initial State
    // ========================================================================
    group('Initial State Tests', () {
      test('Should have null current user initially', () {
        expect(authProvider.currentUser, isNull);
      });

      test('Should not be loading initially', () {
        expect(authProvider.isLoading, false);
      });

      test('Should have no error initially', () {
        expect(authProvider.errorMessage, isNull);
      });
    });

    // ========================================================================
    // TEST 2: loadCurrentUser() - Already Implemented (Verification)
    // ========================================================================
    group('loadCurrentUser() Tests', () {
      test('Should load null when no user exists', () async {
        // Act
        await authProvider.loadCurrentUser();

        // Assert
        expect(authProvider.currentUser, isNull);
        expect(authProvider.isLoading, false);
        expect(authProvider.errorMessage, isNull);
      });

      test('Should load existing user', () async {
        // Arrange
        final user = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'ABC12345',
          enrolledAt: DateTime.now(),
          consentAccepted: true,
          tutorialCompleted: false,
        );
        await authService.saveUser(user);

        // Act
        await authProvider.loadCurrentUser();

        // Assert
        expect(authProvider.currentUser, isNotNull);
        expect(authProvider.currentUser!.studyId, 'STUDY123');
        expect(authProvider.isLoading, false);
      });

      test('Should set loading state during operation', () async {
        // Arrange
        bool wasLoading = false;
        authProvider.addListener(() {
          if (authProvider.isLoading) {
            wasLoading = true;
          }
        });

        // Act
        await authProvider.loadCurrentUser();

        // Assert
        expect(wasLoading, true, reason: 'Should have been loading at some point');
        expect(authProvider.isLoading, false, reason: 'Should not be loading after completion');
      });
    });

    // ========================================================================
    // TEST 3: enrollUser() - Student Implementation
    // ========================================================================
    group('enrollUser() Tests', () {
      test('Should enroll user with valid code', () async {
        // Arrange
        const validCode = 'ABC12345';

        // Act
        await authProvider.enrollUser(validCode);

        // Assert
        expect(authProvider.currentUser, isNotNull,
            reason: 'Should have current user after enrollment');
        expect(authProvider.currentUser!.enrollmentCode, validCode);
        expect(authProvider.currentUser!.consentAccepted, false,
            reason: 'Consent should not be accepted initially');
        expect(authProvider.currentUser!.tutorialCompleted, false,
            reason: 'Tutorial should not be completed initially');
        expect(authProvider.errorMessage, isNull);
      });

      test('Should generate unique study_id for each enrollment', () async {
        // Act
        await authProvider.enrollUser('CODE001');
        final studyId1 = authProvider.currentUser!.studyId;

        // Clear and enroll again
        await database.delete('user_session');
        await authProvider.enrollUser('CODE002');
        final studyId2 = authProvider.currentUser!.studyId;

        // Assert
        expect(studyId1, isNotEmpty);
        expect(studyId2, isNotEmpty);
        expect(studyId1, isNot(equals(studyId2)),
            reason: 'Each enrollment should generate unique study_id');
      });

      test('Should reject invalid code (too short)', () async {
        // Act
        await authProvider.enrollUser('SHORT');

        // Assert
        expect(authProvider.currentUser, isNull,
            reason: 'Should not create user with invalid code');
        expect(authProvider.errorMessage, isNotNull,
            reason: 'Should set error message');
        expect(authProvider.errorMessage!.toLowerCase(), contains('invalid'),
            reason: 'Error should mention invalid code');
      });

      test('Should reject invalid code (special characters)', () async {
        // Act
        await authProvider.enrollUser('ABC@1234');

        // Assert
        expect(authProvider.currentUser, isNull);
        expect(authProvider.errorMessage, isNotNull);
      });

      test('Should reject empty code', () async {
        // Act
        await authProvider.enrollUser('');

        // Assert
        expect(authProvider.currentUser, isNull);
        expect(authProvider.errorMessage, isNotNull);
      });

      test('Should set loading state during enrollment', () async {
        // Arrange
        bool wasLoading = false;
        authProvider.addListener(() {
          if (authProvider.isLoading) {
            wasLoading = true;
          }
        });

        // Act
        await authProvider.enrollUser('ABC12345');

        // Assert
        expect(wasLoading, true);
        expect(authProvider.isLoading, false);
      });

      test('Should clear previous error on successful enrollment', () async {
        // Arrange - Create an error first
        await authProvider.enrollUser('INVALID');
        expect(authProvider.errorMessage, isNotNull);

        // Act - Enroll with valid code
        await authProvider.enrollUser('ABC12345');

        // Assert
        expect(authProvider.errorMessage, isNull);
      });

      test('Should notify listeners during enrollment', () async {
        // Arrange
        int notificationCount = 0;
        authProvider.addListener(() {
          notificationCount++;
        });

        // Act
        await authProvider.enrollUser('ABC12345');

        // Assert
        expect(notificationCount, greaterThanOrEqualTo(2),
            reason: 'Should notify at least twice (loading start/end)');
      });
    });

    // ========================================================================
    // TEST 4: acceptConsent() - Student Implementation
    // ========================================================================
    group('acceptConsent() Tests', () {
      test('Should update consent status for enrolled user', () async {
        // Arrange
        await authProvider.enrollUser('ABC12345');
        expect(authProvider.currentUser!.consentAccepted, false);

        // Act
        await authProvider.acceptConsent();

        // Assert
        expect(authProvider.currentUser!.consentAccepted, true);
        expect(authProvider.currentUser!.consentAcceptedAt, isNotNull);
        expect(authProvider.errorMessage, isNull);
      });

      test('Should set error if no current user', () async {
        // Act
        await authProvider.acceptConsent();

        // Assert
        expect(authProvider.errorMessage, isNotNull,
            reason: 'Should set error when no user enrolled');
      });

      test('Should persist consent status to database', () async {
        // Arrange
        await authProvider.enrollUser('ABC12345');

        // Act
        await authProvider.acceptConsent();

        // Verify in database
        final results = await database.query('user_session');
        expect(results.first['consent_accepted'], 1);
      });

      test('Should notify listeners when accepting consent', () async {
        // Arrange
        await authProvider.enrollUser('ABC12345');
        int notificationCount = 0;
        authProvider.addListener(() {
          notificationCount++;
        });

        // Act
        await authProvider.acceptConsent();

        // Assert
        expect(notificationCount, greaterThan(0));
      });

      test('Should handle accepting consent multiple times', () async {
        // Arrange
        await authProvider.enrollUser('ABC12345');

        // Act
        await authProvider.acceptConsent();
        await authProvider.acceptConsent(); // Accept again

        // Assert - Should not error
        expect(authProvider.currentUser!.consentAccepted, true);
        expect(authProvider.errorMessage, isNull);
      });
    });

    // ========================================================================
    // TEST 5: completeTutorial() - Student Implementation
    // ========================================================================
    group('completeTutorial() Tests', () {
      test('Should update tutorial status for enrolled user', () async {
        // Arrange
        await authProvider.enrollUser('ABC12345');
        expect(authProvider.currentUser!.tutorialCompleted, false);

        // Act
        await authProvider.completeTutorial();

        // Assert
        expect(authProvider.currentUser!.tutorialCompleted, true);
        expect(authProvider.errorMessage, isNull);
      });

      test('Should set error if no current user', () async {
        // Act
        await authProvider.completeTutorial();

        // Assert
        expect(authProvider.errorMessage, isNotNull);
      });

      test('Should persist tutorial status to database', () async {
        // Arrange
        await authProvider.enrollUser('ABC12345');

        // Act
        await authProvider.completeTutorial();

        // Verify in database
        final results = await database.query('user_session');
        expect(results.first['tutorial_completed'], 1);
      });

      test('Should complete onboarding when both consent and tutorial done',
          () async {
        // Arrange
        await authProvider.enrollUser('ABC12345');

        // Act
        await authProvider.acceptConsent();
        await authProvider.completeTutorial();

        // Assert
        expect(authProvider.currentUser!.hasCompletedOnboarding, true);
      });
    });

    // ========================================================================
    // TEST 6: State Management
    // ========================================================================
    group('State Management Tests', () {
      test('Should clear error message on successful operation', () async {
        // Arrange - Create error
        await authProvider.enrollUser('INVALID');
        expect(authProvider.errorMessage, isNotNull);

        // Act - Successful operation
        await authProvider.enrollUser('ABC12345');

        // Assert
        expect(authProvider.errorMessage, isNull);
      });

      test('Should maintain loading state correctly across operations',
          () async {
        // Initial state
        expect(authProvider.isLoading, false);

        // During enrollment
        bool wasLoadingDuringEnroll = false;
        authProvider.addListener(() {
          if (authProvider.isLoading) wasLoadingDuringEnroll = true;
        });

        await authProvider.enrollUser('ABC12345');
        expect(wasLoadingDuringEnroll, true);
        expect(authProvider.isLoading, false);
      });

      test('Should notify listeners on all state changes', () async {
        // Arrange
        final notifications = <String>[];
        authProvider.addListener(() {
          notifications.add('notified');
        });

        // Act
        await authProvider.enrollUser('ABC12345');
        await authProvider.acceptConsent();
        await authProvider.completeTutorial();

        // Assert
        expect(notifications.length, greaterThan(0),
            reason: 'Should notify listeners on state changes');
      });
    });

    // ========================================================================
    // TEST 7: Integration - Complete Flow
    // ========================================================================
    group('Integration Tests', () {
      test('Complete onboarding flow', () async {
        // 1. Initial state
        expect(authProvider.currentUser, isNull);

        // 2. Enroll user
        await authProvider.enrollUser('ABC12345');
        expect(authProvider.currentUser, isNotNull);
        expect(authProvider.currentUser!.hasCompletedOnboarding, false);

        // 3. Accept consent
        await authProvider.acceptConsent();
        expect(authProvider.currentUser!.consentAccepted, true);
        expect(authProvider.currentUser!.hasCompletedOnboarding, false,
            reason: 'Tutorial not yet completed');

        // 4. Complete tutorial
        await authProvider.completeTutorial();
        expect(authProvider.currentUser!.tutorialCompleted, true);
        expect(authProvider.currentUser!.hasCompletedOnboarding, true);

        // 5. Verify persistence
        await authProvider.loadCurrentUser();
        expect(authProvider.currentUser!.hasCompletedOnboarding, true);
      });

      test('Reject invalid enrollment and recover with valid code', () async {
        // 1. Try invalid code
        await authProvider.enrollUser('BAD');
        expect(authProvider.currentUser, isNull);
        expect(authProvider.errorMessage, isNotNull);

        // 2. Recover with valid code
        await authProvider.enrollUser('ABC12345');
        expect(authProvider.currentUser, isNotNull);
        expect(authProvider.errorMessage, isNull);
      });

      test('Cannot accept consent or complete tutorial without enrollment',
          () async {
        // 1. Try consent without enrollment
        await authProvider.acceptConsent();
        expect(authProvider.errorMessage, isNotNull);

        // 2. Try tutorial without enrollment
        await authProvider.completeTutorial();
        expect(authProvider.errorMessage, isNotNull);

        // 3. Enroll user
        await authProvider.enrollUser('ABC12345');

        // 4. Now should work
        await authProvider.acceptConsent();
        expect(authProvider.currentUser!.consentAccepted, true);

        await authProvider.completeTutorial();
        expect(authProvider.currentUser!.tutorialCompleted, true);
      });
    });
  });
}
