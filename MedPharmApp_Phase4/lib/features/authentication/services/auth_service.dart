
import 'package:sqflite/sqflite.dart';
import '../../../core/services/database_service.dart';
import '../models/user_model.dart';

class AuthService {
 
  final DatabaseService _databaseService;

  AuthService(this._databaseService);

  Future<int> saveUser(UserModel user) async {
    try {
      final db = await _databaseService.database;

      final userMap = user.toMap();

      final id = await db.insert(
        'user_session',  
        userMap, 
        conflictAlgorithm: ConflictAlgorithm.replace, 
      );

      print('User saved with ID: $id');
      return id;
    } catch (e) {
      print('Error saving user: $e');
      rethrow;  
    }
  }

  
  Future<UserModel?> getCurrentUser() async {
    try {
      final db = await _databaseService.database;

      final results = await db.query(
        'user_session',
        limit: 1,
      );

      if (results.isEmpty) {
        print('No user enrolled yet');
        return null;
      }

      final user = UserModel.fromMap(results.first);
      print('Current user loaded: ${user.studyId}');
      return user;
    } catch (e) {
      print('Error getting current user: $e');
      rethrow;
    }
  }

  Future<int> updateConsentStatus(String studyId) async {
    try {
      final db = await _databaseService.database;

      final rowsUpdated = await db.update(
        'user_session',
        {
          'consent_accepted': 1,
          'consent_accepted_at': DateTime.now().toIso8601String(),
        },
        where: 'study_id = ?',
        whereArgs: [studyId],
      );

      print('Consent status updated for $studyId ($rowsUpdated rows)');
      return rowsUpdated;
    } catch (e) {
      print('Error updating consent status: $e');
      rethrow;
    }
  }

  Future<int> updateTutorialStatus(String studyId) async {
    try {
      final db = await _databaseService.database;

      final rowsUpdated = await db.update(
        'user_session',
        {'tutorial_completed': 1},
        where: 'study_id = ?',
        whereArgs: [studyId],
      );

      print('Tutorial marked complete for $studyId');
      return rowsUpdated;
    } catch (e) {
      print('Error updating tutorial status: $e');
      rethrow;
    }
  }

  Future<bool> validateEnrollmentCode(String code) async {
    if (code.isEmpty) {
      print('Validation failed: Code is empty');
      return false;
    }

    if (code.length < 8 || code.length > 12) {
      print('Validation failed: Code must be 8-12 characters (got ${code.length})');
      return false;
    }

    final alphanumericPattern = RegExp(r'^[a-zA-Z0-9]+$');
    if (!alphanumericPattern.hasMatch(code)) {
      print('Validation failed: Code must be alphanumeric only');
      return false;
    }

    print('Code validation passed: $code');
    return true;
  }

  
  Future<bool> isUserEnrolled() async {
    try {
      final db = await _databaseService.database;

      final results = await db.query('user_session');

      final isEnrolled = results.isNotEmpty;

      if (isEnrolled) {
        print('User is enrolled');
      } else {
        print('No user enrolled');
      }

      return isEnrolled;
    } catch (e) {
      print('Error checking enrollment status: $e');
      return false;
    }
  }

  String generateStudyId(String enrollmentCode) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'STUDY_${enrollmentCode}_$timestamp';
  }

  Future<void> deleteUserData() async {
    final db = await _databaseService.database;
    await db.delete('user_session');
    print('User data deleted');
  }
}
