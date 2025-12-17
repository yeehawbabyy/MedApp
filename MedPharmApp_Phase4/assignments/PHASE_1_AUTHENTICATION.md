# Phase 1 Assignment: User Authentication & Enrollment

**Course:** Mobile Apps in Surgery and Medicine 4.0
**Institution:** AGH University of Science and Technology
**Lab:** Lab 3 - Clinical Trial Application Development
**Phase:** 1 of 3
**Difficulty:** ⭐⭐ Intermediate
**Scaffolding Level:** 80% complete - Learn by filling in TODOs
**Estimated Time:** 8-12 hours (including testing and debugging)

---

## 📚 Learning Objectives

By completing this assignment, you will learn to:

1. ✅ Implement data models with serialization (toMap/fromMap)
2. ✅ Create service classes for database operations
3. ✅ Build providers for state management using Provider package
4. ✅ Connect UI to providers (Consumer, context.read/watch)
5. ✅ Handle async operations with proper error handling
6. ✅ Validate user input
7. ✅ Navigate between screens
8. ✅ Follow the feature-first architecture pattern

---

## 📋 Prerequisites

Before starting, ensure you have:

- [ ] Read `ARCHITECTURE_GUIDE.md` (especially sections 1-7)
- [ ] Run `flutter pub get` successfully
- [ ] App runs without errors (even if incomplete)
- [ ] Understood the example methods in the code
- [ ] SQLite database basics (CREATE, INSERT, UPDATE, SELECT)

---

## 🎯 Assignment Overview

You will implement the **User Authentication** feature, which includes:

1. **User enrollment** with enrollment code
2. **Informed consent** acceptance
3. **Data persistence** in SQLite database
4. **State management** with Provider
5. **Navigation** between screens

**What's Provided (80%):**
- Complete database setup
- Full UI layouts
- Example implementations
- Detailed TODO comments

**What You'll Implement (20%):**
- Model serialization methods
- Service database operations
- Provider state management
- UI-Provider connections

---

## 📝 Tasks Breakdown

### Task 1: Implement UserModel (3 methods)

**File:** `lib/features/authentication/models/user_model.dart`

**Priority:** ⭐⭐⭐ (Start here - easiest)

#### Task 1.1: Implement `toMap()` Method

**Purpose:** Convert UserModel object to Map for database storage

**Steps:**

1. Open `user_model.dart`
2. Find the `toMap()` method (line ~70)
3. Return a Map with these keys (matching database columns):
   - `'study_id'`: studyId
   - `'enrollment_code'`: enrollmentCode
   - `'enrolled_at'`: enrolledAt.toIso8601String()
   - `'consent_accepted'`: consentAccepted ? 1 : 0
   - `'consent_accepted_at'`: consentAcceptedAt?.toIso8601String()
   - `'tutorial_completed'`: tutorialCompleted ? 1 : 0

**Hints:**
- Don't include 'id' if it's null (database auto-generates it)
- SQLite stores booleans as integers (1 = true, 0 = false)
- DateTime must be converted to String

**Example:**
```dart
Map<String, dynamic> toMap() {
  final map = <String, dynamic>{
    'study_id': studyId,
    'enrollment_code': enrollmentCode,
    // ... add other fields
  };

  // Only include id if it's not null
  if (id != null) {
    map['id'] = id;
  }

  return map;
}
```

**Testing:**
```dart
final user = UserModel(
  studyId: 'TEST123',
  enrollmentCode: 'ABC12345',
  enrolledAt: DateTime.now(),
);
print(user.toMap()); // Should print all fields
```

**Acceptance Criteria:**
- [ ] Returns Map<String, dynamic>
- [ ] All required fields included
- [ ] Booleans converted to int (0 or 1)
- [ ] DateTime converted to ISO8601 string
- [ ] id only included if not null
- [ ] No errors when called

---

#### Task 1.2: Implement `fromMap()` Factory Constructor

**Purpose:** Create UserModel from database Map

**Steps:**

1. Find `fromMap()` method (line ~106)
2. Extract values from map and convert types:
   - `map['id'] as int?` for nullable int
   - `map['study_id'] as String` for required string
   - `DateTime.parse(map['enrolled_at'])` for DateTime
   - `map['consent_accepted'] == 1` for boolean
   - Handle nullable DateTime: `map['consent_accepted_at'] != null ? DateTime.parse(...) : null`

**Example:**
```dart
factory UserModel.fromMap(Map<String, dynamic> map) {
  return UserModel(
    id: map['id'] as int?,
    studyId: map['study_id'] as String,
    enrollmentCode: map['enrollment_code'] as String,
    enrolledAt: DateTime.parse(map['enrolled_at'] as String),
    consentAccepted: map['consent_accepted'] == 1,
    consentAcceptedAt: map['consent_accepted_at'] != null
        ? DateTime.parse(map['consent_accepted_at'] as String)
        : null,
    tutorialCompleted: map['tutorial_completed'] == 1,
  );
}
```

**Testing:**
```dart
final map = {
  'id': 1,
  'study_id': 'TEST123',
  'enrollment_code': 'ABC12345',
  'enrolled_at': '2024-11-06T10:00:00.000Z',
  'consent_accepted': 1,
  'consent_accepted_at': null,
  'tutorial_completed': 0,
};
final user = UserModel.fromMap(map);
print(user); // Should create valid UserModel
```

**Acceptance Criteria:**
- [ ] Creates UserModel from Map
- [ ] All fields correctly extracted
- [ ] Type conversions work (String→DateTime, int→bool)
- [ ] Handles nullable fields correctly
- [ ] No errors when parsing valid map

---

#### Task 1.3: Implement `copyWith()` Method

**Purpose:** Create a modified copy of UserModel

**Steps:**

1. Find `copyWith()` method (line ~151)
2. For each parameter, use the null-aware operator:
   - `parameterName ?? this.parameterName`
3. Return new UserModel with updated values

**Example:**
```dart
UserModel copyWith({
  int? id,
  String? studyId,
  // ... other parameters
}) {
  return UserModel(
    id: id ?? this.id,
    studyId: studyId ?? this.studyId,
    enrollmentCode: enrollmentCode ?? this.enrollmentCode,
    // ... other fields
  );
}
```

**Testing:**
```dart
final user = UserModel(
  studyId: 'TEST123',
  enrollmentCode: 'ABC12345',
  enrolledAt: DateTime.now(),
  consentAccepted: false,
);

final updated = user.copyWith(consentAccepted: true);
print(user.consentAccepted);    // false (original unchanged)
print(updated.consentAccepted); // true (new copy)
```

**Acceptance Criteria:**
- [ ] Returns new UserModel instance
- [ ] Original object unchanged (immutability)
- [ ] Updated fields use new values
- [ ] Unchanged fields keep original values
- [ ] Works with nullable fields

---

### Task 2: Implement AuthService (5 methods)

**File:** `lib/features/authentication/services/auth_service.dart`

**Priority:** ⭐⭐ (Do after UserModel)

**Pattern:** Study the `saveUser()` example method (lines 49-73), then apply the same pattern.

---

#### Task 2.1: Implement `getCurrentUser()`

**Purpose:** Load current user from database

**Steps:**

1. Get database instance: `final db = await _databaseService.database;`
2. Query user_session table: `final results = await db.query('user_session', limit: 1);`
3. If results is empty, return null
4. If results has data, convert first result to UserModel and return

**Code Template:**
```dart
Future<UserModel?> getCurrentUser() async {
  try {
    final db = await _databaseService.database;

    final results = await db.query('user_session', limit: 1);

    if (results.isEmpty) {
      return null;  // No user enrolled
    }

    return UserModel.fromMap(results.first);
  } catch (e) {
    print('❌ Error getting current user: $e');
    rethrow;
  }
}
```

**Acceptance Criteria:**
- [ ] Returns UserModel? (nullable)
- [ ] Returns null if no user exists
- [ ] Returns UserModel if user exists
- [ ] Uses try-catch for error handling
- [ ] Calls UserModel.fromMap()

---

#### Task 2.2: Implement `updateConsentStatus()`

**Purpose:** Mark consent as accepted

**Steps:**

1. Get database instance
2. Update user_session table:
   ```dart
   await db.update(
     'user_session',
     {
       'consent_accepted': 1,
       'consent_accepted_at': DateTime.now().toIso8601String(),
     },
     where: 'study_id = ?',
     whereArgs: [studyId],
   );
   ```
3. Return number of rows updated

**Code Template:**
```dart
Future<int> updateConsentStatus(String studyId) async {
  try {
    final db = await _databaseService.database;

    final rowsUpdated = await db.update(
      'user_session',
      {
        'consent_accepted': 1,
        'consent_accepted_at': DateTime.now().toIso8601String(),
      },
      where: 'study_id = ?',
      whereArgs: [studyId],
    );

    return rowsUpdated;
  } catch (e) {
    print('❌ Error updating consent: $e');
    rethrow;
  }
}
```

**Acceptance Criteria:**
- [ ] Updates consent_accepted to 1
- [ ] Sets consent_accepted_at to current time
- [ ] Uses WHERE clause with study_id
- [ ] Returns number of rows updated
- [ ] Error handling with try-catch

---

#### Task 2.3: Implement `updateTutorialStatus()`

**Purpose:** Mark tutorial as completed

**Steps:**

1. Similar to updateConsentStatus()
2. Update tutorial_completed field to 1

**Code Template:**
```dart
Future<int> updateTutorialStatus(String studyId) async {
  try {
    final db = await _databaseService.database;

    return await db.update(
      'user_session',
      {'tutorial_completed': 1},
      where: 'study_id = ?',
      whereArgs: [studyId],
    );
  } catch (e) {
    print('❌ Error updating tutorial: $e');
    rethrow;
  }
}
```

**Acceptance Criteria:**
- [ ] Updates tutorial_completed to 1
- [ ] Uses correct WHERE clause
- [ ] Returns number of rows updated
- [ ] Error handling included

---

#### Task 2.4: Implement `validateEnrollmentCode()`

**Purpose:** Validate enrollment code format

**Steps:**

1. Check if code is not empty
2. Check if code length is 8-12 characters
3. Check if code contains only letters and numbers (alphanumeric)

**Code Template:**
```dart
Future<bool> validateEnrollmentCode(String code) async {
  // Check if empty
  if (code.isEmpty) {
    return false;
  }

  // Check length (8-12 characters)
  if (code.length < 8 || code.length > 12) {
    return false;
  }

  // Check alphanumeric (letters and numbers only)
  final alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');
  if (!alphanumeric.hasMatch(code)) {
    return false;
  }

  return true;
}
```

**Testing:**
```dart
print(await validateEnrollmentCode(''));           // false - empty
print(await validateEnrollmentCode('ABC'));        // false - too short
print(await validateEnrollmentCode('ABC123456789123')); // false - too long
print(await validateEnrollmentCode('ABC@123'));    // false - special char
print(await validateEnrollmentCode('ABC12345'));   // true - valid!
```

**Acceptance Criteria:**
- [ ] Returns false for empty code
- [ ] Returns false if length < 8 or > 12
- [ ] Returns false for non-alphanumeric characters
- [ ] Returns true for valid codes
- [ ] No database call needed (pure validation)

---

#### Task 2.5: Implement `isUserEnrolled()`

**Purpose:** Check if any user exists in database

**Steps:**

1. Query user_session table
2. Return true if results is NOT empty

**Code Template:**
```dart
Future<bool> isUserEnrolled() async {
  try {
    final db = await _databaseService.database;
    final results = await db.query('user_session');
    return results.isNotEmpty;
  } catch (e) {
    print('❌ Error checking enrollment: $e');
    return false;
  }
}
```

**Acceptance Criteria:**
- [ ] Returns true if user exists
- [ ] Returns false if no user exists
- [ ] Error handling returns false (safe default)

---

### Task 3: Implement AuthProvider (4 methods)

**File:** `lib/features/authentication/providers/auth_provider.dart`

**Priority:** ⭐ (Do after AuthService)

**Pattern:** Study the `loadCurrentUser()` example method (lines 85-110), then apply the same pattern.

**Important:** Always follow this pattern:
1. Set loading = true, clear error, notifyListeners()
2. Do async work (call service)
3. Update state
4. Set loading = false, notifyListeners()
5. Wrap in try-catch

---

#### Task 3.1: Implement `enrollUser()`

**Purpose:** Enroll a new user with enrollment code

**Steps:**

1. Set loading state
2. Validate code using `_authService.validateEnrollmentCode()`
3. If invalid, set error and return
4. Generate study ID using `_authService.generateStudyId()`
5. Create new UserModel
6. Save using `_authService.saveUser()`
7. Update _currentUser
8. Clear loading, notify

**Code Template:**
```dart
Future<void> enrollUser(String code) async {
  try {
    // Step 1: Set loading
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Step 2: Validate code
    final isValid = await _authService.validateEnrollmentCode(code);
    if (!isValid) {
      _errorMessage = 'Invalid enrollment code format';
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Step 3: Generate study ID
    final studyId = _authService.generateStudyId(code);

    // Step 4: Create user
    final user = UserModel(
      studyId: studyId,
      enrollmentCode: code,
      enrolledAt: DateTime.now(),
    );

    // Step 5: Save user
    await _authService.saveUser(user);

    // Step 6: Update state
    _currentUser = user;

    // Step 7: Clear loading
    _isLoading = false;
    notifyListeners();
  } catch (e) {
    _isLoading = false;
    _errorMessage = 'Failed to enroll: $e';
    notifyListeners();
  }
}
```

**Acceptance Criteria:**
- [ ] Validates code before enrolling
- [ ] Creates UserModel with correct fields
- [ ] Saves to database via service
- [ ] Updates _currentUser state
- [ ] Calls notifyListeners() appropriately
- [ ] Error handling with user-friendly messages

---

#### Task 3.2: Implement `acceptConsent()`

**Purpose:** Mark consent as accepted

**Steps:**

1. Check if _currentUser is null (can't accept without user)
2. Set loading state
3. Call `_authService.updateConsentStatus()`
4. Update _currentUser using copyWith()
5. Clear loading, notify

**Code Template:**
```dart
Future<void> acceptConsent() async {
  if (_currentUser == null) return;

  try {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _authService.updateConsentStatus(_currentUser!.studyId);

    _currentUser = _currentUser!.copyWith(
      consentAccepted: true,
      consentAcceptedAt: DateTime.now(),
    );

    _isLoading = false;
    notifyListeners();
  } catch (e) {
    _isLoading = false;
    _errorMessage = 'Failed to accept consent: $e';
    notifyListeners();
  }
}
```

**Acceptance Criteria:**
- [ ] Returns early if no current user
- [ ] Calls service to update database
- [ ] Uses copyWith() to update user
- [ ] Updates both consentAccepted and consentAcceptedAt
- [ ] Proper loading states

---

#### Task 3.3: Implement `completeTutorial()`

**Purpose:** Mark tutorial as completed

**Steps:**

1. Similar to acceptConsent()
2. Update tutorial_completed instead

**Code Template:**
```dart
Future<void> completeTutorial() async {
  if (_currentUser == null) return;

  try {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _authService.updateTutorialStatus(_currentUser!.studyId);

    _currentUser = _currentUser!.copyWith(
      tutorialCompleted: true,
    );

    _isLoading = false;
    notifyListeners();
  } catch (e) {
    _isLoading = false;
    _errorMessage = 'Failed to complete tutorial: $e';
    notifyListeners();
  }
}
```

**Acceptance Criteria:**
- [ ] Updates tutorialCompleted field
- [ ] Follows the provider pattern
- [ ] Error handling included

---

#### Task 3.4: Implement `updateEnrollmentCode()`

**Purpose:** Update enrollment code as user types

**Steps:**

1. Update _enrollmentCode with new value
2. Call notifyListeners()

**Code Template:**
```dart
void updateEnrollmentCode(String code) {
  _enrollmentCode = code;
  notifyListeners();
}
```

**Acceptance Criteria:**
- [ ] Updates _enrollmentCode
- [ ] Calls notifyListeners()
- [ ] Synchronous (not async)

---

### Task 4: Connect UI to Provider (Enrollment Screen)

**File:** `lib/features/authentication/screens/enrollment_screen.dart`

**Priority:** ⭐ (Do after Provider)

---

#### Task 4.1: Implement `_handleEnrollment()`

**Purpose:** Handle "Enroll" button press

**Steps:**

1. Validate form
2. Get AuthProvider
3. Call enrollUser()
4. Check for errors
5. Navigate to consent screen if successful

**Code Template:**
```dart
Future<void> _handleEnrollment() async {
  // Step 1: Validate form
  if (!_formKey.currentState!.validate()) {
    return;  // Form has errors, don't proceed
  }

  // Step 2: Get provider
  final authProvider = context.read<AuthProvider>();

  // Step 3: Enroll user
  await authProvider.enrollUser(_codeController.text);

  // Step 4: Check for errors
  if (authProvider.errorMessage != null) {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authProvider.errorMessage!),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Step 5: Navigate to consent screen
  if (mounted) {
    Navigator.pushReplacementNamed(context, '/consent');
  }
}
```

**Acceptance Criteria:**
- [ ] Validates form before proceeding
- [ ] Calls provider.enrollUser()
- [ ] Shows SnackBar on error
- [ ] Navigates on success
- [ ] Uses context.read() not context.watch()

---

#### Task 4.2: Connect TextField to Provider

**Purpose:** Update provider as user types

**Location:** Line ~142 in enrollment_screen.dart

**Code:**
```dart
TextFormField(
  controller: _codeController,
  onChanged: (value) {
    context.read<AuthProvider>().updateEnrollmentCode(value);
  },
  // ... rest of properties
)
```

**Acceptance Criteria:**
- [ ] onChanged callback added
- [ ] Calls provider.updateEnrollmentCode()
- [ ] Uses context.read()

---

#### Task 4.3: Show Loading Indicator

**Purpose:** Show spinner while enrolling

**Location:** Line ~161 in enrollment_screen.dart (Consumer)

**Code:**
```dart
Consumer<AuthProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ElevatedButton(
      onPressed: _handleEnrollment,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
      ),
      child: const Text(
        'Enroll in Study',
        style: TextStyle(fontSize: 16),
      ),
    );
  },
)
```

**Acceptance Criteria:**
- [ ] Shows CircularProgressIndicator when loading
- [ ] Shows button when not loading
- [ ] Uses Consumer to watch isLoading

---

#### Task 4.4: Show Error Message

**Purpose:** Display error message if enrollment fails

**Location:** Line ~186 in enrollment_screen.dart (Consumer)

**Code:**
```dart
Consumer<AuthProvider>(
  builder: (context, provider, child) {
    if (provider.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          provider.errorMessage!,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return const SizedBox.shrink();
  },
)
```

**Acceptance Criteria:**
- [ ] Shows error message when present
- [ ] Error text styled in red
- [ ] Returns empty widget when no error
- [ ] Uses Consumer to watch errorMessage

---

### Task 5: Connect Consent Screen

**File:** `lib/features/authentication/screens/consent_screen.dart`

**Priority:** ⭐ (Quick task)

---

#### Task 5.1: Implement `_handleAcceptConsent()`

**Purpose:** Handle consent acceptance

**Code:**
```dart
Future<void> _handleAcceptConsent() async {
  final authProvider = context.read<AuthProvider>();
  await authProvider.acceptConsent();

  if (mounted) {
    // Navigate to home screen (or tutorial if you create it)
    Navigator.pushReplacementNamed(context, '/home');
  }
}
```

**Note:** '/home' route doesn't exist yet - you'll create it in Phase 2, or just show a placeholder screen for now.

**Acceptance Criteria:**
- [ ] Calls provider.acceptConsent()
- [ ] Navigates to next screen
- [ ] Checks mounted before navigating

---

## ✅ Testing Your Implementation

### Manual Testing Checklist

Run the app and verify:

**Enrollment Screen:**
- [ ] App launches to enrollment screen
- [ ] Can type in enrollment code field
- [ ] Validation shows errors for invalid codes:
  - [ ] Empty code → "Please enter an enrollment code"
  - [ ] Code "ABC" → "Code must be 8-12 characters"
  - [ ] Code "ABC@1234" → Should fail validation (special char)
  - [ ] Valid code "ABC12345" → Validates successfully
- [ ] Loading indicator shows while enrolling
- [ ] Error message displays if enrollment fails
- [ ] Successfully navigates to consent screen with valid code

**Consent Screen:**
- [ ] Consent text is scrollable
- [ ] Checkbox works
- [ ] "I Accept" button disabled until checkbox checked
- [ ] Button enabled after checking
- [ ] Clicking button accepts consent

**Database Verification:**
- [ ] User saved to database (check using database inspector)
- [ ] study_id generated correctly
- [ ] enrollment_code saved
- [ ] enrolled_at timestamp set
- [ ] consent_accepted updated to 1 after accepting

### Unit Testing (Optional but Recommended)

Create test file: `test/features/authentication/user_model_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:med_pharm_app/features/authentication/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('toMap should convert UserModel to Map', () {
      final user = UserModel(
        studyId: 'TEST123',
        enrollmentCode: 'ABC12345',
        enrolledAt: DateTime(2024, 11, 6),
      );

      final map = user.toMap();

      expect(map['study_id'], 'TEST123');
      expect(map['enrollment_code'], 'ABC12345');
      expect(map['consent_accepted'], 0);
    });

    test('fromMap should create UserModel from Map', () {
      final map = {
        'id': 1,
        'study_id': 'TEST123',
        'enrollment_code': 'ABC12345',
        'enrolled_at': '2024-11-06T10:00:00.000Z',
        'consent_accepted': 1,
        'consent_accepted_at': null,
        'tutorial_completed': 0,
      };

      final user = UserModel.fromMap(map);

      expect(user.id, 1);
      expect(user.studyId, 'TEST123');
      expect(user.consentAccepted, true);
    });
  });
}
```

Run tests: `flutter test`

---

## 📤 Submission Requirements

### What to Submit

1. **Modified Files** (5 files):
   - `lib/features/authentication/models/user_model.dart`
   - `lib/features/authentication/services/auth_service.dart`
   - `lib/features/authentication/providers/auth_provider.dart`
   - `lib/features/authentication/screens/enrollment_screen.dart`
   - `lib/features/authentication/screens/consent_screen.dart`

2. **Video Demonstration** (3-5 minutes):
   - Show app running on emulator/device
   - Demonstrate enrollment flow
   - Show database content (using database inspector or print statements)
   - Explain one implemented method

3. **Written Report** (1-2 pages):
   - Challenges encountered and solutions
   - What you learned about architecture patterns
   - How Provider pattern works (in your own words)

### Submission Checklist

- [ ] All TODO methods implemented
- [ ] App runs without errors
- [ ] Enrollment flow works end-to-end
- [ ] Code follows Dart conventions (run `flutter analyze`)
- [ ] Code formatted (run `flutter format .`)
- [ ] Manual testing completed
- [ ] Video demonstration recorded
- [ ] Written report completed

---

## 📊 Grading Rubric (100 points)

### Implementation (70 points)

**UserModel (15 points)**
- toMap() implementation: 5 points
- fromMap() implementation: 5 points
- copyWith() implementation: 5 points

**AuthService (25 points)**
- getCurrentUser(): 5 points
- updateConsentStatus(): 5 points
- updateTutorialStatus(): 4 points
- validateEnrollmentCode(): 6 points
- isUserEnrolled(): 5 points

**AuthProvider (20 points)**
- enrollUser(): 8 points
- acceptConsent(): 4 points
- completeTutorial(): 4 points
- updateEnrollmentCode(): 4 points

**UI Integration (10 points)**
- Enrollment screen connected: 5 points
- Consent screen connected: 5 points

### Code Quality (15 points)

- **Follows patterns** (5 points): Matches example methods
- **Error handling** (3 points): Try-catch blocks present
- **Code organization** (3 points): Clean, readable code
- **Comments** (2 points): Added helpful comments
- **No warnings** (2 points): `flutter analyze` passes

### Functionality (10 points)

- **Works correctly** (5 points): Enrollment flow completes
- **Data persists** (3 points): Database stores correctly
- **Error handling** (2 points): Handles invalid input

### Documentation (5 points)

- **Video demonstration** (3 points): Clear, shows all features
- **Written report** (2 points): Thoughtful, well-written

---

## 💡 Tips for Success

### Getting Started
1. ✅ Read one file at a time
2. ✅ Start with UserModel (easiest)
3. ✅ Study the example methods carefully
4. ✅ Test each method after implementing it

### Common Mistakes to Avoid
❌ Forgetting to call `notifyListeners()` in Provider
❌ Using `context.watch()` instead of `context.read()` for methods
❌ Not handling null values properly
❌ Forgetting try-catch blocks
❌ Not converting DateTime to String for database
❌ Converting bool to String instead of int for SQLite

### Debugging Tips
- 🔍 Use `print()` statements to see values
- 🔍 Check database using Database Inspector (Android Studio)
- 🔍 Run `flutter analyze` to find issues
- 🔍 Read error messages carefully - they usually tell you the problem

### Best Practices
- ✅ Test after implementing each method
- ✅ Follow the patterns from example methods
- ✅ Read the Learning Notes at the end of each file
- ✅ Ask questions early, don't wait until deadline

---

## 🆘 Getting Help

### Resources
1. **ARCHITECTURE_GUIDE.md** - Your main reference
2. **Example methods in code** - saveUser(), loadCurrentUser()
3. **Learning Notes** - At the end of each file
4. **Flutter Docs** - https://docs.flutter.dev
5. **Provider Docs** - https://pub.dev/packages/provider

### When Stuck
1. Re-read the TODO comments
2. Look at the example method in the same file
3. Check ARCHITECTURE_GUIDE.md for pattern explanations
4. Try printing values to understand what's happening
5. Ask instructor or classmates

### Office Hours
[Add your office hours here]

---

## 🎯 Learning Outcomes Assessment

After completing this assignment, you should be able to:

- [ ] **Explain** the purpose of Models, Services, and Providers
- [ ] **Implement** data serialization (toMap/fromMap)
- [ ] **Create** database operations using sqflite
- [ ] **Build** state management with Provider
- [ ] **Connect** UI to state using Consumer and context methods
- [ ] **Handle** async operations with proper error handling
- [ ] **Navigate** between screens
- [ ] **Debug** common Flutter issues

---

## 📅 Timeline Suggestion

**Day 1-2:** UserModel + AuthService
**Day 3-4:** AuthProvider
**Day 5:** UI Integration
**Day 6:** Testing + Documentation
**Day 7:** Video + Report

**Total:** 6-8 hours

---

**Good luck! Remember: Follow the patterns, test frequently, and ask questions! 🚀**

---

## Appendix A: Quick Reference

### Pattern: Provider Method

```dart
Future<void> myMethod() async {
  try {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Do async work
    final result = await _service.someMethod();

    // Update state
    _someState = result;

    _isLoading = false;
    notifyListeners();
  } catch (e) {
    _isLoading = false;
    _errorMessage = 'Error: $e';
    notifyListeners();
  }
}
```

### Pattern: Database Query

```dart
Future<List<MyModel>> getItems() async {
  final db = await _databaseService.database;
  final results = await db.query('table_name');
  return results.map((map) => MyModel.fromMap(map)).toList();
}
```

### Pattern: UI Consumer

```dart
Consumer<MyProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) {
      return CircularProgressIndicator();
    }
    return Text(provider.data);
  },
)
```
