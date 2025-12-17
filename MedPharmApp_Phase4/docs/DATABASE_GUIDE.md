# SQLite Database Guide for Students

**Purpose:** Learn SQLite fundamentals and patterns used in this app
**Package:** sqflite (Flutter's SQLite plugin)

---

## 📋 Table of Contents

1. [SQL Basics](#sql-basics)
2. [CRUD Operations](#crud-operations)
3. [Querying Patterns](#querying-patterns)
4. [Data Types & Conversions](#data-types--conversions)
5. [Common Patterns](#common-patterns)
6. [Database Best Practices](#database-best-practices)
7. [Debugging Database](#debugging-database)

---

## 1. SQL Basics

### What is SQL?

**SQL** = Structured Query Language
- Language for managing databases
- Used to CREATE, READ, UPDATE, DELETE data
- Works with tables (like Excel spreadsheets)

### Database Structure

```
Database: medpharm.db
├── Table: user_session
│   ├── Column: id (INTEGER)
│   ├── Column: study_id (TEXT)
│   ├── Column: enrollment_code (TEXT)
│   └── ...
├── Table: assessments
│   ├── Column: id (TEXT)
│   ├── Column: nrs_score (INTEGER)
│   └── ...
└── Table: gamification_progress
    └── ...
```

### Table Anatomy

```sql
CREATE TABLE user_session (
  id INTEGER PRIMARY KEY AUTOINCREMENT,  -- Primary key (unique identifier)
  study_id TEXT NOT NULL UNIQUE,         -- Required, must be unique
  enrollment_code TEXT NOT NULL,         -- Required
  enrolled_at TEXT NOT NULL,             -- Required
  consent_accepted INTEGER DEFAULT 0,    -- Optional (defaults to 0)
  created_at TEXT DEFAULT CURRENT_TIMESTAMP  -- Auto-generated
);
```

**Parts:**
- `CREATE TABLE` - Make a new table
- `table_name` - Name of the table
- `column_name TYPE constraints` - Each column definition

**Column Constraints:**
- `PRIMARY KEY` - Unique identifier for each row
- `AUTOINCREMENT` - Auto-generate increasing numbers
- `NOT NULL` - Value required (can't be null)
- `UNIQUE` - No duplicates allowed
- `DEFAULT value` - Use this if no value provided

---

## 2. CRUD Operations

### C - CREATE (Insert Data)

**SQL:**
```sql
INSERT INTO user_session (study_id, enrollment_code, enrolled_at)
VALUES ('STUDY123', 'ABC12345', '2024-11-06T10:00:00.000Z');
```

**Dart (sqflite):**
```dart
// Method 1: Using insert() - recommended
await db.insert(
  'user_session',      // Table name
  {                    // Data as Map
    'study_id': 'STUDY123',
    'enrollment_code': 'ABC12345',
    'enrolled_at': DateTime.now().toIso8601String(),
  },
  conflictAlgorithm: ConflictAlgorithm.replace,  // What if already exists?
);

// Method 2: Raw SQL
await db.rawInsert(
  'INSERT INTO user_session (study_id, enrollment_code) VALUES (?, ?)',
  ['STUDY123', 'ABC12345'],
);
```

**Conflict Algorithms:**
- `ConflictAlgorithm.replace` - Replace if exists
- `ConflictAlgorithm.fail` - Throw error if exists
- `ConflictAlgorithm.ignore` - Skip if exists
- `ConflictAlgorithm.abort` - Cancel transaction if exists

---

### R - READ (Query Data)

**SQL:**
```sql
-- Get all rows
SELECT * FROM user_session;

-- Get specific columns
SELECT study_id, enrollment_code FROM user_session;

-- Get with condition
SELECT * FROM user_session WHERE study_id = 'STUDY123';

-- Get with limit
SELECT * FROM user_session LIMIT 1;
```

**Dart (sqflite):**
```dart
// Get all rows
final allUsers = await db.query('user_session');

// Get specific columns
final ids = await db.query(
  'user_session',
  columns: ['study_id', 'enrollment_code'],
);

// Get with WHERE condition
final results = await db.query(
  'user_session',
  where: 'study_id = ?',  // ? is placeholder
  whereArgs: ['STUDY123'],  // Values for placeholders
);

// Get one row
final user = await db.query('user_session', limit: 1);

// Get with multiple conditions
final results = await db.query(
  'user_session',
  where: 'study_id = ? AND consent_accepted = ?',
  whereArgs: ['STUDY123', 1],
);

// Get with ordering
final sorted = await db.query(
  'assessments',
  orderBy: 'timestamp DESC',  // Newest first
);

// Complex query
final results = await db.query(
  'assessments',
  where: 'is_synced = ? AND timestamp > ?',
  whereArgs: [0, yesterday.toIso8601String()],
  orderBy: 'timestamp DESC',
  limit: 10,
);
```

**Query Results:**
```dart
// query() returns List<Map<String, dynamic>>
final results = await db.query('user_session');

// Each item is a Map
// results = [
//   {'id': 1, 'study_id': 'STUDY123', 'enrollment_code': 'ABC12345'},
//   {'id': 2, 'study_id': 'STUDY456', 'enrollment_code': 'DEF67890'},
// ]

// Check if empty
if (results.isEmpty) {
  print('No results found');
  return null;
}

// Get first result
final firstUser = results.first;
print(firstUser['study_id']);  // 'STUDY123'

// Convert to model
final user = UserModel.fromMap(results.first);
```

---

### U - UPDATE (Modify Data)

**SQL:**
```sql
UPDATE user_session
SET consent_accepted = 1, consent_accepted_at = '2024-11-06T11:00:00.000Z'
WHERE study_id = 'STUDY123';
```

**Dart (sqflite):**
```dart
// Update specific row
final rowsUpdated = await db.update(
  'user_session',
  {                              // New values
    'consent_accepted': 1,
    'consent_accepted_at': DateTime.now().toIso8601String(),
  },
  where: 'study_id = ?',         // Which row(s) to update
  whereArgs: ['STUDY123'],
);

print('Updated $rowsUpdated rows');  // Usually 1

// Update multiple rows
await db.update(
  'assessments',
  {'is_synced': 1},
  where: 'is_synced = ?',
  whereArgs: [0],  // Update all unsynced assessments
);
```

---

### D - DELETE (Remove Data)

**SQL:**
```sql
DELETE FROM user_session WHERE study_id = 'STUDY123';
```

**Dart (sqflite):**
```dart
// Delete specific row
final rowsDeleted = await db.delete(
  'user_session',
  where: 'study_id = ?',
  whereArgs: ['STUDY123'],
);

// Delete all rows (careful!)
await db.delete('user_session');  // Deletes everything!

// Delete with multiple conditions
await db.delete(
  'assessments',
  where: 'timestamp < ? AND is_synced = ?',
  whereArgs: [oldDate.toIso8601String(), 1],
);
```

---

## 3. Querying Patterns

### Pattern 1: Get Single Record

```dart
Future<UserModel?> getCurrentUser() async {
  final db = await _databaseService.database;

  // Query with limit 1
  final results = await db.query('user_session', limit: 1);

  // Check if empty
  if (results.isEmpty) {
    return null;  // No user found
  }

  // Convert first result to model
  return UserModel.fromMap(results.first);
}
```

### Pattern 2: Get Multiple Records

```dart
Future<List<AssessmentModel>> getAssessments() async {
  final db = await _databaseService.database;

  // Query all or with conditions
  final results = await db.query(
    'assessments',
    orderBy: 'timestamp DESC',
    limit: 30,
  );

  // Convert each map to model
  return results.map((map) => AssessmentModel.fromMap(map)).toList();
}
```

### Pattern 3: Check if Exists

```dart
Future<bool> userExists(String studyId) async {
  final db = await _databaseService.database;

  final results = await db.query(
    'user_session',
    where: 'study_id = ?',
    whereArgs: [studyId],
  );

  return results.isNotEmpty;  // true if exists
}
```

### Pattern 4: Count Records

```dart
Future<int> countAssessments() async {
  final db = await _databaseService.database;

  final result = await db.rawQuery(
    'SELECT COUNT(*) as count FROM assessments'
  );

  return result.first['count'] as int;
}
```

### Pattern 5: Get Today's Records

```dart
Future<List<AssessmentModel>> getTodayAssessments() async {
  final db = await _databaseService.database;

  // Calculate start and end of today
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(Duration(days: 1));

  final results = await db.query(
    'assessments',
    where: 'timestamp >= ? AND timestamp < ?',
    whereArgs: [
      startOfDay.toIso8601String(),
      endOfDay.toIso8601String(),
    ],
  );

  return results.map((map) => AssessmentModel.fromMap(map)).toList();
}
```

---

## 4. Data Types & Conversions

### SQLite Data Types

SQLite only has 5 data types:
1. **NULL** - Null value
2. **INTEGER** - Whole numbers (-9223372036854775808 to 9223372036854775807)
3. **REAL** - Floating point numbers
4. **TEXT** - Strings
5. **BLOB** - Binary data

### Dart ↔ SQLite Conversions

| Dart Type | SQLite Type | Save to DB | Read from DB |
|-----------|-------------|------------|--------------|
| int | INTEGER | Direct | `as int` |
| double | REAL | Direct | `as double` |
| String | TEXT | Direct | `as String` |
| bool | INTEGER | `value ? 1 : 0` | `value == 1` |
| DateTime | TEXT | `toIso8601String()` | `DateTime.parse()` |
| enum | TEXT | `toString()` | Parse string |
| List | TEXT | `jsonEncode()` | `jsonDecode()` |
| Map | TEXT | `jsonEncode()` | `jsonDecode()` |

### Conversion Examples

**Boolean:**
```dart
// Save
final map = {
  'consent_accepted': consentAccepted ? 1 : 0,  // true → 1, false → 0
};

// Read
final consentAccepted = map['consent_accepted'] == 1;  // 1 → true, 0 → false
```

**DateTime:**
```dart
// Save
final map = {
  'enrolled_at': DateTime.now().toIso8601String(),  // '2024-11-06T10:00:00.000Z'
};

// Read
final enrolledAt = DateTime.parse(map['enrolled_at'] as String);
```

**Nullable DateTime:**
```dart
// Save
final map = {
  'consent_accepted_at': consentAcceptedAt?.toIso8601String(),  // null or string
};

// Read
final consentAcceptedAt = map['consent_accepted_at'] != null
    ? DateTime.parse(map['consent_accepted_at'] as String)
    : null;
```

**List (JSON):**
```dart
import 'dart:convert';

// Save
final map = {
  'tags': jsonEncode(['tag1', 'tag2', 'tag3']),  // '["tag1","tag2","tag3"]'
};

// Read
final tags = (jsonDecode(map['tags'] as String) as List)
    .map((item) => item as String)
    .toList();
```

---

## 5. Common Patterns

### Pattern: Upsert (Insert or Update)

```dart
Future<void> saveUser(UserModel user) async {
  final db = await _databaseService.database;

  // Check if exists
  final existing = await db.query(
    'user_session',
    where: 'study_id = ?',
    whereArgs: [user.studyId],
  );

  if (existing.isEmpty) {
    // Insert new
    await db.insert('user_session', user.toMap());
  } else {
    // Update existing
    await db.update(
      'user_session',
      user.toMap(),
      where: 'study_id = ?',
      whereArgs: [user.studyId],
    );
  }
}

// Or use conflict algorithm
await db.insert(
  'user_session',
  user.toMap(),
  conflictAlgorithm: ConflictAlgorithm.replace,  // Replaces if exists
);
```

### Pattern: Batch Operations

```dart
Future<void> saveMultipleAssessments(List<AssessmentModel> assessments) async {
  final db = await _databaseService.database;

  final batch = db.batch();

  for (var assessment in assessments) {
    batch.insert('assessments', assessment.toMap());
  }

  // Execute all at once (faster)
  await batch.commit(noResult: true);
}
```

### Pattern: Transactions

```dart
Future<void> enrollUserWithProgress(UserModel user) async {
  final db = await _databaseService.database;

  await db.transaction((txn) async {
    // Insert user
    await txn.insert('user_session', user.toMap());

    // Create initial progress
    await txn.insert('gamification_progress', {
      'study_id': user.studyId,
      'total_points': 0,
      'current_level': 1,
    });

    // If either fails, both are rolled back
  });
}
```

---

## 6. Database Best Practices

### ✅ DO: Use Parameterized Queries

```dart
✅ Good - Safe from SQL injection
await db.query(
  'user_session',
  where: 'study_id = ?',
  whereArgs: [userInput],  // Safely escaped
);

❌ Bad - SQL injection risk!
await db.rawQuery(
  "SELECT * FROM user_session WHERE study_id = '$userInput'"
);  // User could inject malicious SQL!
```

### ✅ DO: Use Indexes for Faster Queries

```dart
// In database creation
await db.execute('''
  CREATE INDEX idx_assessments_timestamp
  ON assessments(timestamp)
''');

// Now queries on timestamp are much faster
final results = await db.query(
  'assessments',
  where: 'timestamp > ?',
  whereArgs: [date],
);
```

### ✅ DO: Handle Errors

```dart
Future<UserModel?> getUser() async {
  try {
    final db = await _databaseService.database;
    final results = await db.query('user_session');

    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  } catch (e) {
    print('❌ Error getting user: $e');
    rethrow;  // Let caller handle it
  }
}
```

### ✅ DO: Close Database (if needed)

```dart
// Usually only when app is closing
await _databaseService.close();
```

### ❌ DON'T: Store Sensitive Data Unencrypted

```dart
❌ Bad - Plain text passwords
await db.insert('users', {
  'password': 'MyPassword123',  // Never do this!
});

✅ Better - Use secure storage or encryption
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
final storage = FlutterSecureStorage();
await storage.write(key: 'password', value: password);
```

### ❌ DON'T: Use Dynamic Types

```dart
❌ Bad - Loses type safety
dynamic value = map['id'];

✅ Good - Explicit types
final id = map['id'] as int?;
final name = map['name'] as String;
```

---

## 7. Debugging Database

### Technique 1: Print Queries

```dart
Future<void> getUsers() async {
  final results = await db.query('user_session');

  print('📊 Query Results: $results');
  // [{id: 1, study_id: STUDY123, ...}]

  print('📊 Number of results: ${results.length}');
}
```

### Technique 2: View Database File

**Android Studio:**
1. Run app in debug mode
2. View → Tool Windows → App Inspection
3. Database Inspector tab
4. Select your database
5. Browse tables and data

**Manual (using adb):**
```bash
# Android
adb shell
cd /data/data/pl.agh.mdaniol.med_pharm_app/databases/
sqlite3 medpharm.db
.tables
SELECT * FROM user_session;
.quit
```

### Technique 3: Export Database

```dart
Future<void> exportDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'medpharm.db');

  final file = File(path);
  final bytes = await file.readAsBytes();

  // Save to downloads or share
  print('Database at: $path');
  print('Size: ${bytes.length} bytes');
}
```

### Technique 4: Reset Database (for testing)

```dart
Future<void> resetDatabase() async {
  // Close and delete
  await _databaseService.close();
  await _databaseService.deleteDatabase();

  // Reinitialize (creates fresh database)
  await _databaseService.database;

  print('🔄 Database reset!');
}
```

---

## 🎓 Practice Exercises

### Exercise 1: Count Completed Assessments
Write a method that counts how many assessments a user has completed.

<details>
<summary>Solution</summary>

```dart
Future<int> countCompletedAssessments(String studyId) async {
  final db = await _databaseService.database;

  final result = await db.rawQuery(
    'SELECT COUNT(*) as count FROM assessments WHERE study_id = ?',
    [studyId],
  );

  return result.first['count'] as int;
}
```
</details>

### Exercise 2: Get Unsynced Assessments
Write a method that gets all assessments that haven't been synced yet.

<details>
<summary>Solution</summary>

```dart
Future<List<AssessmentModel>> getUnsyncedAssessments() async {
  final db = await _databaseService.database;

  final results = await db.query(
    'assessments',
    where: 'is_synced = ?',
    whereArgs: [0],
  );

  return results.map((map) => AssessmentModel.fromMap(map)).toList();
}
```
</details>

### Exercise 3: Update All Unsynced to Synced
Write a method that marks all unsynced assessments as synced.

<details>
<summary>Solution</summary>

```dart
Future<int> markAllAsSynced() async {
  final db = await _databaseService.database;

  return await db.update(
    'assessments',
    {'is_synced': 1},
    where: 'is_synced = ?',
    whereArgs: [0],
  );
}
```
</details>

---

## 📚 SQL Quick Reference

```sql
-- CREATE TABLE
CREATE TABLE table_name (
  column1 TYPE constraint,
  column2 TYPE constraint
);

-- INSERT
INSERT INTO table_name (col1, col2) VALUES (val1, val2);

-- SELECT
SELECT * FROM table_name;
SELECT col1, col2 FROM table_name WHERE condition;

-- UPDATE
UPDATE table_name SET col1 = val1 WHERE condition;

-- DELETE
DELETE FROM table_name WHERE condition;

-- DROP TABLE
DROP TABLE table_name;

-- CREATE INDEX
CREATE INDEX index_name ON table_name(column);
```

---

## 🔗 Resources

- [SQLite Tutorial](https://www.sqlitetutorial.net/)
- [sqflite Package Docs](https://pub.dev/packages/sqflite)
- [SQL Cheat Sheet](https://www.sqltutorial.org/sql-cheat-sheet/)

---

**Remember:** SQL is a powerful tool. Always use parameterized queries and handle errors properly! 🗄️
