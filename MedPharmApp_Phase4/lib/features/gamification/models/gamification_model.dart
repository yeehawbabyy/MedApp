
enum BadgeType {
  streak3Day,
  streak7Day,
  streak14Day,
  streak30Day,

  firstAssessment,
  tenthAssessment,
  twentyFifthAssessment,
  fiftiethAssessment,
  hundredthAssessment,

  earlyBird,      
  perfectWeek,    
  dedicated,    
}

extension BadgeTypeExtension on BadgeType {
  String get displayName {
    switch (this) {
      case BadgeType.streak3Day:
        return '3-Day Streak';
      case BadgeType.streak7Day:
        return '7-Day Streak';
      case BadgeType.streak14Day:
        return '14-Day Streak';
      case BadgeType.streak30Day:
        return '30-Day Streak';
      case BadgeType.firstAssessment:
        return 'First Steps';
      case BadgeType.tenthAssessment:
        return 'Getting Started';
      case BadgeType.twentyFifthAssessment:
        return 'Quarter Century';
      case BadgeType.fiftiethAssessment:
        return 'Halfway Hero';
      case BadgeType.hundredthAssessment:
        return 'Century Club';
      case BadgeType.earlyBird:
        return 'Early Bird';
      case BadgeType.perfectWeek:
        return 'Perfect Week';
      case BadgeType.dedicated:
        return 'Dedicated';
    }
  }

  String get description {
    switch (this) {
      case BadgeType.streak3Day:
        return 'Complete assessments for 3 consecutive days';
      case BadgeType.streak7Day:
        return 'Complete assessments for 7 consecutive days';
      case BadgeType.streak14Day:
        return 'Complete assessments for 14 consecutive days';
      case BadgeType.streak30Day:
        return 'Complete assessments for 30 consecutive days';
      case BadgeType.firstAssessment:
        return 'Complete your first assessment';
      case BadgeType.tenthAssessment:
        return 'Complete 10 assessments';
      case BadgeType.twentyFifthAssessment:
        return 'Complete 25 assessments';
      case BadgeType.fiftiethAssessment:
        return 'Complete 50 assessments';
      case BadgeType.hundredthAssessment:
        return 'Complete 100 assessments';
      case BadgeType.earlyBird:
        return 'Complete 5 assessments early in the day';
      case BadgeType.perfectWeek:
        return 'Complete all assessments in a week';
      case BadgeType.dedicated:
        return 'Complete assessments every day for a month';
    }
  }

  String get iconName {
    switch (this) {
      case BadgeType.streak3Day:
      case BadgeType.streak7Day:
      case BadgeType.streak14Day:
      case BadgeType.streak30Day:
        return 'local_fire_department';
      case BadgeType.firstAssessment:
        return 'star';
      case BadgeType.tenthAssessment:
      case BadgeType.twentyFifthAssessment:
      case BadgeType.fiftiethAssessment:
      case BadgeType.hundredthAssessment:
        return 'emoji_events';
      case BadgeType.earlyBird:
        return 'wb_sunny';
      case BadgeType.perfectWeek:
        return 'calendar_today';
      case BadgeType.dedicated:
        return 'workspace_premium';
    }
  }
}

class UserStatsModel {
  final String odId;  
  final String studyId;  
  final int totalPoints;
  final int currentStreak;
  final int longestStreak;
  final int totalAssessments;
  final int earlyCompletions;  
  final DateTime lastAssessmentDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserStatsModel({
    String? odId,
    required this.studyId,
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalAssessments = 0,
    this.earlyCompletions = 0,
    DateTime? lastAssessmentDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : odId = odId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        lastAssessmentDate = lastAssessmentDate ?? DateTime(2000),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get level {
    if (totalPoints < 500) return 1;
   
    int lvl = 1;
    int required = 0;
    while (required <= totalPoints) {
      lvl++;
      required = (lvl * (lvl - 1) * 250);
    }
    return lvl - 1;
  }

  int get pointsToNextLevel {
    final nextLevel = level + 1;
    final required = nextLevel * (nextLevel - 1) * 250;
    return required - totalPoints;
  }

  double get levelProgress {
    final currentLevelPoints = level * (level - 1) * 250;
    final nextLevelPoints = (level + 1) * level * 250;
    final pointsInCurrentLevel = totalPoints - currentLevelPoints;
    final pointsNeededForLevel = nextLevelPoints - currentLevelPoints;
    return pointsInCurrentLevel / pointsNeededForLevel;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': odId,
      'study_id': studyId,
      'total_points': totalPoints,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_assessments': totalAssessments,
      'early_completions': earlyCompletions,
      'last_assessment_date': lastAssessmentDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserStatsModel.fromMap(Map<String, dynamic> map) {
    return UserStatsModel(
      odId: map['id'] as String?,
      studyId: map['study_id'] as String,
      totalPoints: (map['total_points'] as int?) ?? 0,
      currentStreak: (map['current_streak'] as int?) ?? 0,
      longestStreak: (map['longest_streak'] as int?) ?? 0,
      totalAssessments: (map['total_assessments'] as int?) ?? 0,
      earlyCompletions: (map['early_completions'] as int?) ?? 0,
      lastAssessmentDate: map['last_assessment_date'] != null
          ? DateTime.parse(map['last_assessment_date'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  UserStatsModel copyWith({
    String? odId,
    String? studyId,
    int? totalPoints,
    int? currentStreak,
    int? longestStreak,
    int? totalAssessments,
    int? earlyCompletions,
    DateTime? lastAssessmentDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserStatsModel(
      odId: odId ?? this.odId,
      studyId: studyId ?? this.studyId,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalAssessments: totalAssessments ?? this.totalAssessments,
      earlyCompletions: earlyCompletions ?? this.earlyCompletions,
      lastAssessmentDate: lastAssessmentDate ?? this.lastAssessmentDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserStatsModel(studyId: $studyId, points: $totalPoints, level: $level, streak: $currentStreak)';
  }
}

class BadgeModel {
  final String id;
  final String studyId;
  final BadgeType badgeType;
  final DateTime earnedAt;

  BadgeModel({
    String? id,
    required this.studyId,
    required this.badgeType,
    DateTime? earnedAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        earnedAt = earnedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'study_id': studyId,
      'badge_type': badgeType.name,  
      'earned_at': earnedAt.toIso8601String(),
    };
  }

  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    return BadgeModel(
      id: map['id'] as String,
      studyId: map['study_id'] as String,
      badgeType: BadgeType.values.firstWhere(
        (e) => e.name == map['badge_type'],
        orElse: () => BadgeType.firstAssessment,
      ),
      earnedAt: DateTime.parse(map['earned_at'] as String),
    );
  }

  @override
  String toString() {
    return 'BadgeModel(${badgeType.displayName}, earned: $earnedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BadgeModel &&
        other.studyId == studyId &&
        other.badgeType == badgeType;
  }

  @override
  int get hashCode => studyId.hashCode ^ badgeType.hashCode;
}

class PointValues {
  static const int assessmentComplete = 100;
  static const int earlyBonus = 50;  
  static const int firstAssessment = 200;
  static const int weeklyBonus = 500;  
  static const int streakBonus3Day = 150;
  static const int streakBonus7Day = 300;
  static const int streakBonus14Day = 500;
  static const int streakBonus30Day = 1000;
}
