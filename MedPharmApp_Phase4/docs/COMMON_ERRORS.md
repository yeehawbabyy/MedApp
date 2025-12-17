# Common Errors & Troubleshooting Guide

**Purpose:** Quick solutions to common problems students encounter
**Tip:** Use Ctrl+F / Cmd+F to search for your error message

---

## 📋 Table of Contents

1. [Provider Errors](#provider-errors)
2. [Database Errors](#database-errors)
3. [Navigation Errors](#navigation-errors)
4. [Build Errors](#build-errors)
5. [Runtime Errors](#runtime-errors)
6. [Null Safety Errors](#null-safety-errors)
7. [Import Errors](#import-errors)
8. [General Debugging Tips](#general-debugging-tips)

---

## 1. Provider Errors

### Error: "Could not find the correct Provider<AuthProvider>"

**Full Error:**
```
Error: Could not find the correct Provider<AuthProvider> above this Widget

This happens because you used a BuildContext that does not include the provider
of your choice.
```

**Cause:** Trying to access Provider before it's provided in the widget tree

**Solution:**
```dart
✅ Fix - Ensure Provider is ABOVE the widget trying to access it

// In main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(...),
    ),
  ],
  child: MaterialApp(  // ← Provider is above MaterialApp
    home: EnrollmentScreen(),  // ← So screens can access it
  ),
)

❌ Wrong - Provider below widget
MaterialApp(
  home: MultiProvider(  // ← Too late! EnrollmentScreen can't access it
    providers: [...],
    child: EnrollmentScreen(),
  ),
)
```

**Quick Check:**
- Open `main.dart`
- Find `MultiProvider`
- Verify `ChangeNotifierProvider<AuthProvider>` is in the providers list
- Verify `MaterialApp` is the child of `MultiProvider`

---

### Error: "Unhandled Exception: setState() called after dispose()"

**Cause:** Calling `setState()` or `notifyListeners()` after widget is disposed

**Solution:**
```dart
✅ Fix - Check if still mounted/active

// In Provider
Future<void> myMethod() async {
  _isLoading = true;
  notifyListeners();

  try {
    await someAsyncOperation();

    // Check if still active before updating state
    if (!_isDisposed) {  // Add this check
      _isLoading = false;
      notifyListeners();
    }
  } catch (e) {
    if (!_isDisposed) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}

// In StatefulWidget
Future<void> myMethod() async {
  await someAsyncOperation();

  if (mounted) {  // Check if widget still in tree
    setState(() {
      // Update state
    });
  }
}
```

---

### Error: "The getter 'currentUser' isn't defined for the type 'BuildContext'"

**Cause:** Using wrong syntax to access Provider

**Solution:**
```dart
✅ Fix - Use proper Provider syntax

// To READ provider (in methods, onPressed callbacks)
final provider = context.read<AuthProvider>();
provider.enrollUser('ABC12345');

// To WATCH provider (in build method, Consumer)
final provider = context.watch<AuthProvider>();
return Text(provider.currentUser?.studyId ?? 'No user');

// Using Consumer (recommended for specific widgets)
Consumer<AuthProvider>(
  builder: (context, provider, child) {
    return Text(provider.currentUser?.studyId ?? 'No user');
  },
)

❌ Wrong
context.currentUser  // Wrong syntax
context.get<AuthProvider>().currentUser  // Wrong method
```

---

## 2. Database Errors

### Error: "table user_session has no column named X"

**Cause:** Column name in code doesn't match database schema

**Solution:**
```dart
✅ Fix - Match column names exactly

// Check database_service.dart for exact column names
CREATE TABLE user_session (
  study_id TEXT NOT NULL,  // ← Must use 'study_id'
  enrollment_code TEXT,    // ← Must use 'enrollment_code'
  ...
)

// In userModel.toMap()
Map<String, dynamic> toMap() {
  return {
    'study_id': studyId,          // ← Matches database
    'enrollment_code': enrollmentCode,  // ← Matches database
    // ...
  };
}

❌ Wrong - Column name mismatch
{
  'studyId': studyId,  // Wrong! Database uses 'study_id'
  'code': enrollmentCode,  // Wrong! Database uses 'enrollment_code'
}
```

**Quick Fix:**
1. Open `lib/core/services/database_service.dart`
2. Find the CREATE TABLE statement
3. Copy exact column names
4. Use those exact names in your toMap() and fromMap() methods

---

### Error: "UNIQUE constraint failed"

**Full Error:**
```
SqliteException(19): UNIQUE constraint failed: user_session.study_id
```

**Cause:** Trying to insert a record with duplicate unique value

**Solution:**
```dart
✅ Fix Option 1 - Use INSERT OR REPLACE

await db.insert(
  'user_session',
  userMap,
  conflictAlgorithm: ConflictAlgorithm.replace,  // Replace if exists
);

✅ Fix Option 2 - Check before inserting

final existing = await db.query(
  'user_session',
  where: 'study_id = ?',
  whereArgs: [studyId],
);

if (existing.isEmpty) {
  // Safe to insert
  await db.insert('user_session', userMap);
} else {
  // Update instead
  await db.update('user_session', userMap,
    where: 'study_id = ?',
    whereArgs: [studyId],
  );
}
```

---

### Error: "type 'int' is not a subtype of type 'String' in type cast"

**Cause:** Wrong type conversion when reading from database

**Solution:**
```dart
✅ Fix - Use correct type casting

factory UserModel.fromMap(Map<String, dynamic> map) {
  return UserModel(
    id: map['id'] as int?,  // ← int, can be null
    studyId: map['study_id'] as String,  // ← String, required
    consentAccepted: map['consent_accepted'] == 1,  // ← int to bool
    enrolledAt: DateTime.parse(map['enrolled_at'] as String),  // ← String to DateTime
  );
}

❌ Wrong - Type mismatch
id: map['id'] as String,  // Wrong! id is int
consentAccepted: map['consent_accepted'] as bool,  // Wrong! SQLite uses int
enrolledAt: map['enrolled_at'] as DateTime,  // Wrong! Database stores String
```

**Remember:**
- SQLite INTEGER → Dart int
- SQLite TEXT → Dart String
- SQLite INTEGER (0/1) → Dart bool (false/true)
- DateTime → Store as TEXT using `.toIso8601String()`

---

### Error: "Bad state: No element"

**Cause:** Calling `.first` on empty query results

**Solution:**
```dart
✅ Fix - Check if results empty

final results = await db.query('user_session', limit: 1);

if (results.isEmpty) {
  return null;  // No user found
}

return UserModel.fromMap(results.first);  // Safe

❌ Wrong - No check
final results = await db.query('user_session', limit: 1);
return UserModel.fromMap(results.first);  // Crashes if empty!
```

---

## 3. Navigation Errors

### Error: "Navigator operation requested with a context that does not include a Navigator"

**Cause:** Calling Navigator before MaterialApp is built

**Solution:**
```dart
✅ Fix - Ensure MaterialApp exists

// Wrong place - no Navigator yet
void main() {
  Navigator.pushNamed(context, '/home');  // ❌ Too early!
  runApp(MyApp());
}

// Right place - after MaterialApp
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, '/home');  // ✅ Works!
      },
      child: Text('Go'),
    );
  }
}
```

---

### Error: "Could not find a generator for route RouteSettings('/xyz')"

**Cause:** Route not defined in routes map

**Solution:**
```dart
✅ Fix - Add route to AppRoutes

// In lib/app/routes.dart
static Map<String, WidgetBuilder> get routes {
  return {
    enrollment: (context) => const EnrollmentScreen(),
    consent: (context) => const ConsentScreen(),
    '/home': (context) => const HomeScreen(),  // ← Add missing route
  };
}

// Make sure you're using the correct route name
Navigator.pushNamed(context, '/home');  // Must match key in routes map

❌ Wrong
Navigator.pushNamed(context, '/homepage');  // Typo! Should be '/home'
```

---

### Error: "Don't use 'BuildContext's across async gaps"

**Warning in IDE when using context after await**

**Cause:** Using context after async operation (widget might be disposed)

**Solution:**
```dart
✅ Fix - Check mounted before using context

Future<void> handleButton() async {
  await someAsyncOperation();

  // Check if widget still mounted before using context
  if (!mounted) return;

  Navigator.pushNamed(context, '/next');  // Safe
}

// Or store Navigator before await
Future<void> handleButton() async {
  final navigator = Navigator.of(context);  // Get Navigator first

  await someAsyncOperation();

  navigator.pushNamed('/next');  // Safe
}

❌ Wrong - Using context after await without check
Future<void> handleButton() async {
  await someAsyncOperation();
  Navigator.pushNamed(context, '/next');  // Might crash!
}
```

---

## 4. Build Errors

### Error: "Target of URI doesn't exist: 'package:provider/provider.dart'"

**Cause:** Dependencies not installed

**Solution:**
```bash
# Run this in terminal
flutter pub get

# If that doesn't work, try:
flutter clean
flutter pub get

# If still having issues, delete pubspec.lock and try again
rm pubspec.lock
flutter pub get
```

---

### Error: "The method 'X' isn't defined for the class 'Y'"

**Cause:** Missing method implementation or wrong class

**Solution:**
```dart
✅ Fix - Implement the method

// If you see this error:
// The method 'toMap' isn't defined for the class 'UserModel'

// It means you need to implement toMap() in UserModel
class UserModel {
  Map<String, dynamic> toMap() {  // ← Add this method
    return {
      'study_id': studyId,
      // ...
    };
  }
}

// Or check you're calling the method on the right object
final map = userModel.toMap();  // ✅ Correct
final map = authService.toMap();  // ❌ Wrong class!
```

---

### Error: "The argument type 'String' can't be assigned to the parameter type 'int'"

**Cause:** Passing wrong type to a function

**Solution:**
```dart
✅ Fix - Convert to correct type

// If function expects int
void setAge(int age) { }

// Convert String to int
setAge(int.parse('25'));  // ✅ Correct
setAge('25');  // ❌ Wrong type

// If function expects String
void setCode(String code) { }

// Convert int to String
setCode(25.toString());  // ✅ Correct
setCode(25);  // ❌ Wrong type
```

---

## 5. Runtime Errors

### Error: "Null check operator used on a null value"

**Cause:** Using ! on a null value

**Solution:**
```dart
✅ Fix - Check for null before using !

String? nullableValue;

// Wrong - crashes if null
print(nullableValue!.length);  // ❌ Crash!

// Right - check first
if (nullableValue != null) {
  print(nullableValue.length);  // ✅ Safe
}

// Or use null-aware operator
print(nullableValue?.length);  // ✅ Returns null if nullableValue is null
print(nullableValue?.length ?? 0);  // ✅ Returns 0 if null
```

---

### Error: "RangeError (index): Invalid value: Not in inclusive range 0..0: 1"

**Cause:** Accessing list index that doesn't exist

**Solution:**
```dart
✅ Fix - Check list length

List<String> items = ['first'];

// Wrong
print(items[1]);  // ❌ Crash! Only index 0 exists

// Right
if (items.length > 1) {
  print(items[1]);  // ✅ Safe
}

// Or use .elementAt with default
print(items.elementAtOrNull(1) ?? 'default');  // ✅ Returns null if doesn't exist
```

---

### Error: "A RenderFlex overflowed by X pixels on the bottom"

**Cause:** Widget content too big for available space (often with keyboard)

**Solution:**
```dart
✅ Fix - Make content scrollable

// Wrap in SingleChildScrollView
return Scaffold(
  body: SingleChildScrollView(  // ← Add this
    child: Column(
      children: [
        // Your content
      ],
    ),
  ),
);

// Or use ListView instead of Column
return Scaffold(
  body: ListView(  // ← Instead of Column
    children: [
      // Your content
    ],
  ),
);
```

---

## 6. Null Safety Errors

### Error: "The property 'X' can't be unconditionally accessed because the receiver can be 'null'"

**Cause:** Accessing property on nullable object without null check

**Solution:**
```dart
✅ Fix - Check for null or use ?

UserModel? currentUser;

// Wrong
print(currentUser.studyId);  // ❌ currentUser might be null

// Right - Null check
if (currentUser != null) {
  print(currentUser.studyId);  // ✅ Safe
}

// Right - Null-aware operator
print(currentUser?.studyId);  // ✅ Returns null if currentUser is null
print(currentUser?.studyId ?? 'No ID');  // ✅ Returns 'No ID' if null
```

---

### Error: "The parameter 'X' can't have a value of 'null' because of its type"

**Cause:** Passing null to non-nullable parameter

**Solution:**
```dart
✅ Fix - Make parameter nullable or provide non-null value

// If parameter shouldn't be null
void setUser(UserModel user) {  // Required, non-nullable
  // ...
}

setUser(myUser!);  // ✅ Only if you're 100% sure it's not null
setUser(myUser ?? defaultUser);  // ✅ Provide fallback

// If parameter can be null
void setUser(UserModel? user) {  // Optional, nullable
  // ...
}

setUser(null);  // ✅ Now allowed
```

---

## 7. Import Errors

### Error: "Relative import paths aren't allowed"

**Cause:** Using relative imports from different directories incorrectly

**Solution:**
```dart
✅ Fix - Use package imports for consistency

// Instead of:
import '../../models/user_model.dart';

// Use package import:
import 'package:med_pharm_app/features/authentication/models/user_model.dart';

// Or use relative imports only within same feature:
// In lib/features/authentication/services/auth_service.dart
import '../models/user_model.dart';  // ✅ OK - same feature
```

---

### Error: "Duplicate import"

**Cause:** Importing same file twice

**Solution:**
```dart
❌ Wrong - Duplicate
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';  // Duplicate!

✅ Fix - Remove duplicate
import 'package:flutter/material.dart';  // Once is enough
```

---

## 8. General Debugging Tips

### 🔍 **Debugging Technique 1: Print Statements**

```dart
// Add prints to see what's happening
Future<void> enrollUser(String code) async {
  print('📝 enrollUser called with code: $code');

  final isValid = await validateCode(code);
  print('✅ Code valid: $isValid');

  if (!isValid) {
    print('❌ Invalid code, returning');
    return;
  }

  final user = UserModel(...);
  print('👤 Created user: $user');

  await saveUser(user);
  print('💾 User saved successfully');
}
```

### 🔍 **Debugging Technique 2: Debugger Breakpoints**

1. Click in the gutter (left of line numbers) to set breakpoint
2. Run app in debug mode
3. When code hits breakpoint, execution pauses
4. Inspect variables in Debug panel
5. Step through code line by line

### 🔍 **Debugging Technique 3: Flutter DevTools**

```bash
# Run app in debug mode
flutter run

# Open DevTools
# Look for the URL in console output
# Open in browser to see:
# - Widget Inspector
# - Network tab
# - Memory profiler
# - Performance tab
```

### 🔍 **Debugging Technique 4: Analyze & Format**

```bash
# Find issues
flutter analyze

# Auto-format code
flutter format .

# Fix some issues automatically
dart fix --apply
```

---

## 🆘 Still Stuck?

### Checklist Before Asking for Help

- [ ] Read the error message completely
- [ ] Searched this document for the error
- [ ] Checked your code against examples in the project
- [ ] Ran `flutter pub get`
- [ ] Ran `flutter clean` and rebuilt
- [ ] Restarted your IDE
- [ ] Checked ARCHITECTURE_GUIDE.md
- [ ] Added print statements to understand what's happening

### How to Ask for Help

When asking for help, provide:

1. **Error Message** (complete, not just first line)
2. **Code** that's causing the error
3. **What you tried** to fix it
4. **What you expected** to happen
5. **What actually happened**

**Good Question Example:**
```
I'm getting this error:
"Could not find the correct Provider<AuthProvider>"

In enrollment_screen.dart line 45:
final provider = context.read<AuthProvider>();

I checked main.dart and AuthProvider is in the MultiProvider list.
I expected the provider to be found.
Instead I get this error.

What I tried:
- Restarted the app
- Checked the provider is above MaterialApp

What am I missing?
```

---

## 📚 Additional Resources

- [Flutter Error Messages](https://flutter.dev/docs/testing/errors)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter) - Search your error

---

**Remember:** Every error is a learning opportunity! Read the error message carefully - it usually tells you exactly what's wrong. 🐛→🦋
