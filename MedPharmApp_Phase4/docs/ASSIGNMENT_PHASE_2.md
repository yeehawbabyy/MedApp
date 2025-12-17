# Phase 2 Assignment: Pain Assessment Feature

**Course:** Mobile Applications in Surgery and Medicine 4.0
**Phase:** 2 of 3
**Difficulty:** Intermediate (60% scaffolded)
**Estimated Time:** 4-6 hours

---

## Overview

In Phase 2, you will implement the **Pain Assessment feature** that allows users to submit daily pain ratings using two validated clinical scales: NRS (Numerical Rating Scale) and VAS (Visual Analog Scale).

### What You'll Build

- ✅ Assessment data model with validation
- ✅ Assessment database service layer
- ✅ Assessment state management (Provider)
- ✅ Three assessment screens (NRS, VAS, History)
- ✅ Multi-step form flow with navigation
- ✅ List-based UI with ListView.builder

### Learning Goals

By completing this phase, you will:

1. **Apply Phase 1 Patterns** - Use the same architectural patterns with less scaffolding
2. **Work with Lists** - Handle collections of data in state management and UI
3. **Master Multi-Step Flows** - Navigate between screens while passing data
4. **Implement Business Logic** - Enforce "one assessment per day" rule
5. **Build Complex UI** - Create interactive sliders, color-coded feedback, list views

---

## Prerequisites

- ✅ **Completed Phase 1** - All 17 Phase 1 TODOs implemented and working
- ✅ **Understanding of Provider** - ChangeNotifier, notifyListeners(), Consumer
- ✅ **Database Knowledge** - SQLite queries, toMap/fromMap patterns
- ✅ **Navigation Skills** - Navigator.pushNamed(), passing arguments

---

## Assignment Structure

### Total TODOs: 12

#### 1. AssessmentModel (2 TODOs)
**File:** `lib/features/assessment/models/assessment_model.dart`

- [ ] **TODO 1:** Implement `fromMap()` factory method
- [ ] **TODO 2:** Implement `copyWith()` method

**Difficulty:** ⭐ Easy - Same patterns as Phase 1 UserModel

#### 2. AssessmentService (3 TODOs)
**File:** `lib/features/assessment/services/assessment_service.dart`

- [ ] **TODO 1:** Implement `getAssessmentHistory()` - Query and return list
- [ ] **TODO 2:** Implement `getAssessmentCount()` - Count assessments
- [ ] **TODO 3:** Implement `hasTodayAssessment()` - Check if assessment exists

**Difficulty:** ⭐⭐ Medium - Work with queries and date filtering

#### 3. AssessmentProvider (3 TODOs)
**File:** `lib/features/assessment/providers/assessment_provider.dart`

- [ ] **TODO 1:** Implement `loadAssessmentHistory()` - Load list from service
- [ ] **TODO 2:** Implement `refreshAssessments()` - Call multiple methods
- [ ] **TODO 3:** Implement `clearError()` - Clear error state

**Difficulty:** ⭐ Easy - Follow provided patterns

#### 4. NRS Assessment Screen (2 TODOs)
**File:** `lib/features/assessment/screens/nrs_assessment_screen.dart`

- [ ] **TODO 1:** Implement `_handleNext()` - Navigate to VAS screen with data
- [ ] **TODO 2:** Connect slider onChanged (Already implemented as example)

**Difficulty:** ⭐ Easy - Simple navigation with arguments

#### 5. VAS Assessment Screen (2 TODOs)
**File:** `lib/features/assessment/screens/vas_assessment_screen.dart`

- [ ] **TODO 1:** Implement `_handleSubmit()` - Submit assessment via provider
- [ ] **TODO 2:** Show loading indicator (Already implemented as example)

**Difficulty:** ⭐⭐ Medium - Work with multiple providers

#### 6. Assessment History Screen (2 TODOs)
**File:** `lib/features/assessment/screens/assessment_history_screen.dart`

- [ ] **TODO 1:** Load history in initState (Already wired up)
- [ ] **TODO 2:** Implement `_loadHistory()` - Call provider method
- [ ] **TODO 3:** Add FAB for new assessment (Already implemented as example)

**Difficulty:** ⭐ Easy - Follow initState pattern

---

## Detailed TODO Instructions

### Part 1: Data Layer (Models & Services)

#### AssessmentModel TODOs

**TODO 1: Implement fromMap() (Lines 101-105)**

Create an AssessmentModel from a database Map.

```dart
factory AssessmentModel.fromMap(Map<String, dynamic> map) {
  // 1. Extract values from map using proper type casting
  // 2. Convert String → DateTime using DateTime.parse()
  // 3. Convert int → bool (1 == true, 0 == false)
  // 4. Return AssessmentModel with all fields
}
```

**Hints:**
- Study the `toMap()` method above (lines 65-75) - it's the reverse operation
- Reference Phase 1 `UserModel.fromMap()` for the pattern
- DateTime fields: `timestamp` and `createdAt` are stored as ISO8601 strings
- Bool field: `is_synced` is stored as int (0 or 1)

**TODO 2: Implement copyWith() (Lines 123-135)**

Create a copy with some fields optionally updated.

```dart
AssessmentModel copyWith({
  String? id,
  String? studyId,
  // ... other parameters
}) {
  // Use ?? operator: parameter ?? this.field
  // Return new AssessmentModel with updated values
}
```

**Hints:**
- All parameters are optional and nullable
- Use null coalescing: `id ?? this.id`
- Reference Phase 1 `UserModel.copyWith()` for the exact pattern

---

#### AssessmentService TODOs

**TODO 1: Implement getAssessmentHistory() (Lines 144-151)**

Get assessment history for a user, ordered by newest first.

```dart
Future<List<AssessmentModel>> getAssessmentHistory(
  String studyId, {
  int limit = 30,
}) async {
  // 1. Get database
  // 2. Query assessments table
  // 3. Filter by study_id
  // 4. Order by timestamp DESC (newest first)
  // 5. Apply limit
  // 6. Convert each Map to AssessmentModel
  // 7. Return list
}
```

**Hints:**
- Study `getTodayAssessment()` above (lines 70-103) for query pattern
- Use `orderBy: 'timestamp DESC'` for newest first
- Use `.map((map) => AssessmentModel.fromMap(map)).toList()` to convert
- Don't forget try-catch and error handling!

**TODO 2: Implement getAssessmentCount() (Lines 185-189)**

Count total assessments for a user.

```dart
Future<int> getAssessmentCount(String studyId) async {
  // 1. Query assessments where study_id = ?
  // 2. Return results.length
  // 3. Return 0 on error (safe fallback)
}
```

**Hints:**
- This is the SIMPLEST method in this file
- Similar to Phase 1 `isUserEnrolled()` but return count instead of bool
- Use `results.length` to count rows

**TODO 3: Implement hasTodayAssessment() (Lines 212-216)**

Check if user has already submitted today's assessment.

```dart
Future<bool> hasTodayAssessment(String studyId) async {
  // 1. Call getTodayAssessment(studyId) - already implemented!
  // 2. Return true if result is not null
  // 3. Return false if result is null
}
```

**Hints:**
- This is a ONE-LINER method!
- Just use the existing `getTodayAssessment()` method
- Example: `return await getTodayAssessment(studyId) != null;`

---

### Part 2: Presentation Layer (Providers & Screens)

#### AssessmentProvider TODOs

**TODO 1: Implement loadAssessmentHistory() (Lines 139-141)**

Load assessment history from service and update state.

```dart
Future<void> loadAssessmentHistory(String studyId, {int limit = 30}) async {
  // 1. Set loading states
  // 2. Call _assessmentService.getAssessmentHistory()
  // 3. Update _assessmentHistory state
  // 4. Clear loading states
  // 5. Call notifyListeners()
  // 6. Handle errors
}
```

**Hints:**
- Study `loadTodayAssessment()` above (lines 86-107) - same pattern!
- Don't forget: `_isLoading = true` at start, `false` at end
- Clear `_errorMessage` at start
- Call `notifyListeners()` after state changes

**TODO 2: Implement refreshAssessments() (Lines 170-172)**

Refresh both today's assessment and history.

```dart
Future<void> refreshAssessments(String studyId) async {
  // 1. Call loadTodayAssessment(studyId)
  // 2. Call loadAssessmentHistory(studyId)
}
```

**Hints:**
- This is a TWO-LINER method!
- Both methods are already implemented
- Just call them in sequence (await each one)

**TODO 3: Implement clearError() (Lines 194-196)**

Clear the current error message.

```dart
void clearError() {
  // 1. Set _errorMessage to null
  // 2. Call notifyListeners()
}
```

**Hints:**
- This is the SIMPLEST method in the provider
- Two lines: set null, notify listeners
- Synchronous (no async/await needed)

---

#### NRS Assessment Screen TODOs

**TODO 1: Implement _handleNext() (Lines 44-47)**

Navigate to VAS screen with the selected NRS score.

```dart
void _handleNext() {
  // 1. Convert _nrsScore (double) to int using .round()
  // 2. Navigate to '/assessment/vas'
  // 3. Pass nrsScore in arguments: {'nrsScore': score}
}
```

**Hints:**
- Use `Navigator.pushNamed(context, '/assessment/vas', arguments: map)`
- Arguments format: `{'nrsScore': _nrsScore.round()}`
- No async needed - navigation is synchronous for pushNamed

**TODO 2: Slider onChanged** - Already implemented as example (Line 169-172)

---

#### VAS Assessment Screen TODOs

**TODO 1: Implement _handleSubmit() (Lines 69-71)**

Submit the completed assessment to the database.

```dart
Future<void> _handleSubmit() async {
  // 1. Get AuthProvider (for studyId)
  // 2. Get AssessmentProvider (for submit method)
  // 3. Extract studyId from current user
  // 4. Call provider.submitAssessment(studyId, nrsScore, vasScore)
  // 5. Check for errors
  // 6. If error: Show SnackBar with error
  // 7. If success: Show success SnackBar and navigate to history
}
```

**Hints:**
- Reference Phase 1 `_handleEnrollment()` from enrollment_screen.dart
- Use `context.read<AuthProvider>()` and `context.read<AssessmentProvider>()`
- VAS score: `_vasScore.round()` to convert double to int
- Navigate to: `/assessment/history` on success
- Use `Navigator.pushReplacementNamed()` so user can't go back

**TODO 2: Loading indicator** - Already implemented as example (Lines 195-212)

---

#### Assessment History Screen TODOs

**TODO 1: Load history in initState** - Already wired up (Lines 48-51)

**TODO 2: Implement _loadHistory() (Lines 62-65)**

Load assessment history from provider.

```dart
Future<void> _loadHistory() async {
  // 1. Get AuthProvider
  // 2. Get AssessmentProvider
  // 3. Get studyId from current user
  // 4. Call assessmentProvider.loadAssessmentHistory(studyId)
}
```

**Hints:**
- Similar to VAS screen's _handleSubmit() but simpler
- No error handling needed here (provider handles it)
- Just call the provider method

**TODO 3: FAB for new assessment** - Already implemented as example (Lines 188-202)

---

## Testing Your Implementation

### Step 1: Verify Compilation

```bash
flutter analyze --no-fatal-infos
# Should have no errors (print warnings are OK)
```

### Step 2: Build the App

```bash
flutter build apk --debug
# Should build successfully
```

### Step 3: Manual Testing

Run the app and test the complete flow:

1. **Navigate to Assessment**
   - From home screen, tap "New Assessment" button
   - Should open NRS screen

2. **NRS Screen Testing**
   - [ ] Move slider - score should update
   - [ ] Color should change based on score (green → yellow → red)
   - [ ] Description should update ("Mild Pain", "Severe Pain", etc.)
   - [ ] Tap "Next" → Should navigate to VAS screen

3. **VAS Screen Testing**
   - [ ] Should show NRS score from previous screen
   - [ ] Move slider - score should update (0-100)
   - [ ] Color and description should update
   - [ ] Tap "Submit Assessment"
   - [ ] Should show loading spinner
   - [ ] Should show success message
   - [ ] Should navigate to History screen

4. **History Screen Testing**
   - [ ] Should display submitted assessment
   - [ ] Should show NRS and VAS scores
   - [ ] Should show date and time
   - [ ] Today's assessment should have "Today" chip
   - [ ] FAB should be hidden (can't submit twice today)
   - [ ] Pull to refresh should work

5. **One-Per-Day Rule Testing**
   - [ ] Try to submit another assessment today
   - [ ] Should show error: "You have already submitted an assessment today"
   - [ ] FAB should not appear on history screen

6. **Database Testing**
   - Use Android Studio Database Inspector
   - Check `assessments` table has your data
   - Verify NRS score, VAS score, timestamps are correct

### Step 4: Edge Cases

Test these scenarios:

- [ ] What happens with empty assessment history?
  - Should show "No assessments yet" message
  - Should show button to create first assessment

- [ ] What happens if database error occurs?
  - Should show error message
  - Should show "Retry" button

- [ ] Navigation back button behavior
  - From VAS screen: Goes back to NRS screen
  - From History screen: Goes back to home

---

## Common Errors & Solutions

### Error: "UnimplementedError: fromMap() not implemented"

**Cause:** You haven't implemented the fromMap() method yet
**Solution:** Implement AssessmentModel.fromMap() following the toMap() pattern

### Error: "The getter 'assessmentHistory' isn't defined"

**Cause:** Provider not properly registered in main.dart
**Solution:** Check that AssessmentProvider is in ChangeNotifierProvider list

### Error: "Could not find a generator for route '/assessment/nrs'"

**Cause:** Routes not registered in main.dart
**Solution:** Add assessment routes to routes map in main.dart

### Error: "type 'Null' is not a subtype of type 'String'"

**Cause:** Trying to access navigation arguments before they're set
**Solution:** Use null-aware operators: `args?['nrsScore'] as int?`

### Error: "The argument type 'Future<void>' can't be assigned to 'VoidCallback'"

**Cause:** Using async function where sync callback expected
**Solution:** Wrap in separate async method or use `onPressed: () async { ... }`

### ListView not showing items

**Cause:** Not calling loadAssessmentHistory() on screen init
**Solution:** Check initState() and _loadHistory() implementation

---

## Grading Rubric

### Functionality (60 points)

- **AssessmentModel** (10 points)
  - fromMap() correctly deserializes data (5 pts)
  - copyWith() creates correct copies (5 pts)

- **AssessmentService** (15 points)
  - getAssessmentHistory() returns correct list (5 pts)
  - getAssessmentCount() returns accurate count (5 pts)
  - hasTodayAssessment() checks correctly (5 pts)

- **AssessmentProvider** (15 points)
  - loadAssessmentHistory() updates state correctly (5 pts)
  - refreshAssessments() calls both methods (5 pts)
  - clearError() clears error state (5 pts)

- **Screens** (20 points)
  - NRS screen navigates with data (5 pts)
  - VAS screen submits assessment (10 pts)
  - History screen loads and displays data (5 pts)

### Code Quality (20 points)

- Follows established patterns from Phase 1 (5 pts)
- Proper error handling (try-catch, error messages) (5 pts)
- Consistent code style and formatting (5 pts)
- Meaningful variable names (5 pts)

### Architecture (20 points)

- Correct separation of concerns (Model/Service/Provider/UI) (10 pts)
- Proper state management (notifyListeners() usage) (5 pts)
- Navigation flow works correctly (5 pts)

### Total: 100 points

**Passing Grade:** 70 points
**Good Grade:** 85 points
**Excellent Grade:** 95+ points

---

## Submission Instructions

### What to Submit

1. **Source Code**
   - Zip your entire `lib/features/assessment/` directory
   - Include all modified files

2. **Video Demo** (2-3 minutes)
   - Show app running on emulator/device
   - Complete one full assessment flow (NRS → VAS → History)
   - Show history screen with multiple assessments
   - Demonstrate "one per day" rule (try submitting twice)

3. **Reflection Document** (1 page)
   - What was the most challenging TODO and why?
   - How does Phase 2 differ from Phase 1 in complexity?
   - What patterns from Phase 1 did you reuse?
   - What did you learn about state management with lists?

### Submission Deadline

**Due:** [Instructor to fill in]

### How to Submit

[Instructor to fill in submission platform/method]

---

## Tips for Success

### Before You Start

1. ✅ **Complete Phase 1 first** - Don't start Phase 2 until Phase 1 works
2. ✅ **Review Phase 1 patterns** - Many Phase 2 TODOs use same patterns
3. ✅ **Read all code comments** - Hints are embedded in the code
4. ✅ **Study example methods** - Each file has fully implemented examples

### While Working

1. **Implement in order** - Start with Model → Service → Provider → Screens
2. **Test incrementally** - Test each TODO after implementing it
3. **Use print statements** - Debug by printing values to console
4. **Read error messages** - Flutter errors tell you exactly what's wrong
5. **Compare with Phase 1** - When stuck, look at similar Phase 1 code

### When Stuck

1. **Check the hints** - Every TODO has detailed hints in comments
2. **Look at examples** - Every file has working examples to study
3. **Review Phase 1 code** - Most patterns are identical
4. **Use Flutter DevTools** - Inspect state, check database
5. **Ask for help** - Office hours, classmates, discussion forum

---

## Learning Resources

### Official Documentation

- [Flutter Provider Package](https://pub.dev/packages/provider)
- [SQLite (sqflite) Package](https://pub.dev/packages/sqflite)
- [Flutter Navigation](https://docs.flutter.dev/cookbook/navigation)

### Course Materials

- Phase 1 Teaching Materials (reference implementations)
- ARCHITECTURE_GUIDE.md (architecture overview)
- TROUBLESHOOTING_PHASE_1.md (common errors)

---

## Next Steps

After completing Phase 2, you'll be ready for:

### Phase 3: Gamification & Analytics

- Achievement system
- Progress tracking
- Data visualization (charts)
- Less scaffolding (30% - more independent work)

---

## Questions?

If you have questions about the assignment:

1. Check the code comments first (detailed hints)
2. Review Phase 1 implementations (similar patterns)
3. Post in course discussion forum
4. Attend office hours
5. Email instructor: [Instructor to fill in]

---

**Good luck with Phase 2! Remember: You already know these patterns from Phase 1. Phase 2 is the same patterns applied to a more complex feature. 🚀**
