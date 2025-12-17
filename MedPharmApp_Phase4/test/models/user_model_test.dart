// ============================================================================
// USER MODEL VALIDATION TESTS
// ============================================================================
//
// These tests validate that students have correctly implemented UserModel
// Students: Run with `flutter test test/models/user_model_test.dart`
//
// Tests verify:
// - toMap() serialization
// - fromMap() deserialization
// - copyWith() immutability pattern
// - Helper methods (hasCompletedOnboarding, enrollmentStatus)

import 'package:flutter_test/flutter_test.dart';
import 'package:med_pharm_app/features/authentication/models/user_model.dart';

void main() {
  group('UserModel Validation Tests', () {
    // Test data
    final testDate = DateTime(2024, 1, 15, 10, 30);

    // ========================================================================
    // TEST 1: toMap() - Model to Database Map
    // ========================================================================
    group('toMap() Tests', () {
      test('Should convert model to map with all fields', () {
        // Arrange
        final user = UserModel(
          id: 1,
          studyId: 'STUDY123',
          enrollmentCode: 'ABC12345',
          enrolledAt: testDate,
          consentAccepted: true,
          consentAcceptedAt: testDate,
          tutorialCompleted: false,
        );

        // Act
        final map = user.toMap();

        // Assert
        expect(map['id'], 1, reason: 'id should be 1');
        expect(map['study_id'], 'STUDY123',
            reason: 'study_id column name must match database');
        expect(map['enrollment_code'], 'ABC12345',
            reason: 'enrollment_code column name must match database');
        expect(map['enrolled_at'], testDate.toIso8601String(),
            reason: 'DateTime should be stored as ISO8601 string');
        expect(map['consent_accepted'], 1,
            reason: 'Boolean true should be stored as 1 for SQLite');
        expect(map['consent_accepted_at'], testDate.toIso8601String(),
            reason: 'DateTime should be stored as ISO8601 string');
        expect(map['tutorial_completed'], 0,
            reason: 'Boolean false should be stored as 0 for SQLite');
      });

      test('Should handle null values correctly', () {
        // Arrange
        final user = UserModel(
          studyId: 'STUDY456',
          enrollmentCode: 'XYZ99999',
          enrolledAt: testDate,
          consentAccepted: false,
        );

        // Act
        final map = user.toMap();

        // Assert
        expect(map['id'], isNull, reason: 'id should be null when not set');
        expect(map['consent_accepted_at'], isNull,
            reason: 'consent_accepted_at should be null when not provided');
        expect(map['tutorial_completed'], 0,
            reason: 'tutorial_completed defaults to false (0)');
      });

      test('Should use correct database column names', () {
        // Arrange
        final user = UserModel(
          studyId: 'TEST',
          enrollmentCode: 'TEST',
          enrolledAt: testDate,
        );

        // Act
        final map = user.toMap();

        // Assert - Verify snake_case column names
        expect(map.containsKey('study_id'), true,
            reason: 'Must use study_id (not studyId)');
        expect(map.containsKey('enrollment_code'), true,
            reason: 'Must use enrollment_code (not enrollmentCode)');
        expect(map.containsKey('enrolled_at'), true,
            reason: 'Must use enrolled_at (not enrolledAt)');
        expect(map.containsKey('consent_accepted'), true,
            reason: 'Must use consent_accepted (not consentAccepted)');
        expect(map.containsKey('consent_accepted_at'), true,
            reason: 'Must use consent_accepted_at (not consentAcceptedAt)');
        expect(map.containsKey('tutorial_completed'), true,
            reason: 'Must use tutorial_completed (not tutorialCompleted)');
      });
    });

    // ========================================================================
    // TEST 2: fromMap() - Database Map to Model
    // ========================================================================
    group('fromMap() Tests', () {
      test('Should create model from complete map', () {
        // Arrange
        final map = {
          'id': 1,
          'study_id': 'STUDY123',
          'enrollment_code': 'ABC12345',
          'enrolled_at': testDate.toIso8601String(),
          'consent_accepted': 1,
          'consent_accepted_at': testDate.toIso8601String(),
          'tutorial_completed': 0,
        };

        // Act
        final user = UserModel.fromMap(map);

        // Assert
        expect(user.id, 1, reason: 'id should be parsed correctly');
        expect(user.studyId, 'STUDY123',
            reason: 'studyId should be parsed correctly');
        expect(user.enrollmentCode, 'ABC12345',
            reason: 'enrollmentCode should be parsed correctly');
        expect(user.enrolledAt, testDate,
            reason: 'DateTime should be parsed from ISO8601 string');
        expect(user.consentAccepted, true,
            reason: 'Integer 1 should be parsed as boolean true');
        expect(user.consentAcceptedAt, testDate,
            reason: 'DateTime should be parsed from ISO8601 string');
        expect(user.tutorialCompleted, false,
            reason: 'Integer 0 should be parsed as boolean false');
      });

      test('Should handle null values correctly', () {
        // Arrange
        final map = {
          'study_id': 'STUDY456',
          'enrollment_code': 'XYZ99999',
          'enrolled_at': testDate.toIso8601String(),
          'consent_accepted': 0,
          'tutorial_completed': 0,
        };

        // Act
        final user = UserModel.fromMap(map);

        // Assert
        expect(user.id, isNull, reason: 'id should be null when not in map');
        expect(user.consentAcceptedAt, isNull,
            reason: 'consentAcceptedAt should be null when not in map');
      });

      test('Should parse boolean values from integers', () {
        // Arrange
        final mapWithTrue = {
          'study_id': 'TEST',
          'enrollment_code': 'TEST',
          'enrolled_at': testDate.toIso8601String(),
          'consent_accepted': 1,
          'tutorial_completed': 1,
        };

        final mapWithFalse = {
          'study_id': 'TEST',
          'enrollment_code': 'TEST',
          'enrolled_at': testDate.toIso8601String(),
          'consent_accepted': 0,
          'tutorial_completed': 0,
        };

        // Act
        final userTrue = UserModel.fromMap(mapWithTrue);
        final userFalse = UserModel.fromMap(mapWithFalse);

        // Assert
        expect(userTrue.consentAccepted, true,
            reason: '1 should convert to true');
        expect(userTrue.tutorialCompleted, true,
            reason: '1 should convert to true');
        expect(userFalse.consentAccepted, false,
            reason: '0 should convert to false');
        expect(userFalse.tutorialCompleted, false,
            reason: '0 should convert to false');
      });
    });

    // ========================================================================
    // TEST 3: Round-trip Serialization
    // ========================================================================
    group('Round-trip Serialization Tests', () {
      test('Should maintain data integrity through toMap/fromMap cycle', () {
        // Arrange
        final original = UserModel(
          id: 42,
          studyId: 'STUDY999',
          enrollmentCode: 'ROUND123',
          enrolledAt: testDate,
          consentAccepted: true,
          consentAcceptedAt: testDate,
          tutorialCompleted: true,
        );

        // Act
        final map = original.toMap();
        final restored = UserModel.fromMap(map);

        // Assert
        expect(restored.id, original.id);
        expect(restored.studyId, original.studyId);
        expect(restored.enrollmentCode, original.enrollmentCode);
        expect(restored.enrolledAt, original.enrolledAt);
        expect(restored.consentAccepted, original.consentAccepted);
        expect(restored.consentAcceptedAt, original.consentAcceptedAt);
        expect(restored.tutorialCompleted, original.tutorialCompleted);
      });
    });

    // ========================================================================
    // TEST 4: copyWith() - Immutability Pattern
    // ========================================================================
    group('copyWith() Tests', () {
      test('Should create modified copy while keeping original unchanged', () {
        // Arrange
        final original = UserModel(
          id: 1,
          studyId: 'STUDY123',
          enrollmentCode: 'ABC12345',
          enrolledAt: testDate,
          consentAccepted: false,
          tutorialCompleted: false,
        );

        // Act
        final modified = original.copyWith(
          consentAccepted: true,
          consentAcceptedAt: testDate,
        );

        // Assert - Modified copy has new values
        expect(modified.consentAccepted, true);
        expect(modified.consentAcceptedAt, testDate);

        // Assert - Original unchanged
        expect(original.consentAccepted, false);
        expect(original.consentAcceptedAt, isNull);

        // Assert - Other fields copied
        expect(modified.id, original.id);
        expect(modified.studyId, original.studyId);
        expect(modified.enrollmentCode, original.enrollmentCode);
      });

      test('Should allow updating single field', () {
        // Arrange
        final original = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'OLD_CODE',
          enrolledAt: testDate,
        );

        // Act
        final modified = original.copyWith(
          enrollmentCode: 'NEW_CODE',
        );

        // Assert
        expect(modified.enrollmentCode, 'NEW_CODE');
        expect(modified.studyId, original.studyId);
      });

      test('Should allow updating tutorial status', () {
        // Arrange
        final original = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'ABC123',
          enrolledAt: testDate,
          tutorialCompleted: false,
        );

        // Act
        final modified = original.copyWith(tutorialCompleted: true);

        // Assert
        expect(modified.tutorialCompleted, true);
        expect(original.tutorialCompleted, false);
      });
    });

    // ========================================================================
    // TEST 5: Helper Methods
    // ========================================================================
    group('Helper Methods Tests', () {
      test('hasCompletedOnboarding should return true when all steps done', () {
        // Arrange
        final user = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'ABC123',
          enrolledAt: testDate,
          consentAccepted: true,
          tutorialCompleted: true,
        );

        // Act & Assert
        expect(user.hasCompletedOnboarding, true);
      });

      test(
          'hasCompletedOnboarding should return false when consent not accepted',
          () {
        // Arrange
        final user = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'ABC123',
          enrolledAt: testDate,
          consentAccepted: false,
          tutorialCompleted: true,
        );

        // Act & Assert
        expect(user.hasCompletedOnboarding, false);
      });

      test(
          'hasCompletedOnboarding should return false when tutorial not completed',
          () {
        // Arrange
        final user = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'ABC123',
          enrolledAt: testDate,
          consentAccepted: true,
          tutorialCompleted: false,
        );

        // Act & Assert
        expect(user.hasCompletedOnboarding, false);
      });

      test('enrollmentStatus should return correct status string', () {
        // Arrange - Complete
        final completeUser = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'ABC123',
          enrolledAt: testDate,
          consentAccepted: true,
          tutorialCompleted: true,
        );

        // Arrange - Pending consent
        final pendingConsentUser = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'ABC123',
          enrolledAt: testDate,
          consentAccepted: false,
          tutorialCompleted: false,
        );

        // Arrange - Pending tutorial
        final pendingTutorialUser = UserModel(
          studyId: 'STUDY123',
          enrollmentCode: 'ABC123',
          enrolledAt: testDate,
          consentAccepted: true,
          tutorialCompleted: false,
        );

        // Act & Assert
        expect(completeUser.enrollmentStatus, 'Complete');
        expect(pendingConsentUser.enrollmentStatus, 'Pending Consent');
        expect(pendingTutorialUser.enrollmentStatus, 'Pending Tutorial');
      });
    });
  });
}
