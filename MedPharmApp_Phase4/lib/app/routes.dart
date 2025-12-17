import 'package:flutter/material.dart';
import '../features/authentication/screens/enrollment_screen.dart';
import '../features/authentication/screens/consent_screen.dart';

import '../features/assessment/screens/nrs_assessment_screen.dart';
import '../features/assessment/screens/vas_assessment_screen.dart';
import '../features/assessment/screens/assessment_history_screen.dart';

import '../features/gamification/screens/home_screen.dart';
import '../features/gamification/screens/badge_gallery_screen.dart';
import '../features/gamification/screens/progress_screen.dart';

class AppRoutes {
  static const String enrollment = '/';
  static const String consent = '/consent';
  static const String tutorial = '/tutorial';
  static const String home = '/home';

  static const String assessmentNrs = '/assessment/nrs';
  static const String assessmentVas = '/assessment/vas';
  static const String assessmentHistory = '/assessment/history';

  static const String badges = '/badges';
  static const String progress = '/progress';

  static Map<String, WidgetBuilder> get routes {
    return {
      enrollment: (context) => const EnrollmentScreen(),
      consent: (context) => const ConsentScreen(),
      home: (context) => const HomeScreen(),
      assessmentNrs: (context) => const NrsAssessmentScreen(),
      assessmentVas: (context) => const VasAssessmentScreen(),
      assessmentHistory: (context) => const AssessmentHistoryScreen(),
      badges: (context) => const BadgeGalleryScreen(),
      progress: (context) => const ProgressScreen(),
    };
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Text('Route ${settings.name} not found'),
        ),
      ),
    );
  }
}
