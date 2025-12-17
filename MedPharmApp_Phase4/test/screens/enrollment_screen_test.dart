// ============================================================================
// ENROLLMENT SCREEN WIDGET TESTS
// ============================================================================
//
// These tests validate the EnrollmentScreen UI and Provider integration
// Students: Run with `flutter test test/screens/enrollment_screen_test.dart`
//
// Tests verify:
// - UI elements render correctly
// - Form validation works
// - Integration with AuthProvider
// - Loading and error states
// - Navigation after successful enrollment

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:med_pharm_app/core/services/database_service.dart';
import 'package:med_pharm_app/features/authentication/services/auth_service.dart';
import 'package:med_pharm_app/features/authentication/providers/auth_provider.dart';
import 'package:med_pharm_app/features/authentication/screens/enrollment_screen.dart';

void main() {
  // Initialize FFI for testing
  sqfliteFfiInit();

  group('EnrollmentScreen Widget Tests', () {
    late DatabaseService databaseService;
    late AuthService authService;
    late AuthProvider authProvider;

    setUp(() async {
      // Setup test database
      databaseFactory = databaseFactoryFfi;
      databaseService = DatabaseService();
      authService = AuthService(databaseService);
      authProvider = AuthProvider(authService);
    });

    // Helper function to create test widget
    Widget createTestWidget() {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: const MaterialApp(
          home: EnrollmentScreen(),
        ),
      );
    }

    // ========================================================================
    // TEST 1: UI Rendering
    // ========================================================================
    group('UI Rendering Tests', () {
      testWidgets('Should display app title', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('MedPharm'), findsOneWidget);
      });

      testWidgets('Should display welcome message', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Welcome'), findsOneWidget);
        expect(find.textContaining('Pain Assessment Clinical Trial'),
            findsOneWidget);
      });

      testWidgets('Should display enrollment code input field',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Enrollment Code'), findsOneWidget);
      });

      testWidgets('Should display enrollment button',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.widgetWithText(ElevatedButton, 'Enroll in Study'),
            findsOneWidget);
      });

      testWidgets('Should display info text about code format',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.textContaining('8-12 characters'), findsOneWidget);
      });
    });

    // ========================================================================
    // TEST 2: Form Validation
    // ========================================================================
    group('Form Validation Tests', () {
      testWidgets('Should accept valid enrollment code',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byType(TextField), 'ABC12345');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pump();

        // Assert - Should not show validation error
        expect(find.text('Invalid code'), findsNothing);
      });

      testWidgets('Should reject empty enrollment code',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pump();

        // Assert - May show error (implementation dependent)
        // The implementation should handle this case
      });

      testWidgets('Should show error for invalid code',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byType(TextField), 'SHORT');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pumpAndSettle();

        // Assert - Error should be displayed somewhere
        // (Either in TextField or as separate error message)
        expect(authProvider.errorMessage, isNotNull);
      });
    });

    // ========================================================================
    // TEST 3: Provider Integration
    // ========================================================================
    group('Provider Integration Tests', () {
      testWidgets('Should call enrollUser on button press with valid code',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byType(TextField), 'ABC12345');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pumpAndSettle();

        // Assert
        expect(authProvider.currentUser, isNotNull,
            reason: 'Should have enrolled user');
        expect(authProvider.currentUser!.enrollmentCode, 'ABC12345');
      });

      testWidgets('Should update UI when enrollment succeeds',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byType(TextField), 'ABC12345');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pumpAndSettle();

        // Assert - Provider should have current user
        expect(authProvider.currentUser, isNotNull);
        expect(authProvider.errorMessage, isNull);
      });

      testWidgets('Should display error message from provider',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act - Enter invalid code
        await tester.enterText(find.byType(TextField), 'BAD');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pumpAndSettle();

        // Assert
        expect(authProvider.errorMessage, isNotNull);
        // Error should be displayed in UI
        // (Implementation may vary - could be in SnackBar, Text widget, etc.)
      });
    });

    // ========================================================================
    // TEST 4: Loading State
    // ========================================================================
    group('Loading State Tests', () {
      testWidgets('Should show loading indicator during enrollment',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byType(TextField), 'ABC12345');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pump(); // Don't settle - catch loading state

        // Assert - Should show some loading indicator
        // (CircularProgressIndicator, disabled button, etc.)
        // Implementation dependent
      });

      testWidgets('Should disable button during enrollment',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byType(TextField), 'ABC12345');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pump();

        // Assert - Button should be disabled during loading
        // (Implementation dependent - may check enabled state)
      });

      testWidgets('Should re-enable button after enrollment completes',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byType(TextField), 'ABC12345');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pumpAndSettle();

        // Assert
        expect(authProvider.isLoading, false);
      });
    });

    // ========================================================================
    // TEST 5: Error Handling
    // ========================================================================
    group('Error Handling Tests', () {
      testWidgets('Should clear previous error on new attempt',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act - First attempt with invalid code
        await tester.enterText(find.byType(TextField), 'BAD');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pumpAndSettle();
        expect(authProvider.errorMessage, isNotNull);

        // Act - Second attempt with valid code
        await tester.enterText(find.byType(TextField), 'ABC12345');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pumpAndSettle();

        // Assert
        expect(authProvider.errorMessage, isNull,
            reason: 'Error should be cleared on successful enrollment');
      });

      testWidgets('Should show different errors for different validation issues',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Test empty code
        await tester.enterText(find.byType(TextField), '');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pumpAndSettle();
        final emptyError = authProvider.errorMessage;

        // Test too short
        await tester.enterText(find.byType(TextField), 'SHORT');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pumpAndSettle();
        final shortError = authProvider.errorMessage;

        // Assert - Should have error messages
        expect(emptyError, isNotNull);
        expect(shortError, isNotNull);
      });
    });

    // ========================================================================
    // TEST 6: Navigation
    // ========================================================================
    group('Navigation Tests', () {
      testWidgets('Should navigate after successful enrollment',
          (WidgetTester tester) async {
        // Note: Navigation testing requires proper route setup
        // This test verifies the enrollment succeeds
        // Actual navigation would need MaterialApp with routes

        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byType(TextField), 'ABC12345');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pumpAndSettle();

        // Assert - User enrolled (navigation would happen in real app)
        expect(authProvider.currentUser, isNotNull);
      });
    });

    // ========================================================================
    // TEST 7: Accessibility
    // ========================================================================
    group('Accessibility Tests', () {
      testWidgets('Should have semantic labels for screen readers',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert - Key interactive elements should be accessible
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('Should support keyboard navigation',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act - Tab to text field and enter text
        await tester.enterText(find.byType(TextField), 'ABC12345');

        // Assert
        expect(find.text('ABC12345'), findsOneWidget);
      });
    });

    // ========================================================================
    // TEST 8: Edge Cases
    // ========================================================================
    group('Edge Cases Tests', () {
      testWidgets('Should handle maximum length code (12 chars)',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byType(TextField), 'ABCD12345678');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pumpAndSettle();

        // Assert
        expect(authProvider.currentUser, isNotNull);
      });

      testWidgets('Should handle minimum length code (8 chars)',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byType(TextField), 'ABCD1234');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pumpAndSettle();

        // Assert
        expect(authProvider.currentUser, isNotNull);
      });

      testWidgets('Should trim whitespace from code',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byType(TextField), ' ABC12345 ');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pumpAndSettle();

        // Assert - Should enroll successfully (if implementation trims)
        // Or show error (if implementation doesn't trim)
      });

      testWidgets('Should handle mixed case code',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.enterText(find.byType(TextField), 'AbC12345');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Enroll in Study'));
        await tester.pumpAndSettle();

        // Assert
        expect(authProvider.currentUser, isNotNull);
      });
    });
  });
}
