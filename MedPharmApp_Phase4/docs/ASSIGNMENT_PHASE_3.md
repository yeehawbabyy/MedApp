# Phase 3: Gamification System

## Overview

In Phase 3, you will implement a gamification system to encourage daily assessment completion. This includes points, levels, streaks, and achievement badges. The scaffolding level is 30%, meaning you have less guidance than in previous phases and are expected to apply patterns you learned independently.

**Estimated Time:** 3-4 hours

## Prerequisites

Before starting Phase 3, you must have completed:
- Phase 1: Authentication (enrollment, consent)
- Phase 2: Pain Assessment (NRS, VAS, history)

If you skipped earlier phases, the code may not work correctly.

## Learning Goals

By completing Phase 3, you will learn:
1. Working with multiple related models (UserStatsModel, BadgeModel)
2. Implementing complex business logic (streak calculation, badge conditions)
3. Using enums with extensions for type-safe constants
4. Building custom UI components (calendar, progress charts)
5. Coordinating multiple providers in screens

## Project Structure

Phase 3 adds the following files:

```
lib/features/gamification/
├── models/
│   └── gamification_model.dart      # UserStatsModel, BadgeModel, BadgeType enum
├── services/
│   └── gamification_service.dart    # Database operations for gamification
├── providers/
│   └── gamification_provider.dart   # State management for UI
└── screens/
    ├── home_screen.dart             # Main dashboard after onboarding
    ├── badge_gallery_screen.dart    # Display all badges (earned/locked)
    └── progress_screen.dart         # Stats, calendar, streak info
```

## What You Need to Implement

### Step 1: GamificationModel (gamification_model.dart)

**File:** `lib/features/gamification/models/gamification_model.dart`

You need to implement 3 methods:

#### TODO 1: UserStatsModel.fromMap()
Convert a database Map to a UserStatsModel. This follows the same pattern as Phase 1 and 2.

```dart
factory UserStatsModel.fromMap(Map<String, dynamic> map) {
  return UserStatsModel(
    odId: map['id'] as String,
    studyId: map['study_id'] as String,
    totalPoints: map['total_points'] as int,
    currentStreak: map['current_streak'] as int,
    longestStreak: map['longest_streak'] as int,
    totalAssessments: map['total_assessments'] as int,
    earlyCompletions: map['early_completions'] as int,
    lastAssessmentDate: DateTime.parse(map['last_assessment_date'] as String),
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );
}
```

#### TODO 2: UserStatsModel.copyWith()
Create a copy of the model with some fields updated. Same pattern as Phase 1 and 2.

```dart
UserStatsModel copyWith({
  String? odId,
  String? studyId,
  int? totalPoints,
  // ... other parameters
}) {
  return UserStatsModel(
    odId: odId ?? this.odId,
    studyId: studyId ?? this.studyId,
    totalPoints: totalPoints ?? this.totalPoints,
    // ... other fields
  );
}
```

#### TODO 3: BadgeModel.fromMap()
Convert a database Map to a BadgeModel. Note the enum conversion:

```dart
factory BadgeModel.fromMap(Map<String, dynamic> map) {
  return BadgeModel(
    id: map['id'] as String,
    studyId: map['study_id'] as String,
    badgeType: BadgeType.values.firstWhere(
      (e) => e.name == map['badge_type'],
    ),
    earnedAt: DateTime.parse(map['earned_at'] as String),
  );
}
```

### Step 2: GamificationService (gamification_service.dart)

**File:** `lib/features/gamification/services/gamification_service.dart`

You need to implement 5 methods:

#### TODO 1: awardPointsForAssessment()
This is the main method called after each assessment. Steps:
1. Get current user stats
2. Calculate points (base 100, +50 if early, +200 if first)
3. Update streak (increment if yesterday, reset if missed)
4. Update longestStreak if currentStreak is higher
5. Increment totalAssessments
6. Save updated stats
7. Check for new badges
8. Return points awarded

Key logic for streak calculation:
```dart
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

final yesterday = DateTime.now().subtract(Duration(days: 1));
if (isSameDay(stats.lastAssessmentDate, yesterday)) {
  // Increment streak
} else if (isSameDay(stats.lastAssessmentDate, DateTime.now())) {
  // Same day, don't change streak
} else {
  // Missed day(s), reset streak to 1
}
```

#### TODO 2: checkAndAwardBadges()
Check all badge conditions and award new ones:

```dart
Future<List<BadgeModel>> checkAndAwardBadges(String studyId) async {
  final stats = await getOrCreateUserStats(studyId);
  final earnedBadges = await getEarnedBadges(studyId);
  final earnedTypes = earnedBadges.map((b) => b.badgeType).toSet();
  final newBadges = <BadgeModel>[];

  // Milestone badges
  if (stats.totalAssessments >= 1 && !earnedTypes.contains(BadgeType.firstAssessment)) {
    final badge = BadgeModel(studyId: studyId, badgeType: BadgeType.firstAssessment);
    await saveBadge(badge);
    newBadges.add(badge);
  }

  // Check other milestone badges (10, 25, 50, 100)
  // Check streak badges (3, 7, 14, 30 days)
  // Check special badges (earlyBird, perfectWeek, dedicated)

  return newBadges;
}
```

#### TODO 3: getEarnedBadges()
Query the user_badges table for all earned badges:

```dart
Future<List<BadgeModel>> getEarnedBadges(String studyId) async {
  final db = await _databaseService.database;
  final results = await db.query(
    'user_badges',
    where: 'study_id = ?',
    whereArgs: [studyId],
    orderBy: 'earned_at DESC',
  );
  return results.map((map) => BadgeModel.fromMap(map)).toList();
}
```

#### TODO 4: saveBadge()
Insert a new badge into the database:

```dart
Future<void> saveBadge(BadgeModel badge) async {
  final db = await _databaseService.database;
  await db.insert(
    'user_badges',
    badge.toMap(),
    conflictAlgorithm: ConflictAlgorithm.ignore,  // Prevent duplicates
  );
}
```

#### TODO 5: calculateCurrentStreak()
Calculate streak by checking consecutive days with assessments:

```dart
Future<int> calculateCurrentStreak(String studyId) async {
  final assessments = await _assessmentService.getAssessmentHistory(studyId);
  if (assessments.isEmpty) return 0;

  int streak = 0;
  DateTime checkDate = DateTime.now();

  while (true) {
    final hasAssessment = assessments.any((a) =>
      a.timestamp.year == checkDate.year &&
      a.timestamp.month == checkDate.month &&
      a.timestamp.day == checkDate.day
    );

    if (hasAssessment) {
      streak++;
      checkDate = checkDate.subtract(Duration(days: 1));
    } else if (streak == 0) {
      // Today not completed yet, check from yesterday
      checkDate = checkDate.subtract(Duration(days: 1));
    } else {
      break;  // Streak broken
    }
  }

  return streak;
}
```

### Step 3: GamificationProvider (gamification_provider.dart)

**File:** `lib/features/gamification/providers/gamification_provider.dart`

You need to implement 3 methods:

#### TODO 1: recordAssessmentCompletion()
Called after assessment submission:

```dart
Future<void> recordAssessmentCompletion({
  required String studyId,
  bool isEarly = false,
}) async {
  try {
    _isLoading = true;
    _newlyEarnedBadges = [];
    notifyListeners();

    final points = await _gamificationService.awardPointsForAssessment(
      studyId: studyId,
      isEarly: isEarly,
    );
    _lastPointsAwarded = points;

    final newBadges = await _gamificationService.checkAndAwardBadges(studyId);
    _newlyEarnedBadges = newBadges;

    await loadUserStats(studyId);

    _isLoading = false;
    notifyListeners();
  } catch (e) {
    _isLoading = false;
    _errorMessage = 'Failed to record completion';
    notifyListeners();
  }
}
```

#### TODO 2: refreshGamificationData()
Reload all data from database:

```dart
Future<void> refreshGamificationData(String studyId) async {
  try {
    _isLoading = true;
    notifyListeners();

    final stats = await _gamificationService.getOrCreateUserStats(studyId);
    _userStats = stats;

    final badges = await _gamificationService.getEarnedBadges(studyId);
    _earnedBadges = badges;

    _isLoading = false;
    notifyListeners();
  } catch (e) {
    _isLoading = false;
    _errorMessage = 'Failed to refresh data';
    notifyListeners();
  }
}
```

#### TODO 3: clearNewBadges()
Clear the celebration state after showing:

```dart
void clearNewBadges() {
  _newlyEarnedBadges = [];
  _lastPointsAwarded = 0;
  notifyListeners();
}
```

### Step 4: HomeScreen (home_screen.dart)

**File:** `lib/features/gamification/screens/home_screen.dart`

#### TODO 1: _loadData()
Load gamification and assessment data when screen opens:

```dart
Future<void> _loadData() async {
  final authProvider = context.read<AuthProvider>();
  final gamificationProvider = context.read<GamificationProvider>();
  final assessmentProvider = context.read<AssessmentProvider>();

  final studyId = authProvider.currentUser?.studyId;
  if (studyId != null) {
    await gamificationProvider.loadUserStats(studyId);
    await assessmentProvider.loadTodayAssessment(studyId);
  }
}
```

The remaining TODOs (2-8) in HomeScreen are already completed in the scaffolding. Review them to understand the patterns used.

## Database Tables

Phase 3 uses two new tables (already added to database_service.dart):

**user_stats table:**
```sql
CREATE TABLE user_stats (
  id TEXT PRIMARY KEY,
  study_id TEXT NOT NULL UNIQUE,
  total_points INTEGER DEFAULT 0,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  total_assessments INTEGER DEFAULT 0,
  early_completions INTEGER DEFAULT 0,
  last_assessment_date TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

**user_badges table:**
```sql
CREATE TABLE user_badges (
  id TEXT PRIMARY KEY,
  study_id TEXT NOT NULL,
  badge_type TEXT NOT NULL,
  earned_at TEXT NOT NULL,
  UNIQUE(study_id, badge_type)
)
```

## Points System

| Action | Points |
|--------|--------|
| Complete assessment | 100 |
| Early completion bonus | +50 |
| First assessment bonus | +200 |
| Weekly completion bonus | +500 |
| 3-day streak bonus | +150 |
| 7-day streak bonus | +300 |
| 14-day streak bonus | +500 |
| 30-day streak bonus | +1000 |

## Badge Conditions

| Badge | Condition |
|-------|-----------|
| First Steps | Complete 1 assessment |
| Getting Started | Complete 10 assessments |
| Quarter Century | Complete 25 assessments |
| Halfway Hero | Complete 50 assessments |
| Century Club | Complete 100 assessments |
| 3-Day Streak | 3 consecutive days |
| 7-Day Streak | 7 consecutive days |
| 14-Day Streak | 14 consecutive days |
| 30-Day Streak | 30 consecutive days |
| Early Bird | 5 early completions |
| Perfect Week | All 7 days in a week |
| Dedicated | 30-day longest streak |

## Testing Your Implementation

1. **Reset the database** (important if upgrading from Phase 2):
   - Delete the app from your device/emulator
   - Run `flutter clean && flutter pub get`
   - Run the app fresh

2. **Test basic flow:**
   - Enroll and accept consent
   - Navigate to home screen (update consent_screen.dart navigation if needed)
   - Complete an assessment
   - Verify points increase
   - Check badge gallery

3. **Test streak logic:**
   - Complete assessment today (streak should be 1)
   - Manually update database to simulate yesterday's assessment
   - Complete another assessment (streak should be 2)

4. **Test badges:**
   - First assessment should award "First Steps" badge
   - Check badge appears in gallery
   - Check badge celebration UI

## Common Issues

**"Provider not found" error:**
- Ensure GamificationService and GamificationProvider are in main.dart
- Check the order - services must come before providers that use them

**Database errors after upgrading:**
- The new tables are only created on fresh install
- Delete the app and reinstall to get new tables

**Streak not calculating correctly:**
- Check date comparison logic
- Remember: compare year, month, AND day
- Use DateTime.now().subtract(Duration(days: 1)) for yesterday

**Badges not appearing:**
- Verify getEarnedBadges() returns correct data
- Check that saveBadge() uses ConflictAlgorithm.ignore
- Ensure badge_type string matches enum name exactly

## Navigation Flow

After Phase 3, the recommended flow is:
1. Enrollment Screen -> Consent Screen -> Home Screen
2. From Home Screen: Start Assessment, View History, View Badges, View Progress

Update the consent_screen.dart to navigate to '/home' after consent is accepted:
```dart
// In _handleAcceptConsent(), after success:
Navigator.pushReplacementNamed(context, '/home');
```

## Success Criteria

Your Phase 3 implementation is complete when:
- Points are awarded after each assessment
- Level increases based on total points
- Streak tracks consecutive days correctly
- Badges are awarded at correct milestones
- Home screen displays current stats
- Badge gallery shows earned and locked badges
- Progress screen shows completion calendar and stats

## What You Learned

After completing Phase 3, you should understand:
1. How to work with enum types and extensions
2. Complex date calculations for streaks
3. Conditional badge logic
4. Building custom UI components (calendar, progress bars)
5. Coordinating multiple providers in a single screen
6. The complete feature-first architecture pattern

## Next Steps

After Phase 3, you can optionally explore:
- Adding notifications for daily reminders
- Implementing a tutorial screen
- Adding settings screen with notification preferences
- Creating animations for level-up and badge celebrations
