# Testing Guide for Students

**Purpose:** Learn how to write and run tests in Flutter
**Types:** Unit Tests, Widget Tests, Integration Tests

---

## 📋 Table of Contents

1. [Why Test?](#why-test)
2. [Types of Tests](#types-of-tests)
3. [Unit Testing](#unit-testing)
4. [Widget Testing](#widget-testing)
5. [Running Tests](#running-tests)
6. [Testing Best Practices](#testing-best-practices)
7. [Common Testing Patterns](#common-testing-patterns)

---

## 1. Why Test?

### Benefits of Testing

✅ **Catch bugs early** - Before users find them
✅ **Confidence in changes** - Know code still works after modifications
✅ **Documentation** - Tests show how code should work
✅ **Better design** - Testable code is usually better code
✅ **Faster development** - Less manual testing needed

### Testing Pyramid

```
      ┌─────────────┐
      │     E2E     │  5% - Slow, expensive
      │ (Integration)│
      └─────────────┘
    ┌──────────────────┐
    │  Widget Tests    │  25% - Medium speed
    └──────────────────┘
  ┌──────────────────────┐
  │     Unit Tests       │  70% - Fast, cheap
  └──────────────────────┘
```

**Our Focus:** Unit Tests (70%) and Widget Tests (25%)

---

## 2. Types of Tests

### Unit Tests
- Test individual functions/methods
- Fast and isolated
- No UI, no database, no network
- Example: Test UserModel.toMap() method

### Widget Tests
- Test UI components
- Interact with widgets
- Verify UI behavior
- Example: Test enrollment screen shows error message

### Integration Tests
- Test complete user flows
- Slow but comprehensive
- Example: Complete enrollment from start to finish

---

## 3. Unit Testing

### Setting Up

**File Structure:**
```
test/
└── features/
    └── authentication/
        ├── models/
        │   └── user_model_test.dart
        └── services/
            └── auth_service_test.dart
```

**Naming:** Same as source file but with `_test.dart` suffix

### Basic Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:med_pharm_app/features/authentication/models/user_model.dart';

void main() {
  // group() organizes related tests
  group('UserModel Tests', () {

    // test() defines a single test case
    test('toMap should convert UserModel to Map', () {
      // 1. ARRANGE - Set up test data
      final user = UserModel(
        studyId: 'TEST123',
        enrollmentCode: 'ABC12345',
        enrolledAt: DateTime(2024, 11, 6),
      );

      // 2. ACT - Perform the action
      final map = user.toMap();

      // 3. ASSERT - Verify the result
      expect(map['study_id'], 'TEST123');
      expect(map['enrollment_code'], 'ABC12345');
      expect(map['consent_accepted'], 0);
    });

    test('fromMap should create UserModel from Map', () {
      // Arrange
      final map = {
        'id': 1,
        'study_id': 'TEST123',
        'enrollment_code': 'ABC12345',
        'enrolled_at': '2024-11-06T10:00:00.000Z',
        'consent_accepted': 1,
        'consent_accepted_at': null,
        'tutorial_completed': 0,
      };

      // Act
      final user = UserModel.fromMap(map);

      // Assert
      expect(user.id, 1);
      expect(user.studyId, 'TEST123');
      expect(user.consentAccepted, true);  // 1 → true
    });
  });
}
```

### Common Assertions

```dart
// Equality
expect(actual, expected);
expect(2 + 2, 4);

// Boolean
expect(isValid, isTrue);
expect(hasError, isFalse);

// Null checking
expect(value, isNull);
expect(value, isNotNull);

// Type checking
expect(value, isA<String>());
expect(user, isA<UserModel>());

// Collections
expect(list, isEmpty);
expect(list, isNotEmpty);
expect(list, contains('item'));
expect(list.length, 3);

// Exceptions
expect(() => functionThatThrows(), throwsException);
expect(() => functionThatThrows(), throwsA(isA<ArgumentError>()));
```

### Testing Async Methods

```dart
test('saveUser should save to database', () async {
  // Arrange
  final user = UserModel(...);

  // Act
  await authService.saveUser(user);  // Note: await

  // Assert
  final saved = await authService.getCurrentUser();
  expect(saved, isNotNull);
  expect(saved!.studyId, user.studyId);
});
```

### Example: UserModel Tests

```dart
// test/features/authentication/models/user_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:med_pharm_app/features/authentication/models/user_model.dart';

void main() {
  group('UserModel', () {
    group('toMap', () {
      test('converts all fields correctly', () {
        final user = UserModel(
          studyId: 'TEST123',
          enrollmentCode: 'ABC12345',
          enrolledAt: DateTime(2024, 11, 6),
          consentAccepted: true,
          consentAcceptedAt: DateTime(2024, 11, 7),
          tutorialCompleted: false,
        );

        final map = user.toMap();

        expect(map['study_id'], 'TEST123');
        expect(map['enrollment_code'], 'ABC12345');
        expect(map['consent_accepted'], 1);  // true → 1
        expect(map['tutorial_completed'], 0);  // false → 0
      });

      test('handles null id correctly', () {
        final user = UserModel(
          studyId: 'TEST123',
          enrollmentCode: 'ABC12345',
          enrolledAt: DateTime.now(),
        );

        final map = user.toMap();

        expect(map.containsKey('id'), isFalse);  // Should not include null id
      });

      test('converts DateTime to ISO8601 string', () {
        final date = DateTime(2024, 11, 6, 10, 30, 0);
        final user = UserModel(
          studyId: 'TEST123',
          enrollmentCode: 'ABC12345',
          enrolledAt: date,
        );

        final map = user.toMap();

        expect(map['enrolled_at'], '2024-11-06T10:30:00.000');
      });
    });

    group('fromMap', () {
      test('creates UserModel from Map', () {
        final map = {
          'id': 1,
          'study_id': 'TEST123',
          'enrollment_code': 'ABC12345',
          'enrolled_at': '2024-11-06T10:00:00.000Z',
          'consent_accepted': 1,
          'consent_accepted_at': '2024-11-07T11:00:00.000Z',
          'tutorial_completed': 0,
        };

        final user = UserModel.fromMap(map);

        expect(user.id, 1);
        expect(user.studyId, 'TEST123');
        expect(user.enrollmentCode, 'ABC12345');
        expect(user.consentAccepted, true);
        expect(user.tutorialCompleted, false);
        expect(user.consentAcceptedAt, isNotNull);
      });

      test('handles null values correctly', () {
        final map = {
          'study_id': 'TEST123',
          'enrollment_code': 'ABC12345',
          'enrolled_at': '2024-11-06T10:00:00.000Z',
          'consent_accepted': 0,
          'consent_accepted_at': null,
          'tutorial_completed': 0,
        };

        final user = UserModel.fromMap(map);

        expect(user.id, isNull);
        expect(user.consentAcceptedAt, isNull);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = UserModel(
          studyId: 'TEST123',
          enrollmentCode: 'ABC12345',
          enrolledAt: DateTime.now(),
          consentAccepted: false,
        );

        final updated = original.copyWith(consentAccepted: true);

        expect(original.consentAccepted, false);  // Original unchanged
        expect(updated.consentAccepted, true);  // New copy updated
        expect(updated.studyId, 'TEST123');  // Other fields preserved
      });

      test('preserves fields when not provided', () {
        final original = UserModel(
          studyId: 'TEST123',
          enrollmentCode: 'ABC12345',
          enrolledAt: DateTime.now(),
        );

        final copy = original.copyWith();  // No changes

        expect(copy.studyId, original.studyId);
        expect(copy.enrollmentCode, original.enrollmentCode);
      });
    });

    group('helper methods', () {
      test('hasCompletedOnboarding returns true when both consent and tutorial done', () {
        final user = UserModel(
          studyId: 'TEST123',
          enrollmentCode: 'ABC12345',
          enrolledAt: DateTime.now(),
          consentAccepted: true,
          tutorialCompleted: true,
        );

        expect(user.hasCompletedOnboarding, isTrue);
      });

      test('hasCompletedOnboarding returns false when only consent done', () {
        final user = UserModel(
          studyId: 'TEST123',
          enrollmentCode: 'ABC12345',
          enrolledAt: DateTime.now(),
          consentAccepted: true,
          tutorialCompleted: false,
        );

        expect(user.hasCompletedOnboarding, isFalse);
      });
    });
  });
}
```

---

## 4. Widget Testing

### Basic Widget Test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_pharm_app/features/authentication/screens/enrollment_screen.dart';

void main() {
  testWidgets('EnrollmentScreen displays title', (tester) async {
    // 1. ARRANGE - Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: EnrollmentScreen(),
      ),
    );

    // 2. ACT - (Optional) Interact with widget
    // (No interaction needed for this test)

    // 3. ASSERT - Verify widget exists
    expect(find.text('Welcome to MedPharm'), findsOneWidget);
    expect(find.byIcon(Icons.medical_services), findsOneWidget);
  });
}
```

### Widget Test with Provider

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:med_pharm_app/features/authentication/providers/auth_provider.dart';
import 'package:med_pharm_app/features/authentication/screens/enrollment_screen.dart';

void main() {
  testWidgets('Shows loading indicator when enrolling', (tester) async {
    // Create a mock provider
    final authProvider = AuthProvider(mockAuthService);

    // Build widget with provider
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: authProvider,
          child: EnrollmentScreen(),
        ),
      ),
    );

    // Simulate loading state
    authProvider.enrollUser('ABC12345');

    // Rebuild widget to show loading
    await tester.pump();

    // Verify loading indicator appears
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

### Finding Widgets

```dart
// By text
expect(find.text('Hello'), findsOneWidget);

// By type
expect(find.byType(ElevatedButton), findsOneWidget);
expect(find.byType(TextField), findsNWidgets(2));

// By icon
expect(find.byIcon(Icons.home), findsOneWidget);

// By key
expect(find.byKey(Key('my-button')), findsOneWidget);

// By widget
final widget = ElevatedButton(child: Text('Click'), onPressed: () {});
expect(find.byWidget(widget), findsOneWidget);

// Assertions
findsOneWidget    // Exactly 1 widget found
findsNothing      // 0 widgets found
findsNWidgets(3)  // Exactly 3 widgets found
findsAtLeastNWidgets(2)  // 2 or more widgets found
findsWidgets      // At least 1 widget found
```

### Interacting with Widgets

```dart
// Tap
await tester.tap(find.text('Submit'));
await tester.pump();  // Rebuild after tap

// Enter text
await tester.enterText(find.byType(TextField), 'ABC12345');
await tester.pump();

// Scroll
await tester.drag(find.byType(ListView), Offset(0, -200));
await tester.pump();

// Long press
await tester.longPress(find.text('Item'));
await tester.pump();
```

### Pump Methods

```dart
// pump() - Trigger one frame rebuild
await tester.pump();

// pumpAndSettle() - Trigger frames until settled (animations complete)
await tester.pumpAndSettle();

// pump(Duration) - Trigger frame after duration
await tester.pump(Duration(seconds: 1));
```

---

## 5. Running Tests

### Run All Tests

```bash
# Run all tests
flutter test

# Output:
# 00:01 +5: All tests passed!
```

### Run Specific Test File

```bash
# Run single file
flutter test test/features/authentication/models/user_model_test.dart

# Run all tests in a directory
flutter test test/features/authentication/
```

### Run with Coverage

```bash
# Generate coverage report
flutter test --coverage

# View coverage (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Watch Mode (Auto-run on changes)

```bash
# Install
flutter pub global activate test_watcher

# Run
test_watcher
```

---

## 6. Testing Best Practices

### ✅ DO: Follow AAA Pattern

```dart
test('description', () {
  // ARRANGE - Set up test data
  final user = UserModel(...);

  // ACT - Perform the action
  final map = user.toMap();

  // ASSERT - Verify the result
  expect(map['study_id'], 'TEST123');
});
```

### ✅ DO: One Assertion Per Test

```dart
✅ Good - Focused tests
test('toMap converts studyId correctly', () {
  final user = UserModel(studyId: 'TEST123', ...);
  final map = user.toMap();
  expect(map['study_id'], 'TEST123');
});

test('toMap converts consentAccepted correctly', () {
  final user = UserModel(consentAccepted: true, ...);
  final map = user.toMap();
  expect(map['consent_accepted'], 1);
});

❌ Bad - Multiple unrelated assertions
test('toMap converts everything', () {
  final map = user.toMap();
  expect(map['study_id'], 'TEST123');
  expect(map['consent_accepted'], 1);
  expect(map['tutorial_completed'], 0);
  // If first one fails, we don't know if others work
});
```

### ✅ DO: Use Descriptive Test Names

```dart
✅ Good - Clear what's being tested
test('validateEnrollmentCode returns false for empty string', () { });
test('validateEnrollmentCode returns false for code shorter than 8 chars', () { });
test('validateEnrollmentCode returns true for valid 8-12 character code', () { });

❌ Bad - Vague names
test('test1', () { });
test('validation works', () { });
test('returns false', () { });
```

### ✅ DO: Test Edge Cases

```dart
group('validateEnrollmentCode', () {
  test('returns false for empty string', () { });
  test('returns false for null', () { });
  test('returns false for code with 7 chars', () { });  // Just under minimum
  test('returns true for code with 8 chars', () { });   // Exactly minimum
  test('returns true for code with 12 chars', () { });  // Exactly maximum
  test('returns false for code with 13 chars', () { }); // Just over maximum
  test('returns false for code with special characters', () { });
  test('returns false for code with spaces', () { });
  test('returns true for code with uppercase letters', () { });
  test('returns true for code with lowercase letters', () { });
  test('returns true for code with numbers', () { });
  test('returns true for mixed alphanumeric', () { });
});
```

### ❌ DON'T: Test Implementation Details

```dart
❌ Bad - Testing private methods
test('_validateFormat works', () {
  // Don't test private methods directly
  // Test public methods that use them
});

✅ Good - Test public interface
test('validateEnrollmentCode validates format', () {
  // Public method that uses _validateFormat
});
```

---

## 7. Common Testing Patterns

### Pattern 1: Setup and Teardown

```dart
group('AuthService', () {
  late AuthService authService;
  late DatabaseService databaseService;

  // Run before each test
  setUp(() {
    databaseService = DatabaseService();
    authService = AuthService(databaseService);
  });

  // Run after each test
  tearDown(() async {
    await databaseService.deleteDatabase();
    await databaseService.close();
  });

  test('saves user correctly', () {
    // authService is fresh for each test
  });

  test('loads user correctly', () {
    // authService is fresh for this test too
  });
});
```

### Pattern 2: Testing Exceptions

```dart
test('throws ArgumentError for empty code', () {
  expect(
    () => validateCode(''),
    throwsA(isA<ArgumentError>()),
  );
});

test('throws specific error message', () {
  expect(
    () => validateCode(''),
    throwsA(
      predicate((e) =>
        e is ArgumentError &&
        e.message == 'Code cannot be empty'
      ),
    ),
  );
});
```

### Pattern 3: Testing Async Completion

```dart
test('async method completes', () async {
  // Use expectLater for async assertions
  await expectLater(
    authService.saveUser(user),
    completes,  // Completes without error
  );
});

test('async method throws', () async {
  await expectLater(
    authService.saveUser(null),
    throwsException,
  );
});
```

### Pattern 4: Testing State Changes

```dart
testWidgets('button press updates state', (tester) async {
  final provider = AuthProvider(mockService);

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(home: MyWidget()),
    ),
  );

  // Initial state
  expect(provider.isLoading, false);

  // Trigger action
  await tester.tap(find.text('Load'));
  await tester.pump();

  // State changed
  expect(provider.isLoading, true);
});
```

---

## 🎓 Practice Exercises

### Exercise 1: Test Auth Service Validation

Write tests for `validateEnrollmentCode()`:
- Empty string
- Too short (< 8)
- Too long (> 12)
- With special characters
- Valid code

### Exercise 2: Test UserModel copyWith

Write tests for `copyWith()`:
- Updates single field
- Updates multiple fields
- Preserves unchanged fields
- Handles nullable fields

### Exercise 3: Test Widget Error Display

Write a widget test that verifies error message displays when enrollment fails.

---

## 📚 Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Flutter Test Package](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html)
- [Testing Best Practices](https://docs.flutter.dev/testing/best-practices)

---

## 🏆 Testing Checklist

Before submitting code, verify:

- [ ] All public methods have at least one test
- [ ] Edge cases tested (null, empty, boundaries)
- [ ] Error cases tested (exceptions, failures)
- [ ] Tests follow AAA pattern
- [ ] Tests have descriptive names
- [ ] All tests pass: `flutter test`
- [ ] Coverage > 70%: `flutter test --coverage`

---

**Remember:** Good tests make you confident in your code. Test early, test often! 🧪✅
