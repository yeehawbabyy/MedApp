
import 'package:flutter/foundation.dart';
import '../models/assessment_model.dart';
import '../services/assessment_service.dart';

class AssessmentProvider with ChangeNotifier {
  final AssessmentService _assessmentService;

  AssessmentProvider(this._assessmentService);

  AssessmentModel? _todayAssessment;
  List<AssessmentModel> _assessmentHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  AssessmentModel? get todayAssessment => _todayAssessment;
  List<AssessmentModel> get assessmentHistory => _assessmentHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get canSubmitToday => _todayAssessment == null;

  Future<void> submitAssessment({
    required String studyId,
    required int nrsScore,
    required int vasScore,
  }) async {
    try {
      print('Submitting assessment (NRS: $nrsScore, VAS: $vasScore)');

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final existing = await _assessmentService.getTodayAssessment(studyId);
      if (existing != null) {
        _errorMessage = 'You have already submitted an assessment today';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final assessment = AssessmentModel(
        studyId: studyId,
        nrsScore: nrsScore,
        vasScore: vasScore,
        timestamp: DateTime.now(),
      );

      await _assessmentService.saveAssessment(assessment);

      _todayAssessment = assessment;

      _assessmentHistory.insert(0, assessment);

      print('Assessment submitted successfully');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error submitting assessment: $e');
      _isLoading = false;
      _errorMessage = 'Failed to submit assessment. Please try again.';
      notifyListeners();
    }
  }


  Future<void> loadTodayAssessment(String studyId) async {
    try {
      print('Loading today\'s assessment');

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final assessment = await _assessmentService.getTodayAssessment(studyId);
      _todayAssessment = assessment;

      if (assessment != null) {
        print('Found today\'s assessment: ${assessment.id}');
      } else {
        print('ℹNo assessment submitted today');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading today\'s assessment: $e');
      _isLoading = false;
      _errorMessage = 'Failed to load assessment';
      notifyListeners();
    }
  }


  Future<void> loadAssessmentHistory(String studyId, {int limit = 30}) async {
    try {
      print('Loading assessment history');

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final history = await _assessmentService.getAssessmentHistory(
        studyId,
        limit: limit,
      );
      _assessmentHistory = history;

      print('Loaded ${history.length} assessments');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading assessment history: $e');
      _isLoading = false;
      _errorMessage = 'Failed to load assessment history';
      notifyListeners();
    }
  }

  Future<void> refreshAssessments(String studyId) async {
    await loadTodayAssessment(studyId);
    await loadAssessmentHistory(studyId);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }


  Future<int> getAssessmentCount(String studyId) async {
    try {
      return await _assessmentService.getAssessmentCount(studyId);
    } catch (e) {
      print('Error getting assessment count: $e');
      return 0;
    }
  }

  Future<Map<String, double>> getAverageScores(String studyId) async {
    try {
      return await _assessmentService.getAverageScores(studyId);
    } catch (e) {
      print('Error getting average scores: $e');
      return {'nrs': 0.0, 'vas': 0.0};
    }
  }

  void clearState() {
    _todayAssessment = null;
    _assessmentHistory = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}

