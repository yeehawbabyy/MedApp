# Phase 1 Validation Test Suite

**Purpose:** Automated tests to validate your Phase 1 implementations
**Total Tests:** 78+ comprehensive tests across all layers

---

## 📋 Test Structure

```
test/
├── widget_test.dart                     # Main test runner (run this!)
├── models/
│   └── user_model_test.dart            # 18 tests - Model serialization
├── services/
│   └── auth_service_test.dart          # 25+ tests - Database operations
├── providers/
│   └── auth_provider_test.dart         # 20+ tests - State management
└── screens/
    └── enrollment_screen_test.dart     # 15+ tests - UI integration
```

---

## 🚀 Running Tests

### Run All Tests
```bash
# From project root
flutter test

# With verbose output
flutter test --verbose

# See which tests pass/fail
flutter test --reporter expanded
```

### Run Specific Test File
```bash
# Model tests only
flutter test test/models/user_model_test.dart

# Service tests only
flutter test test/services/auth_service_test.dart

# Provider tests only
flutter test test/providers/auth_provider_test.dart

# Widget tests only
flutter test test/screens/enrollment_screen_test.dart
```

### Run Tests with Coverage
```bash
# Generate coverage report
flutter test --coverage

# View coverage in terminal (requires lcov)
lcov --list coverage/lcov.info

# Generate HTML coverage report (requires genhtml)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
# OR
start coverage/html/index.html # Windows
```

---

## 📊 Expected Results

After completing Phase 1 correctly, you should see:

```
✓ 🧪 Phase 1 Complete Validation Suite
  ✓ 📦 Model Tests (18 tests)
    ✓ toMap() Tests (3 tests)
    ✓ fromMap() Tests (3 tests)
    ✓ Round-trip Serialization Tests (1 test)
    ✓ copyWith() Tests (3 tests)
    ✓ Helper Methods Tests (5 tests)

  ✓ 🗄️ Service Tests (25+ tests)
    ✓ saveUser() Tests (2 tests)
    ✓ getCurrentUser() Tests (3 tests)
    ✓ updateConsentStatus() Tests (3 tests)
    ✓ updateTutorialStatus() Tests (2 tests)
    ✓ validateEnrollmentCode() Tests (7 tests)
    ✓ isUserEnrolled() Tests (3 tests)
    ✓ Integration Tests (1 test)

  ✓ 🔄 Provider Tests (20+ tests)
    ✓ Initial State Tests (3 tests)
    ✓ loadCurrentUser() Tests (3 tests)
    ✓ enrollUser() Tests (8 tests)
    ✓ acceptConsent() Tests (5 tests)
    ✓ completeTutorial() Tests (4 tests)
    ✓ State Management Tests (3 tests)
    ✓ Integration Tests (3 tests)

  ✓ 📱 Widget Tests (15+ tests)
    ✓ UI Rendering Tests (4 tests)
    ✓ Form Validation Tests (3 tests)
    ✓ Provider Integration Tests (3 tests)
    ✓ Loading State Tests (3 tests)
    ✓ Error Handling Tests (2 tests)
    ✓ Navigation Tests (1 test)
    ✓ Accessibility Tests (2 tests)
    ✓ Edge Cases Tests (4 tests)

All tests passed! (78+ tests) ✅
```

---

## ❌ Common Test Failures

### 1. UnimplementedError

**Error:**
```
UnimplementedError: toMap() not implemented yet
```

**Cause:** You haven't implemented the TODO method yet

**Solution:**
- Find the method marked with `TODO`
- Implement it according to the assignment instructions
- See `assignments/PHASE_1_AUTHENTICATION.md` for guidance

---

### 2. Column Name Mismatch

**Error:**
```
SqliteException(1): no such column: studyId
```

**Cause:** Using camelCase instead of snake_case for database columns

**Solution:**
```dart
❌ Wrong
return {
  'studyId': studyId,  // Wrong!
};

✅ Correct
return {
  'study_id': studyId,  // Matches database
};
```

**Reference:** `docs/DATABASE_GUIDE.md` Section 3

---

### 3. Boolean Type Conversion

**Error:**
```
type 'int' is not a subtype of type 'bool'
```

**Cause:** SQLite stores booleans as integers (0/1)

**Solution:**
```dart
❌ Wrong
'consent_accepted': consentAccepted,  // bool to database

✅ Correct
'consent_accepted': consentAccepted ? 1 : 0,  // bool to int

// When reading from database:
❌ Wrong
consentAccepted: map['consent_accepted'] as bool,

✅ Correct
consentAccepted: map['consent_accepted'] == 1,  // int to bool
```

**Reference:** `docs/DATABASE_GUIDE.md` Section 5

---

### 4. DateTime Serialization

**Error:**
```
type 'String' is not a subtype of type 'DateTime'
```

**Cause:** DateTime must be converted to/from ISO8601 strings for database

**Solution:**
```dart
❌ Wrong
'enrolled_at': enrolledAt,  // DateTime to database

✅ Correct
'enrolled_at': enrolledAt.toIso8601String(),  // DateTime to String

// When reading from database:
❌ Wrong
enrolledAt: map['enrolled_at'] as DateTime,

✅ Correct
enrolledAt: DateTime.parse(map['enrolled_at'] as String),
```

**Reference:** `docs/DATABASE_GUIDE.md` Section 5

---

### 5. Null Safety Issues

**Error:**
```
Null check operator used on a null value
```

**Cause:** Using `!` on a nullable value without checking

**Solution:**
```dart
❌ Wrong
await authService.updateConsentStatus(_currentUser!.studyId, true);

✅ Correct
if (_currentUser != null) {
  await authService.updateConsentStatus(_currentUser!.studyId, true);
}

// Or
final user = _currentUser;
if (user == null) {
  _errorMessage = 'No user enrolled';
  return;
}
await authService.updateConsentStatus(user.studyId, true);
```

**Reference:** `docs/COMMON_ERRORS.md` Section 6

---

### 6. Missing notifyListeners()

**Error:**
```
Expected currentUser to be <UserModel>, but was <null>
```

**Cause:** Provider not notifying listeners after state change

**Solution:**
```dart
❌ Wrong
Future<void> enrollUser(String code) async {
  _currentUser = await _authService.saveUser(...);
  // Missing notifyListeners()!
}

✅ Correct
Future<void> enrollUser(String code) async {
  _isLoading = true;
  notifyListeners();  // Notify loading started

  _currentUser = await _authService.saveUser(...);

  _isLoading = false;
  notifyListeners();  // Notify loading finished
}
```

**Reference:** `assignments/PHASE_1_AUTHENTICATION.md` Task 2.3

---

## 🔍 Understanding Test Output

### Test Passed ✓
```
✓ Should convert model to map with all fields
```
**Meaning:** Your implementation is correct! 🎉

### Test Failed ✗
```
✗ Should convert model to map with all fields
  Expected: 'STUDY123'
  Actual: null
  test/models/user_model_test.dart:35
```

**How to Fix:**
1. Open the file: `test/models/user_model_test.dart`
2. Go to line: 35
3. Read the test to understand what's expected
4. Fix your implementation to match the expectation
5. Run test again

---

## 📈 Test-Driven Development Flow

**Recommended Approach:**

1. **Read Assignment** → `assignments/PHASE_1_AUTHENTICATION.md`

2. **Run Tests First** (they will fail - that's OK!)
   ```bash
   flutter test test/models/user_model_test.dart
   ```

3. **Implement One Method**
   - Read the TODO comment
   - Look at the example method
   - Implement your method

4. **Run Tests Again**
   ```bash
   flutter test test/models/user_model_test.dart
   ```

5. **Fix Errors** until tests pass

6. **Repeat** for next method

7. **Run All Tests** when done
   ```bash
   flutter test
   ```

---

## 🎯 Test Categories Explained

### Unit Tests (Models, Services)
- Test individual methods in isolation
- No UI, no user interaction
- Fast execution
- Use AAA pattern: Arrange, Act, Assert

**Example:**
```dart
test('Should convert model to map', () {
  // Arrange - Set up test data
  final user = UserModel(studyId: 'TEST');

  // Act - Call the method
  final map = user.toMap();

  // Assert - Verify result
  expect(map['study_id'], 'TEST');
});
```

### Integration Tests (Services)
- Test multiple components working together
- Example: AuthService + DatabaseService
- Verify complete workflows

### Widget Tests (Screens)
- Test UI components
- Simulate user interactions (tap, type, scroll)
- Verify UI updates correctly

**Example:**
```dart
testWidgets('Should display enrollment button', (tester) async {
  // Arrange - Build widget
  await tester.pumpWidget(MyWidget());

  // Act - Find button
  final button = find.text('Enroll in Study');

  // Assert - Verify it exists
  expect(button, findsOneWidget);
});
```

---

## 📚 Additional Resources

### Documentation
- **Testing Guide:** `docs/TESTING_GUIDE.md`
- **Common Errors:** `docs/COMMON_ERRORS.md`
- **Database Guide:** `docs/DATABASE_GUIDE.md`
- **Assignment:** `assignments/PHASE_1_AUTHENTICATION.md`

### Official Documentation
- [Flutter Testing](https://flutter.dev/docs/testing)
- [Widget Testing](https://flutter.dev/docs/cookbook/testing/widget/introduction)
- [Unit Testing](https://flutter.dev/docs/cookbook/testing/unit/introduction)

---

## 💡 Tips for Success

### 1. Run Tests Frequently
Don't wait until you've implemented everything. Run tests after each method!

### 2. Read Test Names
Test names describe what should happen:
```dart
test('Should convert model to map with all fields')
test('Should reject code shorter than 8 characters')
```

### 3. Use Verbose Mode
See which test is running:
```bash
flutter test --verbose
```

### 4. Focus on One Test at a Time
```bash
# Run just one test file
flutter test test/models/user_model_test.dart
```

### 5. Read the Error Messages
Flutter test errors tell you:
- **What** was expected
- **What** actually happened
- **Where** the problem is (file and line)

### 6. Use Print Statements
Add prints to your implementation to debug:
```dart
Map<String, dynamic> toMap() {
  print('Converting to map: studyId = $studyId');
  return {
    'study_id': studyId,
  };
}
```

### 7. Check Example Methods
Look at already-implemented methods like `saveUser()` and `loadCurrentUser()`

---

## 🎓 Grading

Tests are worth **30 points** in Phase 1 grading:

| Criteria | Points | How to Verify |
|----------|--------|---------------|
| All tests pass | 20 | Run `flutter test` |
| No skipped tests | 5 | Check output for `skip` |
| Code coverage >80% | 5 | Run with `--coverage` |

**Note:** Even if some tests fail, you get partial credit for passing tests!

---

## 🆘 Getting Help

### Before Asking for Help

1. Read the error message completely
2. Check `docs/COMMON_ERRORS.md` for the error
3. Review the relevant guide (`DATABASE_GUIDE.md`, `TESTING_GUIDE.md`)
4. Look at example implementations in the codebase
5. Try adding print statements to debug

### When Asking for Help

Provide:
1. **Error message** (complete, not just first line)
2. **Test that's failing** (name and file)
3. **Your implementation** (code you wrote)
4. **What you tried** to fix it

---

## ✅ Test Completion Checklist

- [ ] All model tests passing (18 tests)
- [ ] All service tests passing (25+ tests)
- [ ] All provider tests passing (20+ tests)
- [ ] All widget tests passing (15+ tests)
- [ ] Total tests passing: 78+
- [ ] No skipped tests
- [ ] No test warnings
- [ ] Code coverage >80%

---

**Remember:** Tests are your friends! They tell you exactly what's wrong and guide you to the solution. 🎯

Good luck! 🚀
