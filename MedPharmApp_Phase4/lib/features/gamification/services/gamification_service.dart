
import 'package:sqflite/sqflite.dart';
import '../../../core/services/database_service.dart';
import '../../assessment/services/assessment_service.dart';
import '../models/gamification_model.dart';

class GamificationService {
  final DatabaseService _databaseService;
  final AssessmentService _assessmentService;

  GamificationService(this._databaseService, this._assessmentService);

  Future<UserStatsModel> getOrCreateUserStats(String studyId) async {
    try {
      final db = await _databaseService.database;

      final results = await db.query(
        'user_stats',
        where: 'study_id = ?',
        whereArgs: [studyId],
        limit: 1,
      );

      if (results.isNotEmpty) {
        print('Found existing stats for $studyId');
        return UserStatsModel.fromMap(results.first);
      }

      print('Creating new stats for $studyId');
      final newStats = UserStatsModel(studyId: studyId);
      await db.insert('user_stats', newStats.toMap());
      return newStats;
    } catch (e) {
      print('Error getting/creating user stats: $e');
      rethrow;
    }
  }

  Future<void> saveUserStats(UserStatsModel stats) async {
    try {
      final db = await _databaseService.database;

      final updatedStats = stats.copyWith(updatedAt: DateTime.now());

      await db.insert(
        'user_stats',
        updatedStats.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('Stats saved: ${stats.totalPoints} points, level ${stats.level}');
    } catch (e) {
      print('Error saving user stats: $e');
      rethrow;
    }
  }

  Future<int> awardPointsForAssessment({
    required String studyId,
    bool isEarly = false,
  }) async {
    try {
      print('Awarding points for assessment (studyId: $studyId, isEarly: $isEarly)');

      final stats = await getOrCreateUserStats(studyId);

      int pointsToAward = PointValues.assessmentComplete; // Base: 100

      if (stats.totalAssessments == 0) {
        pointsToAward += PointValues.firstAssessment; // +200
        print('First assessment bonus: +${PointValues.firstAssessment}');
      }

      if (isEarly) {
        pointsToAward += PointValues.earlyBonus; // +50
        print('Early bird bonus: +${PointValues.earlyBonus}');
      }

      int newStreak = stats.currentStreak;
      final today = DateTime.now();
      final lastDate = stats.lastAssessmentDate;

      if (_wasYesterday(lastDate)) {
        newStreak = stats.currentStreak + 1;
        print('Streak continues: $newStreak days');
      } else if (_isToday(lastDate)) {
        // Already counted today - don't change streak
        print('Already counted today, streak unchanged');
      } else {
        // Streak broken - start new
        newStreak = 1;
        print('Streak reset to 1');
      }

      // Streak milestone bonuses
      if (newStreak == 3 && stats.currentStreak < 3) {
        pointsToAward += PointValues.streakBonus3Day;
        print(' 3-day streak bonus: +${PointValues.streakBonus3Day}');
      } else if (newStreak == 7 && stats.currentStreak < 7) {
        pointsToAward += PointValues.streakBonus7Day;
        print(' 7-day streak bonus: +${PointValues.streakBonus7Day}');
      } else if (newStreak == 14 && stats.currentStreak < 14) {
        pointsToAward += PointValues.streakBonus14Day;
        print(' 14-day streak bonus: +${PointValues.streakBonus14Day}');
      } else if (newStreak == 30 && stats.currentStreak < 30) {
        pointsToAward += PointValues.streakBonus30Day;
        print(' 30-day streak bonus: +${PointValues.streakBonus30Day}');
      }

      final newLongestStreak =
          newStreak > stats.longestStreak ? newStreak : stats.longestStreak;

      final updatedStats = stats.copyWith(
        totalPoints: stats.totalPoints + pointsToAward,
        currentStreak: newStreak,
        longestStreak: newLongestStreak,
        totalAssessments: stats.totalAssessments + 1,
        earlyCompletions: isEarly ? stats.earlyCompletions + 1 : stats.earlyCompletions,
        lastAssessmentDate: today,
        updatedAt: today,
      );

      await saveUserStats(updatedStats);

      print('Awarded $pointsToAward points. Total: ${updatedStats.totalPoints}');

      await checkAndAwardBadges(studyId);

      return pointsToAward;
    } catch (e) {
      print(' Error awarding points: $e');
      rethrow;
    }
  }

  Future<List<BadgeModel>> checkAndAwardBadges(String studyId) async {
    try {
      print(' Checking badges for $studyId');

      final stats = await getOrCreateUserStats(studyId);
      final earnedBadges = await getEarnedBadges(studyId);
      final earnedTypes = earnedBadges.map((b) => b.badgeType).toSet();
      final newBadges = <BadgeModel>[];

      // Helper to award badge if not already earned
      Future<void> awardIfNew(BadgeType type) async {
        if (!earnedTypes.contains(type)) {
          final badge = BadgeModel(studyId: studyId, badgeType: type);
          await saveBadge(badge);
          newBadges.add(badge);
          print(' New badge: ${type.displayName}');
        }
      }

      if (stats.totalAssessments >= 1) {
        await awardIfNew(BadgeType.firstAssessment);
      }
      if (stats.totalAssessments >= 10) {
        await awardIfNew(BadgeType.tenthAssessment);
      }
      if (stats.totalAssessments >= 25) {
        await awardIfNew(BadgeType.twentyFifthAssessment);
      }
      if (stats.totalAssessments >= 50) {
        await awardIfNew(BadgeType.fiftiethAssessment);
      }
      if (stats.totalAssessments >= 100) {
        await awardIfNew(BadgeType.hundredthAssessment);
      }

      // Streak badges (based on currentStreak)
      if (stats.currentStreak >= 3) {
        await awardIfNew(BadgeType.streak3Day);
      }
      if (stats.currentStreak >= 7) {
        await awardIfNew(BadgeType.streak7Day);
      }
      if (stats.currentStreak >= 14) {
        await awardIfNew(BadgeType.streak14Day);
      }
      if (stats.currentStreak >= 30) {
        await awardIfNew(BadgeType.streak30Day);
      }

      // Special badges
      if (stats.earlyCompletions >= 5) {
        await awardIfNew(BadgeType.earlyBird);
      }
      if (stats.longestStreak >= 30) {
        await awardIfNew(BadgeType.dedicated);
      }

      // Perfect week badge - check weekly completion
      final weeklyCompletion = await getWeeklyCompletion(studyId);
      if (weeklyCompletion.length == 7 && weeklyCompletion.values.every((v) => v)) {
        await awardIfNew(BadgeType.perfectWeek);
      }

      print(' Awarded ${newBadges.length} new badges');
      return newBadges;
    } catch (e) {
      print('Error checking badges: $e');
      return [];
    }
  }

  Future<List<BadgeModel>> getEarnedBadges(String studyId) async {
    try {
      final db = await _databaseService.database;

      final results = await db.query(
        'user_badges',
        where: 'study_id = ?',
        whereArgs: [studyId],
        orderBy: 'earned_at DESC',
      );

      final badges = results.map((map) => BadgeModel.fromMap(map)).toList();
      print('Loaded ${badges.length} earned badges');
      return badges;
    } catch (e) {
      print('Error getting earned badges: $e');
      return [];
    }
  }

  Future<void> saveBadge(BadgeModel badge) async {
    try {
      final db = await _databaseService.database;

      await db.insert(
        'user_badges',
        badge.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore, // Prevent duplicates
      );

      print('Badge saved: ${badge.badgeType.displayName}');
    } catch (e) {
      print('Error saving badge: $e');
      rethrow;
    }
  }

  Future<int> calculateCurrentStreak(String studyId) async {
    try {
      final assessments = await _assessmentService.getAssessmentHistory(
        studyId,
        limit: 100, 
      );

      if (assessments.isEmpty) {
        return 0;
      }

      int streak = 0;
      DateTime checkDate = DateTime.now();

      bool hasToday = assessments.any((a) => _isSameDay(a.timestamp, checkDate));
      
      if (!hasToday) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        bool hasYesterday = assessments.any((a) => _isSameDay(a.timestamp, checkDate));
        if (!hasYesterday) {
          return 0;
        }
      }

      while (true) {
        bool hasAssessment = assessments.any((a) => _isSameDay(a.timestamp, checkDate));
        if (hasAssessment) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      print('Calculated streak: $streak days');
      return streak;
    } catch (e) {
      print('Error calculating streak: $e');
      return 0;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _wasYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _isSameDay(date, yesterday);
  }

  bool _isToday(DateTime date) {
    return _isSameDay(date, DateTime.now());
  }

  Future<double> getCompletionPercentage(String studyId) async {
    try {
      final stats = await getOrCreateUserStats(studyId);
      final daysSinceCreation = DateTime.now().difference(stats.createdAt).inDays + 1;

      if (daysSinceCreation <= 0) return 0.0;

      final percentage = (stats.totalAssessments / daysSinceCreation) * 100;
      return percentage.clamp(0.0, 100.0);
    } catch (e) {
      print('Error calculating completion percentage: $e');
      return 0.0;
    }
  }

  Future<Map<String, bool>> getWeeklyCompletion(String studyId) async {
    try {
      final assessments = await _assessmentService.getRecentAssessments(
        studyId,
        days: 7,
      );

      final completion = <String, bool>{};
      final today = DateTime.now();

      for (int i = 0; i < 7; i++) {
        final date = today.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final hasAssessment = assessments.any((a) => _isSameDay(a.timestamp, date));
        completion[dateKey] = hasAssessment;
      }

      return completion;
    } catch (e) {
      print('Error getting weekly completion: $e');
      return {};
    }
  }

  Future<void> deleteUserGamificationData(String studyId) async {
    try {
      final db = await _databaseService.database;
      await db.delete('user_stats', where: 'study_id = ?', whereArgs: [studyId]);
      await db.delete('user_badges', where: 'study_id = ?', whereArgs: [studyId]);
      print('Gamification data deleted for $studyId');
    } catch (e) {
      print('Error deleting gamification data: $e');
      rethrow;
    }
  }
}
