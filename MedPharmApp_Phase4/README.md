# MedPharm Pain Assessment App

**Course:** Mobile Apps in Surgery and Medicine 4.0
**Institution:** AGH University of Science and Technology
**Lab Assignment:** Lab 3 - Clinical Trial Application Development

---

## Overview

A Flutter mobile application for collecting daily pain assessments during clinical trials. This is an educational project that simulates a real-world medical app used in pharmaceutical research.

**Scenario:** MedPharm Corporation (fictional) is conducting a Phase III clinical trial for their new pain medication "Painkiller Forte". They need a mobile app for patients to report daily pain levels using standardized questionnaires.

**Target Audience:** Flutter students with 7+ months experience
**Learning Focus:** Feature-first architecture, Provider state management, SQLite database, offline-first design

---

## Getting Started

### Prerequisites

- Flutter SDK 3.16+ installed
- Dart SDK ^3.9.2
- Android Studio or VS Code with Flutter extensions
- iOS: Xcode (macOS only)
- Android: Android SDK

### Setup Instructions

1. **Clone/Download the project**
   ```bash
   cd MedPharmApp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify installation**
   ```bash
   flutter doctor
   ```

4. **Run the app**
   ```bash
   # List available devices
   flutter devices

   # Run on specific device
   flutter run -d <device-id>

   # Or just run (will prompt for device)
   flutter run
   ```

---

## Project Structure

This project follows a **Feature-First** architecture with **Provider** for state management.

```
lib/
├── main.dart                  # App entry point
├── app/                       # App configuration
│   ├── theme.dart            # App theme
│   └── routes.dart           # Navigation routes
├── core/                      # Shared code
│   ├── services/
│   │   └── database_service.dart  # SQLite database (COMPLETE)
│   ├── widgets/              # Reusable UI components
│   └── utils/                # Helper functions
└── features/                  # Feature modules
    ├── authentication/        # Phase 1: User enrollment
    │   ├── models/
    │   ├── services/
    │   ├── providers/
    │   └── screens/
    ├── assessment/            # Phase 2: Pain assessments (TODO)
    ├── sync/                  # Phase 2: Data sync (TODO)
    └── gamification/          # Phase 3: Points & badges (TODO)
```

---

## Documentation

- **[ARCHITECTURE_GUIDE.md](ARCHITECTURE_GUIDE.md)** - **START HERE** - Complete architecture guide for students
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Detailed folder structure and scaffolding levels
- **[PRD.md](PRD.md)** - Product requirements document
- **[TECHNICAL_ARCHITECTURE.md](TECHNICAL_ARCHITECTURE.md)** - Advanced reference architecture

---

## Learning Phases

### Phase 1: Authentication (Current - 80% Scaffolded)
**Goal:** Learn the patterns by implementing TODOs

**Your Tasks:**
1. Implement UserModel methods (toMap, fromMap, copyWith)
2. Implement AuthService methods (getCurrentUser, updateConsent, etc.)
3. Implement AuthProvider methods (enrollUser, acceptConsent, etc.)
4. Wire up Enrollment and Consent screens

**Files to Complete:**
- `lib/features/authentication/models/user_model.dart`
- `lib/features/authentication/services/auth_service.dart`
- `lib/features/authentication/providers/auth_provider.dart`
- `lib/features/authentication/screens/enrollment_screen.dart`
- `lib/features/authentication/screens/consent_screen.dart`

**Assignment:** See [assignments/PHASE_1_AUTHENTICATION.md](assignments/PHASE_1_AUTHENTICATION.md)

### Phase 2: Assessment (Coming Soon - 50% Scaffolded)
Build pain assessment feature using patterns from Phase 1

### Phase 3: Gamification (Coming Soon - 30% Scaffolded)
Create gamification system independently

---

## Testing

### Run Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/authentication/auth_service_test.dart
```

### Debugging
```bash
# Run in debug mode with hot reload
flutter run

# Check for issues
flutter analyze

# Format code
flutter format .
```

---

## Common Commands

```bash
# Clean build files
flutter clean

# Rebuild
flutter pub get
flutter run

# View logs (while app is running)
flutter logs

# Build for release
flutter build apk          # Android
flutter build ios          # iOS (macOS only)
```

---

## Troubleshooting

### "Could not find Provider<X>"
- Ensure provider is added in `main.dart` MultiProvider list
- Check you're using correct type (AuthProvider vs AuthService)

### Database errors
- Delete the app from device/emulator and reinstall
- Or use: `databaseService.deleteDatabase()` (loses all data!)

### "Target of URI doesn't exist: 'package:...'"
- Run `flutter pub get` to install dependencies
- Restart your IDE

### Navigation not working
- Check route name spelling in `app/routes.dart`
- Use route constants (AppRoutes.enrollment) instead of strings

---

## Key Concepts Learned

**Architecture:**
- Feature-first project organization
- Separation of concerns (Model, Service, Provider, Screen)
- Dependency injection

**State Management:**
- Provider package
- ChangeNotifier pattern
- Consumer widget
- context.read() vs context.watch()

**Database:**
- SQLite with sqflite
- Singleton pattern
- CRUD operations
- Database migrations

**UI:**
- Material Design
- Navigation (named routes)
- Forms and validation
- Responsive layouts

---

## Learning Resources

- [ARCHITECTURE_GUIDE.md](ARCHITECTURE_GUIDE.md) - Your main reference
- [Flutter Documentation](https://docs.flutter.dev)
- [Provider Package](https://pub.dev/packages/provider)
- [SQLite Tutorial](https://www.sqlitetutorial.net)

---

## Support

**Questions?**
- Check [docs/COMMON_ERRORS.md](docs/COMMON_ERRORS.md)
- Review [ARCHITECTURE_GUIDE.md](ARCHITECTURE_GUIDE.md)
- Ask your instructor

**Found a bug?**
- Check if it's in the TODO list
- Verify your implementation against examples
- Compare with provided complete methods

---

## License

Educational project for AGH University - Mobile Apps in Surgery and Medicine 4.0 course.

---

**Good luck with your implementation!**

Tips for success:
- Start with ARCHITECTURE_GUIDE.md to understand the patterns
- Follow the examples in the scaffolded code
- Read comments carefully - they contain hints
- Test frequently as you build
- Don't hesitate to ask your instructor questions

Remember: This project simulates a real medical app development scenario. While the company is fictional, the requirements and architecture patterns are realistic and used in actual clinical trial software.
