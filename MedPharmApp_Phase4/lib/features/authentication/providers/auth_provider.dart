

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  
  final AuthService _authService;

  AuthProvider(this._authService);

  UserModel? _currentUser;

  bool _isLoading = false;

  String? _errorMessage;

  String _enrollmentCode = '';


  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get enrollmentCode => _enrollmentCode;

  bool get isFullyEnrolled {
    return _currentUser != null && _currentUser!.hasCompletedOnboarding;
  }

  bool get hasAcceptedConsent {
    return _currentUser?.consentAccepted ?? false;
  }

  bool get hasCompletedTutorial {
    return _currentUser?.tutorialCompleted ?? false;
  }

  Future<void> loadCurrentUser() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners(); 

      final user = await _authService.getCurrentUser();

      _currentUser = user;

      _isLoading = false;
      notifyListeners();  
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load user: $e';
      notifyListeners(); 
    }
  }

  Future<void> enrollUser(String code) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final isValid = await _authService.validateEnrollmentCode(code);
      if (!isValid) {
        _errorMessage = 'Invalid enrollment code format. Must be 8-12 alphanumeric characters.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final studyId = _authService.generateStudyId(code);

      final user = UserModel(
        studyId: studyId,
        enrollmentCode: code,
        enrolledAt: DateTime.now(),
      );

      await _authService.saveUser(user);

      _currentUser = user;

      _isLoading = false;
      notifyListeners();

      print('User enrolled successfully: ${user.studyId}');
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to enroll user. Please try again.';
      notifyListeners();
      print('Enrollment error: $e');
    }
  }


  Future<void> acceptConsent() async {
    if (_currentUser == null) {
      print('Cannot accept consent: No user enrolled');
      return;
    }

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

      print('Consent accepted for ${_currentUser!.studyId}');
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to accept consent. Please try again.';
      notifyListeners();
      print('Accept consent error: $e');
    }
  }

  Future<void> completeTutorial() async {
    if (_currentUser == null) {
      print('Cannot complete tutorial: No user enrolled');
      return;
    }

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

      print('Tutorial completed for ${_currentUser!.studyId}');
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to complete tutorial. Please try again.';
      notifyListeners();
      print('Complete tutorial error: $e');
    }
  }

  void updateEnrollmentCode(String code) {
    _enrollmentCode = code;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.deleteUserData();
      _currentUser = null;
      _enrollmentCode = '';

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to logout: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
}
