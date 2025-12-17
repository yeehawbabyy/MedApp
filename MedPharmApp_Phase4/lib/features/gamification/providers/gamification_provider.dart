
import 'package:flutter/foundation.dart';
import '../models/gamification_model.dart';
import '../services/gamification_service.dart';

class GamificationProvider with ChangeNotifier {
  final GamificationService _gamificationService;

  GamificationProvider(this._gamificationService);

  UserStatsModel? _userStats;

  List<BadgeModel> _earnedBadges = [];

  List<BadgeModel> _newlyEarnedBadges = [];

  int _lastPointsAwarded = 0;

  bool _isLoading = false;

  String? _errorMessage;

  UserStatsModel? get userStats => _userStats;
  List<BadgeModel> get earnedBadges => _earnedBadges;
  List<BadgeModel> get newlyEarnedBadges => _newlyEarnedBadges;
  int get lastPointsAwarded => _lastPointsAwarded;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get currentLevel => _userStats?.level ?? 0;

  int get totalPoints => _userStats?.totalPoints ?? 0;

  int get currentStreak => _userStats?.currentStreak ?? 0;

  double get levelProgress => _userStats?.levelProgress ?? 0.0;

  int get pointsToNextLevel => _userStats?.pointsToNextLevel ?? 500;

  bool get hasNewBadges => _newlyEarnedBadges.isNotEmpty;

  Future<void> loadUserStats(String studyId) async {
    try {
      print('Loading gamification stats for $studyId');

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final stats = await _gamificationService.getOrCreateUserStats(studyId);
      _userStats = stats;

      final badges = await _gamificationService.getEarnedBadges(studyId);
      _earnedBadges = badges;

      print('Loaded stats: Level ${stats.level}, ${stats.totalPoints} points');
      print('Loaded ${badges.length} badges');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading gamification stats: $e');
      _isLoading = false;
      _errorMessage = 'Failed to load gamification data';
      notifyListeners();
    }
  }

  Future<void> recordAssessmentCompletion({
    required String studyId,
    bool isEarly = false,
  }) async {
    try {
      print('Recording assessment completion for gamification');

      _isLoading = true;
      _newlyEarnedBadges = [];
      _lastPointsAwarded = 0;
      _errorMessage = null;
      notifyListeners();

      final points = await _gamificationService.awardPointsForAssessment(
        studyId: studyId,
        isEarly: isEarly,
      );
      _lastPointsAwarded = points;

      final newBadges = await _gamificationService.checkAndAwardBadges(studyId);
      _newlyEarnedBadges = newBadges;

      final stats = await _gamificationService.getOrCreateUserStats(studyId);
      _userStats = stats;

      final allBadges = await _gamificationService.getEarnedBadges(studyId);
      _earnedBadges = allBadges;

      print('Gamification updated: +$points points, ${newBadges.length} new badges');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error recording assessment completion: $e');
      _isLoading = false;
      _errorMessage = 'Failed to update gamification';
      notifyListeners();
    }
  }

  Future<void> refreshGamificationData(String studyId) async {
    try {
      print('Refreshing gamification data');

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final stats = await _gamificationService.getOrCreateUserStats(studyId);
      _userStats = stats;

      final badges = await _gamificationService.getEarnedBadges(studyId);
      _earnedBadges = badges;

      print('Gamification data refreshed');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error refreshing gamification data: $e');
      _isLoading = false;
      _errorMessage = 'Failed to refresh gamification data';
      notifyListeners();
    }
  }

  void clearNewBadges() {
    _newlyEarnedBadges = [];
    _lastPointsAwarded = 0;
    notifyListeners();
  }

  Future<double> getCompletionPercentage(String studyId) async {
    try {
      return await _gamificationService.getCompletionPercentage(studyId);
    } catch (e) {
      print('Error getting completion percentage: $e');
      return 0.0;
    }
  }

  Future<Map<String, bool>> getWeeklyCompletion(String studyId) async {
    try {
      return await _gamificationService.getWeeklyCompletion(studyId);
    } catch (e) {
      print('Error getting weekly completion: $e');
      return {};
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetState() {
    _userStats = null;
    _earnedBadges = [];
    _newlyEarnedBadges = [];
    _lastPointsAwarded = 0;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  bool hasBadge(BadgeType badgeType) {
    return _earnedBadges.any((b) => b.badgeType == badgeType);
  }

  List<BadgeType> get unearnedBadgeTypes {
    final earnedTypes = _earnedBadges.map((b) => b.badgeType).toSet();
    return BadgeType.values.where((t) => !earnedTypes.contains(t)).toList();
  }
}