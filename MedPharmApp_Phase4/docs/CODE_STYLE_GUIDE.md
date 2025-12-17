# Code Style Guide for MedPharm App

**Purpose:** Maintain clean, readable, and professional code
**Applies to:** All Dart/Flutter code in this project

---

## 📋 Table of Contents

1. [Naming Conventions](#naming-conventions)
2. [File Organization](#file-organization)
3. [Code Formatting](#code-formatting)
4. [Comments & Documentation](#comments--documentation)
5. [Dart Best Practices](#dart-best-practices)
6. [Flutter Best Practices](#flutter-best-practices)
7. [Error Handling](#error-handling)
8. [Quick Checklist](#quick-checklist)

---

## 1. Naming Conventions

### Classes (UpperCamelCase)
```dart
✅ Good
class UserModel { }
class AuthProvider extends ChangeNotifier { }
class EnrollmentScreen extends StatefulWidget { }

❌ Bad
class user_model { }
class authprovider { }
class enrollment_screen { }
```

### Variables & Methods (lowerCamelCase)
```dart
✅ Good
String enrollmentCode;
UserModel? currentUser;
Future<void> enrollUser() { }
bool get isLoading => _isLoading;

❌ Bad
String EnrollmentCode;
UserModel? current_user;
Future<void> EnrollUser() { }
bool get is_loading => _isLoading;
```

### Constants (lowerCamelCase with const)
```dart
✅ Good
const int maxCodeLength = 12;
const String defaultStudyId = 'STUDY_DEFAULT';
static const Color primaryColor = Colors.blue;

❌ Bad
const int MAX_CODE_LENGTH = 12;  // Use lowerCamelCase
final String DEFAULT_STUDY_ID = 'STUDY_DEFAULT';  // Use const, not final
```

### Private Members (prefix with _)
```dart
✅ Good
class AuthProvider {
  UserModel? _currentUser;  // Private
  bool _isLoading = false;   // Private

  UserModel? get currentUser => _currentUser;  // Public getter
}

❌ Bad
class AuthProvider {
  UserModel? currentUser;  // Should be private with getter
  bool isLoading = false;  // Should be private
}
```

### Boolean Variables (use "is", "has", "can")
```dart
✅ Good
bool isLoading;
bool hasAcceptedConsent;
bool canSubmit;
bool get isValid => code.length >= 8;

❌ Bad
bool loading;
bool acceptedConsent;
bool submit;
bool get valid => code.length >= 8;
```

---

## 2. File Organization

### File Naming (snake_case)
```
✅ Good
user_model.dart
auth_service.dart
enrollment_screen.dart
database_service.dart

❌ Bad
UserModel.dart
AuthService.dart
EnrollmentScreen.dart
database-service.dart
```

### Import Order
```dart
✅ Good - Group and alphabetize
// 1. Dart SDK imports
import 'dart:async';

// 2. Flutter SDK imports
import 'package:flutter/material.dart';

// 3. External packages
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

// 4. Project imports (relative)
import '../models/user_model.dart';
import '../services/auth_service.dart';

❌ Bad - No organization
import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:provider/provider.dart';
```

### Class Structure Order
```dart
class MyWidget extends StatefulWidget {
  // 1. Constants
  static const int maxAttempts = 3;

  // 2. Final fields
  final String title;
  final Function() onTap;

  // 3. Constructor
  const MyWidget({
    Key? key,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  // 4. Overrides
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // 1. State variables
  bool _isActive = false;

  // 2. Lifecycle methods
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 3. Private methods
  void _handleTap() { }

  // 4. Build method (last)
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

---

## 3. Code Formatting

### Line Length (80 characters recommended, 120 max)
```dart
✅ Good
final user = UserModel(
  studyId: 'STUDY123',
  enrollmentCode: 'ABC12345',
  enrolledAt: DateTime.now(),
);

❌ Bad (too long)
final user = UserModel(studyId: 'STUDY123', enrollmentCode: 'ABC12345', enrolledAt: DateTime.now(), consentAccepted: false);
```

### Indentation (2 spaces, not tabs)
```dart
✅ Good
class MyClass {
  void myMethod() {
    if (condition) {
      doSomething();
    }
  }
}

❌ Bad (4 spaces or tabs)
class MyClass {
    void myMethod() {
        if (condition) {
            doSomething();
        }
    }
}
```

### Trailing Commas (always use for multiline)
```dart
✅ Good - Enables better formatting
final user = UserModel(
  studyId: 'STUDY123',
  enrollmentCode: 'ABC12345',
  enrolledAt: DateTime.now(),
);  // ← Trailing comma

❌ Bad - No trailing comma
final user = UserModel(
  studyId: 'STUDY123',
  enrollmentCode: 'ABC12345',
  enrolledAt: DateTime.now()
);
```

### Whitespace
```dart
✅ Good
// Blank line between methods
void method1() {
  doSomething();
}

void method2() {
  doOtherThing();
}

// Space after commas
final list = [1, 2, 3];
final map = {'key': 'value'};

// Space around operators
int sum = a + b;
bool isValid = age >= 18;

❌ Bad
void method1() {
  doSomething();
}
void method2() {  // No blank line
  doOtherThing();
}

final list = [1,2,3];  // No spaces
int sum = a+b;  // No spaces
```

---

## 4. Comments & Documentation

### Doc Comments (use ///)
```dart
✅ Good
/// Validates the enrollment code format.
///
/// Returns `true` if the code is valid:
/// - Not empty
/// - 8-12 characters long
/// - Alphanumeric only
///
/// Example:
/// ```dart
/// if (validateCode('ABC12345')) {
///   print('Valid!');
/// }
/// ```
bool validateCode(String code) {
  // Implementation
}

❌ Bad
// validates code
bool validateCode(String code) {
  // Implementation
}
```

### TODO Comments (use // TODO:)
```dart
✅ Good
// TODO: Implement user logout functionality
// TODO: Add error handling for network failures

❌ Bad
// todo implement logout
// FIX THIS LATER
```

### Inline Comments (explain WHY, not WHAT)
```dart
✅ Good - Explains reasoning
// SQLite stores booleans as integers
final consentValue = consentAccepted ? 1 : 0;

// We use copyWith() because UserModel is immutable
_currentUser = _currentUser!.copyWith(
  consentAccepted: true,
);

❌ Bad - States the obvious
// Set consent to true
final consentValue = 1;

// Update the user
_currentUser = _currentUser!.copyWith(
  consentAccepted: true,
);
```

### Section Separators
```dart
✅ Good - Clear visual separation
class AuthProvider extends ChangeNotifier {
  // ========================================================================
  // DEPENDENCIES
  // ========================================================================
  final AuthService _authService;

  // ========================================================================
  // STATE VARIABLES
  // ========================================================================
  UserModel? _currentUser;
  bool _isLoading = false;

  // ========================================================================
  // METHODS
  // ========================================================================
  Future<void> enrollUser() async { }
}
```

---

## 5. Dart Best Practices

### Use const Constructors
```dart
✅ Good - Performance optimization
const Text('Hello');
const SizedBox(height: 16);
const Icon(Icons.home);

❌ Bad - Creates new instance every rebuild
Text('Hello');
SizedBox(height: 16);
Icon(Icons.home);
```

### Use final for Immutable Variables
```dart
✅ Good
class UserModel {
  final String studyId;
  final String enrollmentCode;

  UserModel({
    required this.studyId,
    required this.enrollmentCode,
  });
}

❌ Bad - Mutable when it shouldn't be
class UserModel {
  String studyId;
  String enrollmentCode;

  UserModel({
    required this.studyId,
    required this.enrollmentCode,
  });
}
```

### Use Null Safety Properly
```dart
✅ Good
String? nullableString;
String nonNullString = 'Hello';

// Safe null checking
if (nullableString != null) {
  print(nullableString.length);  // Safe
}

// Null-aware operators
final length = nullableString?.length ?? 0;
final upper = nullableString ?? 'DEFAULT';

❌ Bad
String? nullableString;
print(nullableString.length);  // Runtime error!
print(nullableString!.length);  // Dangerous! Use only when 100% sure
```

### Use Collection If/For
```dart
✅ Good - Cleaner
final items = [
  'Always visible',
  if (showExtra) 'Conditional item',
  for (var i in numbers) 'Item $i',
];

❌ Bad - Verbose
final items = ['Always visible'];
if (showExtra) {
  items.add('Conditional item');
}
for (var i in numbers) {
  items.add('Item $i');
}
```

### Use Spread Operator
```dart
✅ Good
final allItems = [...oldItems, ...newItems];
final numbers = [1, 2, ...moreNumbers];

❌ Bad
final allItems = oldItems + newItems;  // Less efficient
```

### Avoid Dynamic
```dart
✅ Good - Type-safe
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'name': name,
  };
}

List<UserModel> users = [];

❌ Bad - Loses type safety
dynamic toMap() {  // Avoid dynamic
  return {
    'id': id,
    'name': name,
  };
}

List<dynamic> users = [];  // Avoid dynamic
```

---

## 6. Flutter Best Practices

### Extract Widgets
```dart
✅ Good - Reusable and readable
class UserCard extends StatelessWidget {
  final UserModel user;

  const UserCard({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(user.studyId),
        subtitle: Text(user.enrollmentCode),
      ),
    );
  }
}

// Usage
return ListView(
  children: users.map((user) => UserCard(user: user)).toList(),
);

❌ Bad - Everything in one widget
return ListView(
  children: users.map((user) => Card(
    child: ListTile(
      title: Text(user.studyId),
      subtitle: Text(user.enrollmentCode),
    ),
  )).toList(),
);
```

### Use Named Parameters
```dart
✅ Good - Clear and flexible
class MyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;

  const MyButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.color,
  }) : super(key: key);
}

// Clear usage
MyButton(
  text: 'Click me',
  onPressed: () => print('Clicked'),
  color: Colors.blue,
)

❌ Bad - Positional parameters
class MyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;

  const MyButton(this.text, this.onPressed, this.color);
}

// Unclear usage
MyButton('Click me', () => print('Clicked'), Colors.blue)
```

### Dispose Resources
```dart
✅ Good - Prevents memory leaks
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();  // Always dispose!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(controller: _controller);
  }
}

❌ Bad - Memory leak
class _MyWidgetState extends State<MyWidget> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(controller: _controller);
  }
  // Missing dispose()!
}
```

### Use Keys Appropriately
```dart
✅ Good - Keys for stateful widgets in lists
ListView(
  children: items.map((item) =>
    ItemWidget(
      key: ValueKey(item.id),
      item: item,
    )
  ).toList(),
)

// No key needed for stateless widgets
const Text('Hello')  // No key needed

❌ Bad - Keys everywhere
const Text('Hello', key: ValueKey('text'))  // Unnecessary
```

---

## 7. Error Handling

### Always Use Try-Catch for Async
```dart
✅ Good
Future<void> saveData() async {
  try {
    final db = await _databaseService.database;
    await db.insert('table', data);
    print('✅ Data saved');
  } catch (e) {
    print('❌ Error saving data: $e');
    rethrow;  // Let caller handle it
  }
}

❌ Bad - No error handling
Future<void> saveData() async {
  final db = await _databaseService.database;
  await db.insert('table', data);  // What if this fails?
}
```

### User-Friendly Error Messages
```dart
✅ Good
try {
  await enrollUser(code);
} catch (e) {
  _errorMessage = 'Failed to enroll. Please check your code and try again.';
}

❌ Bad - Technical error to user
try {
  await enrollUser(code);
} catch (e) {
  _errorMessage = e.toString();  // Shows technical error
}
```

### Validate Input Early
```dart
✅ Good
Future<void> enrollUser(String code) async {
  if (code.isEmpty) {
    throw ArgumentError('Enrollment code cannot be empty');
  }

  if (code.length < 8) {
    throw ArgumentError('Code must be at least 8 characters');
  }

  // Proceed with enrollment
}

❌ Bad - Validates after processing
Future<void> enrollUser(String code) async {
  // Process enrollment...
  if (code.isEmpty) {  // Too late!
    throw ArgumentError('Code cannot be empty');
  }
}
```

---

## 8. Quick Checklist

Before submitting code, verify:

**Naming:**
- [ ] Classes use UpperCamelCase
- [ ] Variables/methods use lowerCamelCase
- [ ] Private members prefixed with _
- [ ] Boolean names use is/has/can

**Formatting:**
- [ ] Run `flutter format .`
- [ ] Run `flutter analyze` (no warnings)
- [ ] Trailing commas on multiline code
- [ ] Imports organized and alphabetized

**Documentation:**
- [ ] Public methods have doc comments (///)
- [ ] TODOs clearly marked
- [ ] Comments explain WHY, not WHAT

**Best Practices:**
- [ ] Use const where possible
- [ ] Use final for immutable fields
- [ ] Null safety properly handled
- [ ] Resources disposed (TextControllers, etc.)
- [ ] Try-catch for all async operations

**Flutter Specific:**
- [ ] Complex widgets extracted into separate classes
- [ ] Named parameters for clarity
- [ ] Keys used for stateful widgets in lists
- [ ] No dynamic types

---

## 🛠️ Automated Tools

### Format Code
```bash
# Format all files
flutter format .

# Check formatting (CI/CD)
flutter format --set-exit-if-changed .
```

### Analyze Code
```bash
# Check for issues
flutter analyze

# Should output: "No issues found!"
```

### Fix Common Issues
```bash
# Fix many issues automatically
dart fix --apply
```

---

## 📚 References

- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Style Guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

---

**Remember:** Consistent code style makes code easier to read, maintain, and collaborate on! 🚀
