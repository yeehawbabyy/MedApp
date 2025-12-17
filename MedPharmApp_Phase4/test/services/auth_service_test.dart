// ============================================================================
// AUTH SERVICE VALIDATION TESTS
// ============================================================================
//
// These tests validate that students have correctly implemented AuthService
// Students: Run with `flutter test test/services/auth_service_test.dart`
//
// Tests verify:
// - saveUser() - already implemented (example)
// - getCurrentUser() - retrieve user from database
// - updateConsentStatus() - update consent in database
// - updateTutorialStatus() - update tutorial status in database
// - validateEnrollmentCode() - validate code format
// - isUserEnrolled() - check user existence

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:med_pharm_app/core/services/database_service.dart';
import 'package:med_pharm_app/features/authentication/models/user_model.dart';
import 'package:med_pharm_app/features/authentication/services/auth_service.dart';

void main() {
  // Initialize FFI for testing
  sqfliteFfiInit();

  group('AuthService Validation Tests', () {
    late DatabaseService databaseService;
    late AuthService authService;
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
            // Create user_session table
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

      // Mock DatabaseService to use our test database
      databaseService = DatabaseService();
      authService = AuthService(databaseService);
    });

    tearDown(() async {
      await database.close();
    });

    // ========================================================================
    // TEST 1: saveUser() - Already Implemented (Verification)
    // ========================================================================
    group('saveUser() Tests', () {
      test('Should save user to database', () async {
        // Arrange
        final user = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'ABC12345',
          enrolledAt: DateTime.now(),
          consentAccepted: false,
          tutorialCompleted: false,
        );

        // Act
        final id = await authService.saveUser(user);

        // Assert
        expect(id, greaterThan(0), reason: 'Should return valid ID');

        // Verify in database
        final results = await database.query('user_session');
        expect(results.length, 1);
        expect(results.first['study_id'], 'STUDY123');
      });

      test('Should replace existing user with same study_id', () async {
        // Arrange
        final user1 = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'OLD_CODE',
          enrolledAt: DateTime.now(),
        );

        final user2 = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'NEW_CODE',
          enrolledAt: DateTime.now(),
        );

        // Act
        await authService.saveUser(user1);
        await authService.saveUser(user2);

        // Assert
        final results = await database.query('user_session');
        expect(results.length, 1, reason: 'Should have only one user');
        expect(results.first['enrollment_code'], 'NEW_CODE',
            reason: 'Should have replaced with new code');
      });
    });

    // ========================================================================
    // TEST 2: getCurrentUser() - Student Implementation
    // ========================================================================
    group('getCurrentUser() Tests', () {
      test('Should return null when no user exists', () async {
        // Act
        final user = await authService.getCurrentUser();

        // Assert
        expect(user, isNull, reason: 'Should return null when no user exists');
      });

      test('Should return user when one exists', () async {
        // Arrange
        final savedUser = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'ABC12345',
          enrolledAt: DateTime.now(),
          consentAccepted: true,
          tutorialCompleted: false,
        );
        await authService.saveUser(savedUser);

        // Act
        final retrievedUser = await authService.getCurrentUser();

        // Assert
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.studyId, 'STUDY123');
        expect(retrievedUser.enrollmentCode, 'ABC12345');
        expect(retrievedUser.consentAccepted, true);
        expect(retrievedUser.tutorialCompleted, false);
      });

      test('Should return most recent user when multiple exist', () async {
        // Arrange - Create two users
        await database.insert('user_session', {
          'study_id': 'STUDY001',
          'enrollment_code': 'FIRST',
          'enrolled_at': DateTime.now().toIso8601String(),
          'consent_accepted': 0,
          'tutorial_completed': 0,
        });

        await database.insert('user_session', {
          'study_id': 'STUDY002',
          'enrollment_code': 'SECOND',
          'enrolled_at': DateTime.now().toIso8601String(),
          'consent_accepted': 0,
          'tutorial_completed': 0,
        });

        // Act
        final user = await authService.getCurrentUser();

        // Assert
        expect(user, isNotNull);
        // Should return first result (implementation may vary)
        expect(user!.studyId, isNotEmpty);
      });
    });

    // ========================================================================
    // TEST 3: updateConsentStatus() - Student Implementation
    // ========================================================================
    group('updateConsentStatus() Tests', () {
      test('Should update consent status to accepted', () async {
        // Arrange
        final user = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'ABC12345',
          enrolledAt: DateTime.now(),
          consentAccepted: false,
        );
        await authService.saveUser(user);

        // Act
        await authService.updateConsentStatus('STUDY123');

        // Assert
        final results = await database.query(
          'user_session',
          where: 'study_id = ?',
          whereArgs: ['STUDY123'],
        );
        expect(results.first['consent_accepted'], 1);
        expect(results.first['consent_accepted_at'], isNotNull,
            reason: 'Should set consent_accepted_at timestamp');
      });

      test('Should set consent_accepted_at when accepting', () async {
        // Arrange
        final user = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'ABC12345',
          enrolledAt: DateTime.now(),
          consentAccepted: false,
        );
        await authService.saveUser(user);

        final beforeUpdate = DateTime.now();

        // Act
        await authService.updateConsentStatus('STUDY123');

        // Assert
        final results = await database.query(
          'user_session',
          where: 'study_id = ?',
          whereArgs: ['STUDY123'],
        );
        final consentAcceptedAt =
            DateTime.parse(results.first['consent_accepted_at'] as String);
        expect(consentAcceptedAt.isAfter(beforeUpdate) ||
                consentAcceptedAt.isAtSameMomentAs(beforeUpdate),
            true);
      });

      test('Should return 0 for non-existent user', () async {
        // Act
        final rowsUpdated = await authService.updateConsentStatus('NONEXISTENT');

        // Assert
        expect(rowsUpdated, 0, reason: 'Should return 0 rows updated');
      });
    });

    // ========================================================================
    // TEST 4: updateTutorialStatus() - Student Implementation
    // ========================================================================
    group('updateTutorialStatus() Tests', () {
      test('Should update tutorial status to completed', () async {
        // Arrange
        final user = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'ABC12345',
          enrolledAt: DateTime.now(),
          tutorialCompleted: false,
        );
        await authService.saveUser(user);

        // Act
        await authService.updateTutorialStatus('STUDY123');

        // Assert
        final results = await database.query(
          'user_session',
          where: 'study_id = ?',
          whereArgs: ['STUDY123'],
        );
        expect(results.first['tutorial_completed'], 1);
      });

      test('Should return 0 for non-existent user', () async {
        // Act
        final rowsUpdated = await authService.updateTutorialStatus('NONEXISTENT');

        // Assert
        expect(rowsUpdated, 0, reason: 'Should return 0 rows updated');
      });
    });

    // ========================================================================
    // TEST 5: validateEnrollmentCode() - Student Implementation
    // ========================================================================
    group('validateEnrollmentCode() Tests', () {
      test('Should accept valid 8-character code', () {
        // Act & Assert
        expect(authService.validateEnrollmentCode('ABC12345'), true);
        expect(authService.validateEnrollmentCode('XYZ99999'), true);
        expect(authService.validateEnrollmentCode('TEST0000'), true);
      });

      test('Should accept valid 12-character code', () {
        // Act & Assert
        expect(authService.validateEnrollmentCode('ABCD12345678'), true);
        expect(authService.validateEnrollmentCode('LONGCODE9999'), true);
      });

      test('Should reject empty code', () {
        // Act & Assert
        expect(authService.validateEnrollmentCode(''), false);
      });

      test('Should reject code shorter than 8 characters', () {
        // Act & Assert
        expect(authService.validateEnrollmentCode('ABC123'), false);
        expect(authService.validateEnrollmentCode('SHORT'), false);
        expect(authService.validateEnrollmentCode('A'), false);
      });

      test('Should reject code longer than 12 characters', () {
        // Act & Assert
        expect(authService.validateEnrollmentCode('ABCDEFGH12345'), false);
        expect(authService.validateEnrollmentCode('WAYTOOLONGCODE'), false);
      });

      test('Should reject code with special characters', () {
        // Act & Assert
        expect(authService.validateEnrollmentCode('ABC@1234'), false);
        expect(authService.validateEnrollmentCode('TEST-CODE'), false);
        expect(authService.validateEnrollmentCode('CODE_123'), false);
        expect(authService.validateEnrollmentCode('CODE 123'), false);
      });

      test('Should accept code with only alphanumeric characters', () {
        // Act & Assert
        expect(authService.validateEnrollmentCode('ABCD1234'), true);
        expect(authService.validateEnrollmentCode('12345678'), true);
        expect(authService.validateEnrollmentCode('ABCDEFGH'), true);
        expect(authService.validateEnrollmentCode('MiXeD123'), true);
      });
    });

    // ========================================================================
    // TEST 6: isUserEnrolled() - Student Implementation
    // ========================================================================
    group('isUserEnrolled() Tests', () {
      test('Should return false when no user exists', () async {
        // Act
        final isEnrolled = await authService.isUserEnrolled();

        // Assert
        expect(isEnrolled, false);
      });

      test('Should return true when user exists', () async {
        // Arrange
        final user = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'ABC12345',
          enrolledAt: DateTime.now(),
        );
        await authService.saveUser(user);

        // Act
        final isEnrolled = await authService.isUserEnrolled();

        // Assert
        expect(isEnrolled, true);
      });

      test('Should return true even if consent not accepted', () async {
        // Arrange
        final user = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'ABC12345',
          enrolledAt: DateTime.now(),
          consentAccepted: false,
        );
        await authService.saveUser(user);

        // Act
        final isEnrolled = await authService.isUserEnrolled();

        // Assert
        expect(isEnrolled, true,
            reason: 'User is enrolled even if consent not yet accepted');
      });
    });

    // ========================================================================
    // TEST 7: Integration Tests
    // ========================================================================
    group('Integration Tests', () {
      test('Complete enrollment flow', () async {
        // 1. Verify no user initially
        expect(await authService.isUserEnrolled(), false);
        expect(await authService.getCurrentUser(), isNull);

        // 2. Validate enrollment code
        expect(authService.validateEnrollmentCode('ABC12345'), true);

        // 3. Save user
        final user = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'ABC12345',
          enrolledAt: DateTime.now(),
          consentAccepted: false,
          tutorialCompleted: false,
        );
        await authService.saveUser(user);

        // 4. Verify user enrolled
        expect(await authService.isUserEnrolled(), true);

        // 5. Get current user
        final currentUser = await authService.getCurrentUser();
        expect(currentUser, isNotNull);
        expect(currentUser!.studyId, 'STUDY123');
        expect(currentUser.consentAccepted, false);
        expect(currentUser.tutorialCompleted, false);

        // 6. Accept consent
        await authService.updateConsentStatus('STUDY123');

        // 7. Verify consent updated
        final afterConsent = await authService.getCurrentUser();
        expect(afterConsent!.consentAccepted, true);

        // 8. Complete tutorial
        await authService.updateTutorialStatus('STUDY123');

        // 9. Verify tutorial updated
        final afterTutorial = await authService.getCurrentUser();
        expect(afterTutorial!.tutorialCompleted, true);
        expect(afterTutorial.hasCompletedOnboarding, true);
      });
    });
  });
}
