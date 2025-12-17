# Technical Architecture Document
## MedPharm Pain Assessment App

**Version:** 1.0
**Date:** November 6, 2025
**Framework:** Flutter 3.x with Dart SDK ^3.9.2
**Architecture Pattern:** Clean Architecture with Offline-First Design

---

## About This Document

**For Students in Mobile Apps in Surgery and Medicine 4.0 (AGH University)**

This document describes the **full Clean Architecture** approach used in professional Flutter applications. It represents the "ideal" architecture for complex, production-grade apps.

**Important Notes:**
- **This is REFERENCE material** - You don't need to implement everything here for Lab 3
- **ARCHITECTURE_GUIDE.md is your primary guide** - It shows the simplified 2-layer approach you'll actually build
- **This document shows "the next level"** - How you could evolve the app later
- **Read it to understand why** - Certain design decisions were made in the simplified version

Think of this as "looking ahead" - understanding where simple patterns can evolve as apps grow in complexity.

**When to use this document:**
- After you're comfortable with the simplified architecture
- When you're curious about "why" certain patterns exist
- As reference for your future professional projects
- For understanding full Clean Architecture in interviews

For now, **start with ARCHITECTURE_GUIDE.md** and come back to this later!

---

## Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Clean Architecture Layers](#2-clean-architecture-layers)
3. [Project Structure](#3-project-structure)
4. [Data Layer](#4-data-layer)
5. [Domain Layer](#5-domain-layer)
6. [Presentation Layer](#6-presentation-layer)
7. [Dependency Injection](#7-dependency-injection)
8. [Offline-First Sync Strategy](#8-offline-first-sync-strategy)
9. [API Integration](#9-api-integration)
10. [Security Implementation](#10-security-implementation)
11. [Third-Party Packages](#11-third-party-packages)
12. [Testing Strategy](#12-testing-strategy)
13. [Build & Deployment](#13-build--deployment)

---

## 1. Architecture Overview

### 1.1 Architecture Pattern: Clean Architecture

The app follows Uncle Bob's Clean Architecture principles with three distinct layers:

```
┌─────────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                      │
│  (UI Widgets, State Management, View Models)            │
│                                                          │
│  Dependencies: Domain Layer Only                        │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│                    DOMAIN LAYER                          │
│  (Entities, Use Cases, Repository Interfaces)           │
│                                                          │
│  Dependencies: None (Pure Dart)                         │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│                     DATA LAYER                           │
│  (Repository Implementations, Data Sources, Models)     │
│                                                          │
│  Dependencies: Domain Layer                             │
└─────────────────────────────────────────────────────────┘
```

**Dependency Rule:** Dependencies point inward. Inner layers know nothing about outer layers.

### 1.2 Offline-First Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   UI Layer   │────▶│  Repository  │────▶│ Local Source │
│   (Flutter)  │     │   (Domain)   │     │   (SQLite)   │
└──────────────┘     └──────┬───────┘     └──────────────┘
                            │
                            │ (Background Sync)
                            │
                            ▼
                     ┌──────────────┐
                     │ Remote Source│
                     │  (REST API)  │
                     └──────────────┘
```

**Flow:**
1. All writes go to local database first (immediate persistence)
2. UI reads from local database (always available)
3. Background sync service sends local data to remote API
4. Remote changes pulled and merged into local database
5. Repository notifies UI of data changes via streams

---

## 2. Clean Architecture Layers

### 2.1 Presentation Layer
**Responsibility:** User interface and user interaction

**Components:**
- **Widgets:** Stateless/Stateful Flutter widgets
- **Screens/Pages:** Top-level UI containers
- **View Models/Controllers:** Business logic for UI (using Provider/Riverpod)
- **State Management:** Reactive state handling

**Rules:**
- Can depend on Domain layer only
- No direct access to Data layer
- No platform-specific code (isolated in separate files)
- Pure UI logic, no business rules

### 2.2 Domain Layer
**Responsibility:** Core business logic and rules

**Components:**
- **Entities:** Core business objects (Assessment, Patient, Questionnaire)
- **Use Cases:** Single-responsibility business operations
- **Repository Interfaces:** Contracts for data operations
- **Value Objects:** Immutable objects (StudyId, PainScore)
- **Failures:** Domain-specific error types

**Rules:**
- Pure Dart (no Flutter dependencies)
- No external dependencies (except Dart SDK)
- Platform-agnostic
- Contains all business rules

### 2.3 Data Layer
**Responsibility:** Data persistence and external communication

**Components:**
- **Repository Implementations:** Concrete implementations of domain interfaces
- **Data Sources:** Local (SQLite) and Remote (API) data sources
- **Models:** Data transfer objects (DTOs) for serialization
- **Mappers:** Convert between Models (DTOs) and Entities
- **Database:** SQLite schema and queries

**Rules:**
- Can depend on Domain layer
- Implements repository interfaces from Domain
- Handles all I/O operations
- Contains no business logic

---

## 3. Project Structure

```
lib/
├── main.dart                          # App entry point
├── app/
│   ├── app.dart                       # MaterialApp configuration
│   ├── routes.dart                    # Navigation routes
│   └── di/                            # Dependency injection
│       └── injection_container.dart   # Service locator setup
│
├── core/                              # Shared utilities
│   ├── constants/
│   │   ├── api_constants.dart
│   │   ├── app_constants.dart
│   │   └── storage_keys.dart
│   ├── errors/
│   │   ├── exceptions.dart            # Data layer exceptions
│   │   └── failures.dart              # Domain layer failures
│   ├── network/
│   │   ├── network_info.dart          # Connectivity checker
│   │   └── api_client.dart            # Dio configuration
│   ├── utils/
│   │   ├── date_utils.dart
│   │   ├── validators.dart
│   │   └── encryption_helper.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── colors.dart
│       └── text_styles.dart
│
├── features/                          # Feature modules
│   │
│   ├── authentication/                # User enrollment & auth
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_local_data_source.dart
│   │   │   │   └── auth_remote_data_source.dart
│   │   │   ├── models/
│   │   │   │   ├── enrollment_code_model.dart
│   │   │   │   └── user_session_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── user_session.dart
│   │   │   │   └── study_participant.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── validate_enrollment_code.dart
│   │   │       ├── accept_consent.dart
│   │   │       └── get_current_user.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart
│   │       ├── screens/
│   │       │   ├── enrollment_screen.dart
│   │       │   ├── consent_screen.dart
│   │       │   ├── tutorial_screen.dart
│   │       │   └── notification_setup_screen.dart
│   │       └── widgets/
│   │           ├── code_input_field.dart
│   │           └── consent_form.dart
│   │
│   ├── assessment/                    # Pain assessments
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── assessment_local_data_source.dart
│   │   │   │   └── assessment_remote_data_source.dart
│   │   │   ├── models/
│   │   │   │   ├── assessment_model.dart
│   │   │   │   ├── nrs_model.dart
│   │   │   │   ├── vas_model.dart
│   │   │   │   ├── mcgill_model.dart
│   │   │   │   └── custom_questionnaire_model.dart
│   │   │   └── repositories/
│   │   │       └── assessment_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── assessment.dart
│   │   │   │   ├── pain_score.dart
│   │   │   │   ├── questionnaire_response.dart
│   │   │   │   └── assessment_window.dart
│   │   │   ├── repositories/
│   │   │   │   └── assessment_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_assessment.dart
│   │   │       ├── submit_assessment.dart
│   │   │       ├── get_pending_assessment.dart
│   │   │       ├── get_assessment_history.dart
│   │   │       └── check_assessment_window.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── assessment_provider.dart
│   │       │   └── questionnaire_provider.dart
│   │       ├── screens/
│   │       │   ├── assessment_home_screen.dart
│   │       │   ├── nrs_screen.dart
│   │       │   ├── vas_screen.dart
│   │       │   ├── mcgill_screen.dart
│   │       │   ├── custom_questionnaire_screen.dart
│   │       │   ├── assessment_review_screen.dart
│   │       │   └── assessment_success_screen.dart
│   │       └── widgets/
│   │           ├── pain_scale_slider.dart
│   │           ├── numeric_pain_buttons.dart
│   │           ├── mcgill_word_selector.dart
│   │           ├── progress_indicator.dart
│   │           └── assessment_timer.dart
│   │
│   ├── sync/                          # Data synchronization
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── sync_local_data_source.dart
│   │   │   ├── models/
│   │   │   │   └── sync_queue_item_model.dart
│   │   │   └── repositories/
│   │   │       └── sync_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── sync_status.dart
│   │   │   │   └── sync_queue_item.dart
│   │   │   ├── repositories/
│   │   │   │   └── sync_repository.dart
│   │   │   └── usecases/
│   │   │       ├── sync_pending_assessments.dart
│   │   │       ├── retry_failed_sync.dart
│   │   │       └── get_sync_status.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── sync_provider.dart
│   │       └── widgets/
│   │           └── sync_status_indicator.dart
│   │
│   ├── gamification/                  # Points, levels, badges
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── gamification_local_data_source.dart
│   │   │   ├── models/
│   │   │   │   ├── badge_model.dart
│   │   │   │   └── progress_model.dart
│   │   │   └── repositories/
│   │   │       └── gamification_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── badge.dart
│   │   │   │   ├── achievement.dart
│   │   │   │   ├── user_level.dart
│   │   │   │   └── progress_stats.dart
│   │   │   ├── repositories/
│   │   │   │   └── gamification_repository.dart
│   │   │   └── usecases/
│   │   │       ├── award_points.dart
│   │   │       ├── check_level_up.dart
│   │   │       ├── unlock_badge.dart
│   │   │       └── get_progress_stats.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── gamification_provider.dart
│   │       ├── screens/
│   │       │   ├── progress_screen.dart
│   │       │   └── badge_gallery_screen.dart
│   │       └── widgets/
│   │           ├── points_display.dart
│   │           ├── level_progress_bar.dart
│   │           ├── badge_card.dart
│   │           ├── achievement_popup.dart
│   │           └── calendar_view.dart
│   │
│   ├── notifications/                 # Push notifications & reminders
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── notification_local_data_source.dart
│   │   │   └── repositories/
│   │   │       └── notification_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── notification_settings.dart
│   │   │   ├── repositories/
│   │   │   │   └── notification_repository.dart
│   │   │   └── usecases/
│   │   │       ├── schedule_assessment_reminder.dart
│   │   │       ├── cancel_notification.dart
│   │   │       └── update_notification_settings.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── notification_provider.dart
│   │       └── screens/
│   │           └── notification_settings_screen.dart
│   │
│   └── audit/                         # Audit trail logging
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── audit_local_data_source.dart
│       │   │   └── audit_remote_data_source.dart
│       │   ├── models/
│       │   │   └── audit_log_model.dart
│       │   └── repositories/
│       │       └── audit_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── audit_log.dart
│       │   ├── repositories/
│       │   │   └── audit_repository.dart
│       │   └── usecases/
│       │       ├── log_user_action.dart
│       │       ├── log_data_change.dart
│       │       ├── log_sync_event.dart
│       │       └── sync_audit_logs.dart
│       └── presentation/
│           └── providers/
│               └── audit_provider.dart
│
└── services/                          # Background services
    ├── background_sync_service.dart   # WorkManager/Background Tasks
    ├── notification_service.dart      # Local notifications
    └── analytics_service.dart         # Firebase Analytics

```

---

## 4. Data Layer

### 4.1 Database Schema (SQLite)

#### 4.1.1 Tables

**assessments**
```sql
CREATE TABLE assessments (
    id TEXT PRIMARY KEY,
    study_id TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    time_window_start TEXT NOT NULL,
    time_window_end TEXT NOT NULL,
    completed_at TEXT,
    synced_at TEXT,
    sync_status TEXT DEFAULT 'pending', -- pending, syncing, synced, failed
    app_version TEXT,
    device_type TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_assessments_study_id ON assessments(study_id);
CREATE INDEX idx_assessments_sync_status ON assessments(sync_status);
CREATE INDEX idx_assessments_timestamp ON assessments(timestamp);
```

**nrs_responses**
```sql
CREATE TABLE nrs_responses (
    id TEXT PRIMARY KEY,
    assessment_id TEXT NOT NULL,
    score INTEGER NOT NULL CHECK(score >= 0 AND score <= 10),
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (assessment_id) REFERENCES assessments(id) ON DELETE CASCADE
);
```

**vas_responses**
```sql
CREATE TABLE vas_responses (
    id TEXT PRIMARY KEY,
    assessment_id TEXT NOT NULL,
    score INTEGER NOT NULL CHECK(score >= 0 AND score <= 100),
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (assessment_id) REFERENCES assessments(id) ON DELETE CASCADE
);
```

**mcgill_responses**
```sql
CREATE TABLE mcgill_responses (
    id TEXT PRIMARY KEY,
    assessment_id TEXT NOT NULL,
    ppi_score INTEGER CHECK(ppi_score >= 0 AND ppi_score <= 5),
    descriptors TEXT, -- JSON array of selected words
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (assessment_id) REFERENCES assessments(id) ON DELETE CASCADE
);
```

**custom_questionnaire_responses**
```sql
CREATE TABLE custom_questionnaire_responses (
    id TEXT PRIMARY KEY,
    assessment_id TEXT NOT NULL,
    question_id TEXT NOT NULL,
    answer TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (assessment_id) REFERENCES assessments(id) ON DELETE CASCADE
);

CREATE INDEX idx_custom_responses_assessment ON custom_questionnaire_responses(assessment_id);
```

**sync_queue**
```sql
CREATE TABLE sync_queue (
    id TEXT PRIMARY KEY,
    item_type TEXT NOT NULL, -- assessment, audit_log
    item_id TEXT NOT NULL,
    payload TEXT NOT NULL, -- JSON
    attempt_count INTEGER DEFAULT 0,
    last_attempt_at TEXT,
    next_retry_at TEXT,
    error_message TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sync_queue_next_retry ON sync_queue(next_retry_at);
CREATE INDEX idx_sync_queue_item_type ON sync_queue(item_type);
```

**user_sessions**
```sql
CREATE TABLE user_sessions (
    id TEXT PRIMARY KEY,
    study_id TEXT UNIQUE NOT NULL,
    enrollment_code TEXT NOT NULL,
    enrolled_at TEXT NOT NULL,
    consent_accepted_at TEXT,
    consent_version TEXT,
    access_token TEXT,
    refresh_token TEXT,
    token_expires_at TEXT,
    notification_time TEXT, -- HH:mm format
    notification_enabled INTEGER DEFAULT 1,
    tutorial_completed INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

**gamification_progress**
```sql
CREATE TABLE gamification_progress (
    id TEXT PRIMARY KEY,
    study_id TEXT NOT NULL,
    total_points INTEGER DEFAULT 0,
    current_level INTEGER DEFAULT 1,
    assessments_completed INTEGER DEFAULT 0,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_assessment_date TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (study_id) REFERENCES user_sessions(study_id)
);
```

**badges**
```sql
CREATE TABLE badges (
    id TEXT PRIMARY KEY,
    study_id TEXT NOT NULL,
    badge_type TEXT NOT NULL, -- consistency, timeliness, milestone, special
    badge_name TEXT NOT NULL,
    unlocked_at TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (study_id) REFERENCES user_sessions(study_id)
);

CREATE INDEX idx_badges_study_id ON badges(study_id);
CREATE INDEX idx_badges_type ON badges(badge_type);
```

**audit_logs**
```sql
CREATE TABLE audit_logs (
    id TEXT PRIMARY KEY,
    study_id TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    event_type TEXT NOT NULL,
    event_details TEXT NOT NULL, -- JSON
    app_version TEXT,
    device_type TEXT,
    os_version TEXT,
    synced INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_study_id ON audit_logs(study_id);
CREATE INDEX idx_audit_logs_synced ON audit_logs(synced);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp);
```

**questionnaire_config**
```sql
CREATE TABLE questionnaire_config (
    id TEXT PRIMARY KEY,
    version INTEGER NOT NULL,
    config_json TEXT NOT NULL, -- Full questionnaire configuration
    downloaded_at TEXT NOT NULL,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

### 4.2 Repository Pattern

**Example: AssessmentRepository Interface (Domain Layer)**
```dart
// lib/features/assessment/domain/repositories/assessment_repository.dart

import 'package:dartz/dartz.dart';
import 'package:med_pharm_app/core/errors/failures.dart';
import 'package:med_pharm_app/features/assessment/domain/entities/assessment.dart';

abstract class AssessmentRepository {
  /// Create a new assessment (saves locally)
  Future<Either<Failure, Assessment>> createAssessment(Assessment assessment);

  /// Submit completed assessment (saves locally, queues for sync)
  Future<Either<Failure, void>> submitAssessment(String assessmentId);

  /// Get today's pending assessment
  Future<Either<Failure, Assessment?>> getPendingAssessment();

  /// Get assessment history
  Future<Either<Failure, List<Assessment>>> getAssessmentHistory({
    int limit = 30,
    int offset = 0,
  });

  /// Get assessment by ID
  Future<Either<Failure, Assessment>> getAssessmentById(String id);

  /// Stream of assessment changes (for real-time UI updates)
  Stream<List<Assessment>> watchAssessments();

  /// Check if assessment window is currently open
  Future<Either<Failure, bool>> isAssessmentWindowOpen();
}
```

**Example: AssessmentRepository Implementation (Data Layer)**
```dart
// lib/features/assessment/data/repositories/assessment_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:med_pharm_app/core/errors/exceptions.dart';
import 'package:med_pharm_app/core/errors/failures.dart';
import 'package:med_pharm_app/core/network/network_info.dart';
import 'package:med_pharm_app/features/assessment/data/datasources/assessment_local_data_source.dart';
import 'package:med_pharm_app/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:med_pharm_app/features/assessment/data/models/assessment_model.dart';
import 'package:med_pharm_app/features/assessment/domain/entities/assessment.dart';
import 'package:med_pharm_app/features/assessment/domain/repositories/assessment_repository.dart';

class AssessmentRepositoryImpl implements AssessmentRepository {
  final AssessmentLocalDataSource localDataSource;
  final AssessmentRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AssessmentRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Assessment>> createAssessment(
    Assessment assessment,
  ) async {
    try {
      final assessmentModel = AssessmentModel.fromEntity(assessment);
      final result = await localDataSource.createAssessment(assessmentModel);
      return Right(result.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> submitAssessment(String assessmentId) async {
    try {
      // 1. Mark as completed locally
      await localDataSource.markAssessmentCompleted(assessmentId);

      // 2. Add to sync queue
      await localDataSource.addToSyncQueue(assessmentId);

      // 3. Trigger background sync if network available
      if (await networkInfo.isConnected) {
        // Background sync service will handle actual sync
        // This just triggers it
      }

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Assessment?>> getPendingAssessment() async {
    try {
      final result = await localDataSource.getTodaysPendingAssessment();
      return Right(result?.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Stream<List<Assessment>> watchAssessments() {
    return localDataSource.watchAssessments().map(
      (models) => models.map((model) => model.toEntity()).toList(),
    );
  }

  // ... other methods
}
```

### 4.3 Data Sources

**Local Data Source (SQLite)**
```dart
// lib/features/assessment/data/datasources/assessment_local_data_source.dart

import 'package:sqflite/sqflite.dart';
import 'package:med_pharm_app/core/errors/exceptions.dart';
import 'package:med_pharm_app/features/assessment/data/models/assessment_model.dart';

abstract class AssessmentLocalDataSource {
  Future<AssessmentModel> createAssessment(AssessmentModel assessment);
  Future<void> markAssessmentCompleted(String assessmentId);
  Future<void> addToSyncQueue(String assessmentId);
  Future<AssessmentModel?> getTodaysPendingAssessment();
  Future<List<AssessmentModel>> getAssessments({int limit, int offset});
  Stream<List<AssessmentModel>> watchAssessments();
}

class AssessmentLocalDataSourceImpl implements AssessmentLocalDataSource {
  final Database database;

  AssessmentLocalDataSourceImpl({required this.database});

  @override
  Future<AssessmentModel> createAssessment(AssessmentModel assessment) async {
    try {
      await database.insert(
        'assessments',
        assessment.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return assessment;
    } catch (e) {
      throw CacheException(message: 'Failed to create assessment: $e');
    }
  }

  @override
  Future<void> markAssessmentCompleted(String assessmentId) async {
    try {
      final now = DateTime.now().toIso8601String();
      await database.update(
        'assessments',
        {
          'completed_at': now,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [assessmentId],
      );
    } catch (e) {
      throw CacheException(message: 'Failed to mark assessment completed: $e');
    }
  }

  // ... other methods
}
```

**Remote Data Source (API)**
```dart
// lib/features/assessment/data/datasources/assessment_remote_data_source.dart

import 'package:dio/dio.dart';
import 'package:med_pharm_app/core/errors/exceptions.dart';
import 'package:med_pharm_app/features/assessment/data/models/assessment_model.dart';

abstract class AssessmentRemoteDataSource {
  Future<void> syncAssessment(AssessmentModel assessment);
  Future<List<AssessmentModel>> fetchAssessments({String? lastSyncTimestamp});
}

class AssessmentRemoteDataSourceImpl implements AssessmentRemoteDataSource {
  final Dio client;

  AssessmentRemoteDataSourceImpl({required this.client});

  @override
  Future<void> syncAssessment(AssessmentModel assessment) async {
    try {
      final response = await client.post(
        '/v1/assessments/sync',
        data: assessment.toJson(),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          message: 'Failed to sync assessment',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ... other methods
}
```

---

## 5. Domain Layer

### 5.1 Entities

**Assessment Entity**
```dart
// lib/features/assessment/domain/entities/assessment.dart

import 'package:equatable/equatable.dart';
import 'package:med_pharm_app/features/assessment/domain/entities/pain_score.dart';
import 'package:med_pharm_app/features/assessment/domain/entities/questionnaire_response.dart';

class Assessment extends Equatable {
  final String id;
  final String studyId;
  final DateTime timestamp;
  final DateTime timeWindowStart;
  final DateTime timeWindowEnd;
  final DateTime? completedAt;
  final DateTime? syncedAt;
  final SyncStatus syncStatus;
  final PainScore? nrsScore;
  final PainScore? vasScore;
  final McGillResponse? mcgillResponse;
  final List<CustomQuestionResponse> customResponses;
  final String appVersion;
  final String deviceType;

  const Assessment({
    required this.id,
    required this.studyId,
    required this.timestamp,
    required this.timeWindowStart,
    required this.timeWindowEnd,
    this.completedAt,
    this.syncedAt,
    this.syncStatus = SyncStatus.pending,
    this.nrsScore,
    this.vasScore,
    this.mcgillResponse,
    this.customResponses = const [],
    required this.appVersion,
    required this.deviceType,
  });

  bool get isCompleted => completedAt != null;
  bool get isSynced => syncStatus == SyncStatus.synced;
  bool get isPending => !isCompleted;

  bool get isWindowOpen {
    final now = DateTime.now();
    return now.isAfter(timeWindowStart) && now.isBefore(timeWindowEnd);
  }

  bool get isOverdue {
    return DateTime.now().isAfter(timeWindowEnd) && !isCompleted;
  }

  @override
  List<Object?> get props => [
        id,
        studyId,
        timestamp,
        completedAt,
        syncedAt,
        syncStatus,
        nrsScore,
        vasScore,
        mcgillResponse,
        customResponses,
      ];
}

enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
}
```

**PainScore Value Object**
```dart
// lib/features/assessment/domain/entities/pain_score.dart

import 'package:equatable/equatable.dart';

class PainScore extends Equatable {
  final int value;
  final int minValue;
  final int maxValue;

  const PainScore({
    required this.value,
    required this.minValue,
    required this.maxValue,
  }) : assert(value >= minValue && value <= maxValue);

  factory PainScore.nrs(int score) {
    return PainScore(value: score, minValue: 0, maxValue: 10);
  }

  factory PainScore.vas(int score) {
    return PainScore(value: score, minValue: 0, maxValue: 100);
  }

  @override
  List<Object?> get props => [value, minValue, maxValue];
}
```

### 5.2 Use Cases

**Base Use Case**
```dart
// lib/core/usecases/usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:med_pharm_app/core/errors/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
```

**Example Use Case: Submit Assessment**
```dart
// lib/features/assessment/domain/usecases/submit_assessment.dart

import 'package:dartz/dartz.dart';
import 'package:med_pharm_app/core/errors/failures.dart';
import 'package:med_pharm_app/core/usecases/usecase.dart';
import 'package:med_pharm_app/features/assessment/domain/repositories/assessment_repository.dart';
import 'package:equatable/equatable.dart';

class SubmitAssessment implements UseCase<void, SubmitAssessmentParams> {
  final AssessmentRepository repository;

  SubmitAssessment(this.repository);

  @override
  Future<Either<Failure, void>> call(SubmitAssessmentParams params) async {
    return await repository.submitAssessment(params.assessmentId);
  }
}

class SubmitAssessmentParams extends Equatable {
  final String assessmentId;

  const SubmitAssessmentParams({required this.assessmentId});

  @override
  List<Object?> get props => [assessmentId];
}
```

---

## 6. Presentation Layer

### 6.1 State Management: Riverpod

**Why Riverpod?**
- Compile-safe dependency injection
- Better testability than Provider
- No BuildContext required for providers
- Automatic disposal of resources
- Built-in caching and lazy loading

**Provider Architecture**
```dart
// lib/features/assessment/presentation/providers/assessment_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_pharm_app/app/di/injection_container.dart';
import 'package:med_pharm_app/features/assessment/domain/entities/assessment.dart';
import 'package:med_pharm_app/features/assessment/domain/usecases/get_pending_assessment.dart';
import 'package:med_pharm_app/features/assessment/domain/usecases/submit_assessment.dart';
import 'package:med_pharm_app/core/usecases/usecase.dart';

// State class
class AssessmentState {
  final Assessment? currentAssessment;
  final bool isLoading;
  final String? errorMessage;
  final bool isSubmitting;

  AssessmentState({
    this.currentAssessment,
    this.isLoading = false,
    this.errorMessage,
    this.isSubmitting = false,
  });

  AssessmentState copyWith({
    Assessment? currentAssessment,
    bool? isLoading,
    String? errorMessage,
    bool? isSubmitting,
  }) {
    return AssessmentState(
      currentAssessment: currentAssessment ?? this.currentAssessment,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

// Provider
class AssessmentNotifier extends StateNotifier<AssessmentState> {
  final GetPendingAssessment getPendingAssessment;
  final SubmitAssessment submitAssessment;

  AssessmentNotifier({
    required this.getPendingAssessment,
    required this.submitAssessment,
  }) : super(AssessmentState());

  Future<void> loadPendingAssessment() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await getPendingAssessment(NoParams());

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFailureToMessage(failure),
      ),
      (assessment) => state = state.copyWith(
        isLoading: false,
        currentAssessment: assessment,
      ),
    );
  }

  Future<void> submitCurrentAssessment() async {
    if (state.currentAssessment == null) return;

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final result = await submitAssessment(
      SubmitAssessmentParams(assessmentId: state.currentAssessment!.id),
    );

    result.fold(
      (failure) => state = state.copyWith(
        isSubmitting: false,
        errorMessage: _mapFailureToMessage(failure),
      ),
      (_) => state = state.copyWith(
        isSubmitting: false,
        currentAssessment: null, // Clear after submission
      ),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Server error. Please try again later.';
    } else if (failure is CacheFailure) {
      return 'Local storage error. Please contact support.';
    } else if (failure is NetworkFailure) {
      return 'No internet connection. Assessment saved locally.';
    }
    return 'An unexpected error occurred.';
  }
}

// Provider definition
final assessmentProvider =
    StateNotifierProvider<AssessmentNotifier, AssessmentState>(
  (ref) => AssessmentNotifier(
    getPendingAssessment: sl<GetPendingAssessment>(),
    submitAssessment: sl<SubmitAssessment>(),
  ),
);
```

### 6.2 Screen Example

```dart
// lib/features/assessment/presentation/screens/assessment_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_pharm_app/features/assessment/presentation/providers/assessment_provider.dart';

class AssessmentHomeScreen extends ConsumerStatefulWidget {
  const AssessmentHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AssessmentHomeScreen> createState() =>
      _AssessmentHomeScreenState();
}

class _AssessmentHomeScreenState extends ConsumerState<AssessmentHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load pending assessment on screen load
    Future.microtask(
      () => ref.read(assessmentProvider.notifier).loadPendingAssessment(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(
            state.errorMessage!,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    if (state.currentAssessment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pain Assessment')),
        body: Center(
          child: Text(
            'No pending assessment',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      );
    }

    final assessment = state.currentAssessment!;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Pain Assessment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (assessment.isWindowOpen)
              _buildAssessmentCard(context, assessment)
            else
              _buildWindowClosedMessage(context, assessment),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentCard(BuildContext context, Assessment assessment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Time Remaining',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            // ... countdown timer widget
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to NRS screen
                Navigator.pushNamed(context, '/assessment/nrs');
              },
              child: const Text('Start Assessment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowClosedMessage(
    BuildContext context,
    Assessment assessment,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Assessment window is closed',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
```

---

## 7. Dependency Injection

### 7.1 Service Locator (get_it)

```dart
// lib/app/di/injection_container.dart

import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

// Core
import 'package:med_pharm_app/core/network/network_info.dart';
import 'package:med_pharm_app/core/network/api_client.dart';

// Features - Assessment
import 'package:med_pharm_app/features/assessment/data/datasources/assessment_local_data_source.dart';
import 'package:med_pharm_app/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:med_pharm_app/features/assessment/data/repositories/assessment_repository_impl.dart';
import 'package:med_pharm_app/features/assessment/domain/repositories/assessment_repository.dart';
import 'package:med_pharm_app/features/assessment/domain/usecases/create_assessment.dart';
import 'package:med_pharm_app/features/assessment/domain/usecases/submit_assessment.dart';
import 'package:med_pharm_app/features/assessment/domain/usecases/get_pending_assessment.dart';

// ... other features

final sl = GetIt.instance; // Service Locator

Future<void> initializeDependencies() async {
  // ===== Core =====

  // Database
  final database = await _initDatabase();
  sl.registerLazySingleton<Database>(() => database);

  // Network
  sl.registerLazySingleton<InternetConnectionChecker>(
    () => InternetConnectionChecker(),
  );
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );

  // API Client
  sl.registerLazySingleton<Dio>(() => createDioClient());

  // Secure Storage
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // ===== Features - Assessment =====

  // Data sources
  sl.registerLazySingleton<AssessmentLocalDataSource>(
    () => AssessmentLocalDataSourceImpl(database: sl()),
  );
  sl.registerLazySingleton<AssessmentRemoteDataSource>(
    () => AssessmentRemoteDataSourceImpl(client: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AssessmentRepository>(
    () => AssessmentRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => CreateAssessment(sl()));
  sl.registerLazySingleton(() => SubmitAssessment(sl()));
  sl.registerLazySingleton(() => GetPendingAssessment(sl()));

  // ===== Repeat for other features =====
  // Authentication, Sync, Gamification, Notifications, Audit
}

Future<Database> _initDatabase() async {
  final databasePath = await getDatabasesPath();
  final path = '$databasePath/medpharm.db';

  return await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      // Create all tables
      await db.execute('''
        CREATE TABLE assessments (
          id TEXT PRIMARY KEY,
          study_id TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          time_window_start TEXT NOT NULL,
          time_window_end TEXT NOT NULL,
          completed_at TEXT,
          synced_at TEXT,
          sync_status TEXT DEFAULT 'pending',
          app_version TEXT,
          device_type TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // ... create other tables
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      // Handle database migrations
    },
  );
}

Dio createDioClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.medpharm.example.com', // Replace with actual URL
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptors
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token
        final token = await sl<FlutterSecureStorage>().read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 - refresh token
        if (error.response?.statusCode == 401) {
          // Implement token refresh logic
        }
        return handler.next(error);
      },
    ),
  );

  // Add logging in debug mode
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  return dio;
}
```

### 7.2 Initialization in main.dart

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_pharm_app/app/app.dart';
import 'package:med_pharm_app/app/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  await di.initializeDependencies();

  runApp(
    const ProviderScope(
      child: MedPharmApp(),
    ),
  );
}
```

---

## 8. Offline-First Sync Strategy

### 8.1 Sync Architecture

**Principles:**
1. **Local-First:** All writes go to local database immediately
2. **Background Sync:** Periodic sync in background (WorkManager/Background Tasks)
3. **Retry Logic:** Exponential backoff for failed syncs
4. **Conflict Resolution:** Server timestamp wins (no client updates post-submission)
5. **Queue-Based:** FIFO queue for pending sync items

### 8.2 Sync Service

```dart
// lib/services/background_sync_service.dart

import 'package:workmanager/workmanager.dart';
import 'package:med_pharm_app/app/di/injection_container.dart';
import 'package:med_pharm_app/features/sync/domain/usecases/sync_pending_assessments.dart';
import 'package:med_pharm_app/features/audit/domain/usecases/sync_audit_logs.dart';

class BackgroundSyncService {
  static const String syncTaskName = 'med_pharm_sync';
  static const String syncTaskId = 'med_pharm_sync_periodic';

  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Register periodic sync (every 6 hours)
    await Workmanager().registerPeriodicTask(
      syncTaskId,
      syncTaskName,
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
  }

  static Future<void> triggerImmediateSync() async {
    await Workmanager().registerOneOffTask(
      'immediate_sync',
      syncTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> cancelAllSync() async {
    await Workmanager().cancelAll();
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Re-initialize dependencies for background isolate
    await di.initializeDependencies();

    try {
      // Sync assessments
      final syncAssessments = sl<SyncPendingAssessments>();
      final assessmentResult = await syncAssessments(NoParams());

      // Sync audit logs
      final syncAudit = sl<SyncAuditLogs>();
      final auditResult = await syncAudit(NoParams());

      // Return success if both succeeded
      return assessmentResult.isRight() && auditResult.isRight();
    } catch (e) {
      // Log error and return failure (will trigger retry)
      print('Background sync failed: $e');
      return false;
    }
  });
}
```

### 8.3 Sync Use Case

```dart
// lib/features/sync/domain/usecases/sync_pending_assessments.dart

import 'package:dartz/dartz.dart';
import 'package:med_pharm_app/core/errors/failures.dart';
import 'package:med_pharm_app/core/usecases/usecase.dart';
import 'package:med_pharm_app/features/sync/domain/repositories/sync_repository.dart';

class SyncPendingAssessments implements UseCase<int, NoParams> {
  final SyncRepository repository;

  SyncPendingAssessments(this.repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    return await repository.syncPendingAssessments();
  }
}
```

### 8.4 Exponential Backoff Strategy

```dart
// lib/features/sync/data/repositories/sync_repository_impl.dart

Duration calculateBackoff(int attemptCount) {
  // Exponential backoff: 1min, 5min, 15min, 1hr, 6hr
  final backoffMinutes = [1, 5, 15, 60, 360];
  final index = attemptCount < backoffMinutes.length
      ? attemptCount
      : backoffMinutes.length - 1;
  return Duration(minutes: backoffMinutes[index]);
}

Future<void> retryFailedSync(SyncQueueItem item) async {
  final nextRetry = DateTime.now().add(calculateBackoff(item.attemptCount));

  await database.update(
    'sync_queue',
    {
      'attempt_count': item.attemptCount + 1,
      'next_retry_at': nextRetry.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    },
    where: 'id = ?',
    whereArgs: [item.id],
  );
}
```

---

## 9. API Integration

### 9.1 API Endpoints

**Base URL:** `https://api.medpharm.example.com`

| Endpoint | Method | Purpose | Auth |
|----------|--------|---------|------|
| `/v1/enrollment/validate` | POST | Validate enrollment code | No |
| `/v1/auth/token` | POST | Get access token | No |
| `/v1/auth/refresh` | POST | Refresh access token | Yes |
| `/v1/assessments/sync` | POST | Sync assessment | Yes |
| `/v1/assessments/bulk` | POST | Bulk sync assessments | Yes |
| `/v1/questionnaires/config` | GET | Get questionnaire config | Yes |
| `/v1/alerts` | POST | Send coordinator alert | Yes |
| `/v1/audit/logs` | POST | Sync audit logs | Yes |

### 9.2 Request/Response Models

**Sync Assessment Request**
```json
{
  "assessmentId": "uuid",
  "studyId": "string",
  "timestamp": "2025-11-06T10:30:00Z",
  "timeWindowStart": "2025-11-06T08:00:00Z",
  "timeWindowEnd": "2025-11-06T10:00:00Z",
  "completedAt": "2025-11-06T09:45:00Z",
  "nrs": {
    "score": 7
  },
  "vas": {
    "score": 68
  },
  "mcgill": {
    "ppiScore": 3,
    "descriptors": ["throbbing", "aching", "tender"]
  },
  "custom": [
    {
      "questionId": "q1",
      "answer": "moderate"
    },
    {
      "questionId": "q2",
      "answer": "yes"
    }
  ],
  "appVersion": "1.0.0",
  "deviceType": "iPhone 14 Pro"
}
```

**Sync Assessment Response**
```json
{
  "success": true,
  "assessmentId": "uuid",
  "syncedAt": "2025-11-06T10:00:00Z"
}
```

### 9.3 Error Handling

```dart
// lib/core/network/api_client.dart

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });
}

Future<T> handleApiCall<T>(Future<Response<T>> Function() apiCall) async {
  try {
    final response = await apiCall();
    return response.data!;
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw ApiException(
        message: 'Connection timeout. Please check your internet connection.',
        statusCode: null,
      );
    } else if (e.type == DioExceptionType.connectionError) {
      throw ApiException(
        message: 'No internet connection.',
        statusCode: null,
      );
    } else if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final message = e.response!.data['message'] ?? 'An error occurred';

      throw ApiException(
        message: message,
        statusCode: statusCode,
        data: e.response!.data,
      );
    } else {
      throw ApiException(message: 'An unexpected error occurred');
    }
  }
}
```

---

## 10. Security Implementation

### 10.1 Data Encryption

**In Transit (TLS 1.3)**
- All API calls use HTTPS
- Certificate pinning to prevent MITM attacks

```dart
// Certificate pinning implementation
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

Dio createSecureDioClient() {
  final dio = Dio();

  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) {
      // Implement certificate pinning
      // Compare cert fingerprint with known good certificate
      return cert.sha256.toString() == 'expected_sha256_hash';
    };
    return client;
  };

  return dio;
}
```

**At Rest (Secure Storage)**
- Access tokens stored in iOS Keychain / Android Keystore
- Study ID and session data in secure storage

```dart
// lib/core/security/secure_storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> saveStudyId(String studyId) async {
    await _storage.write(key: 'study_id', value: studyId);
  }

  Future<String?> getStudyId() async {
    return await _storage.read(key: 'study_id');
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

### 10.2 Audit Trail Implementation

```dart
// lib/features/audit/domain/usecases/log_user_action.dart

import 'package:med_pharm_app/features/audit/domain/entities/audit_log.dart';
import 'package:med_pharm_app/features/audit/domain/repositories/audit_repository.dart';

class LogUserAction {
  final AuditRepository repository;

  LogUserAction(this.repository);

  Future<void> call({
    required String studyId,
    required AuditEventType eventType,
    required Map<String, dynamic> eventDetails,
  }) async {
    final log = AuditLog(
      id: Uuid().v4(),
      studyId: studyId,
      timestamp: DateTime.now(),
      eventType: eventType.toString(),
      eventDetails: eventDetails,
      appVersion: await _getAppVersion(),
      deviceType: await _getDeviceType(),
      osVersion: await _getOSVersion(),
    );

    await repository.logEvent(log);
  }
}

enum AuditEventType {
  appInstalled,
  enrollmentCodeEntered,
  consentAccepted,
  consentWithdrawn,
  assessmentStarted,
  assessmentCompleted,
  assessmentAbandoned,
  notificationReceived,
  notificationOpened,
  settingsChanged,
  dataSynced,
  syncFailed,
}
```

---

## 11. Third-Party Packages

### 11.1 Core Dependencies

```yaml
# pubspec.yaml

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.0

  # Dependency Injection
  get_it: ^7.6.0

  # Functional Programming
  dartz: ^0.10.1
  equatable: ^2.0.5

  # Local Database
  sqflite: ^2.3.0
  path: ^1.8.3

  # Network
  dio: ^5.3.3
  internet_connection_checker: ^1.0.0+1

  # Secure Storage
  flutter_secure_storage: ^9.0.0

  # Background Tasks
  workmanager: ^0.5.2

  # Notifications
  flutter_local_notifications: ^16.1.0
  firebase_messaging: ^14.7.0

  # Firebase
  firebase_core: ^2.24.0
  firebase_analytics: ^10.7.0
  firebase_crashlytics: ^3.4.0

  # UI/UX
  intl: ^0.18.1
  uuid: ^4.1.0

  # Device Info
  device_info_plus: ^9.1.0
  package_info_plus: ^5.0.1

  # Permissions
  permission_handler: ^11.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Linting
  flutter_lints: ^3.0.0

  # Testing
  mockito: ^5.4.2
  build_runner: ^2.4.6

  # Code Generation
  freezed: ^2.4.5
  json_serializable: ^6.7.1
```

### 11.2 Package Justification

| Package | Purpose | Alternative Considered |
|---------|---------|----------------------|
| `flutter_riverpod` | State management with DI | Provider, Bloc |
| `get_it` | Service locator for DI | Injectable, Kiwi |
| `dartz` | Functional error handling | Built-in Exception |
| `sqflite` | Local SQLite database | Hive, Isar |
| `dio` | HTTP client with interceptors | http package |
| `workmanager` | Background tasks | flutter_background_service |
| `flutter_secure_storage` | Secure key-value storage | encrypted_shared_preferences |
| `firebase_messaging` | Push notifications (FCM) | OneSignal |

---

## 12. Testing Strategy

### 12.1 Testing Pyramid

```
        ┌─────────────┐
        │  E2E Tests  │  (5%)
        │ (Integration)│
        └─────────────┘
      ┌──────────────────┐
      │  Widget Tests    │  (25%)
      │  (UI Components) │
      └──────────────────┘
  ┌──────────────────────────┐
  │     Unit Tests           │  (70%)
  │ (Logic, Use Cases, Repos)│
  └──────────────────────────┘
```

### 12.2 Unit Tests

**Example: Testing Use Case**
```dart
// test/features/assessment/domain/usecases/submit_assessment_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:med_pharm_app/features/assessment/domain/repositories/assessment_repository.dart';
import 'package:med_pharm_app/features/assessment/domain/usecases/submit_assessment.dart';

@GenerateMocks([AssessmentRepository])
import 'submit_assessment_test.mocks.dart';

void main() {
  late SubmitAssessment useCase;
  late MockAssessmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssessmentRepository();
    useCase = SubmitAssessment(mockRepository);
  });

  const testAssessmentId = 'test-assessment-id';

  test('should submit assessment successfully', () async {
    // Arrange
    when(mockRepository.submitAssessment(any))
        .thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase(
      const SubmitAssessmentParams(assessmentId: testAssessmentId),
    );

    // Assert
    expect(result, const Right(null));
    verify(mockRepository.submitAssessment(testAssessmentId));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return CacheFailure when submission fails', () async {
    // Arrange
    when(mockRepository.submitAssessment(any))
        .thenAnswer((_) async => Left(CacheFailure(message: 'Error')));

    // Act
    final result = await useCase(
      const SubmitAssessmentParams(assessmentId: testAssessmentId),
    );

    // Assert
    expect(result, Left(CacheFailure(message: 'Error')));
    verify(mockRepository.submitAssessment(testAssessmentId));
  });
}
```

### 12.3 Widget Tests

**Example: Testing Assessment Screen**
```dart
// test/features/assessment/presentation/screens/assessment_home_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_pharm_app/features/assessment/presentation/screens/assessment_home_screen.dart';
import 'package:med_pharm_app/features/assessment/presentation/providers/assessment_provider.dart';

void main() {
  testWidgets('shows loading indicator when loading', (tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assessmentProvider.overrideWith((ref) {
            return AssessmentNotifier(
              getPendingAssessment: mockGetPendingAssessment,
              submitAssessment: mockSubmitAssessment,
            )..state = AssessmentState(isLoading: true);
          }),
        ],
        child: const MaterialApp(
          home: AssessmentHomeScreen(),
        ),
      ),
    );

    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message when error occurs', (tester) async {
    // Arrange
    const errorMessage = 'Something went wrong';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assessmentProvider.overrideWith((ref) {
            return AssessmentNotifier(
              getPendingAssessment: mockGetPendingAssessment,
              submitAssessment: mockSubmitAssessment,
            )..state = AssessmentState(errorMessage: errorMessage);
          }),
        ],
        child: const MaterialApp(
          home: AssessmentHomeScreen(),
        ),
      ),
    );

    // Assert
    expect(find.text(errorMessage), findsOneWidget);
  });
}
```

### 12.4 Integration Tests

**Example: E2E Assessment Flow**
```dart
// integration_test/assessment_flow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:med_pharm_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete assessment flow', (tester) async {
    // Start app
    app.main();
    await tester.pumpAndSettle();

    // Navigate to assessment
    await tester.tap(find.text('Start Assessment'));
    await tester.pumpAndSettle();

    // Complete NRS
    await tester.tap(find.text('7'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Complete VAS
    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // ... complete other questionnaires

    // Submit
    await tester.tap(find.text('Submit Assessment'));
    await tester.pumpAndSettle();

    // Verify success
    expect(find.text('Assessment Complete!'), findsOneWidget);
  });
}
```

### 12.5 Test Coverage Target

- **Overall:** ≥80%
- **Domain Layer:** ≥95% (critical business logic)
- **Data Layer:** ≥85% (repositories, data sources)
- **Presentation Layer:** ≥70% (UI logic, providers)

---

## 13. Build & Deployment

### 13.1 CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/ci.yml

name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter format --set-exit-if-changed .

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info

  build-android:
    needs: [analyze, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk --release
      - run: flutter build appbundle --release
      - uses: actions/upload-artifact@v3
        with:
          name: android-release
          path: |
            build/app/outputs/flutter-apk/app-release.apk
            build/app/outputs/bundle/release/app-release.aab

  build-ios:
    needs: [analyze, test]
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build ios --release --no-codesign
      - uses: actions/upload-artifact@v3
        with:
          name: ios-release
          path: build/ios/iphoneos/Runner.app
```

### 13.2 Build Flavors

**Development, Staging, Production**

```dart
// lib/app/config/app_config.dart

enum Environment { development, staging, production }

class AppConfig {
  final Environment environment;
  final String apiBaseUrl;
  final bool enableLogging;
  final bool enableAnalytics;

  AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableLogging,
    required this.enableAnalytics,
  });

  static AppConfig development() => AppConfig(
        environment: Environment.development,
        apiBaseUrl: 'https://dev-api.medpharm.example.com',
        enableLogging: true,
        enableAnalytics: false,
      );

  static AppConfig staging() => AppConfig(
        environment: Environment.staging,
        apiBaseUrl: 'https://staging-api.medpharm.example.com',
        enableLogging: true,
        enableAnalytics: true,
      );

  static AppConfig production() => AppConfig(
        environment: Environment.production,
        apiBaseUrl: 'https://api.medpharm.example.com',
        enableLogging: false,
        enableAnalytics: true,
      );
}
```

**Build Commands**
```bash
# Development
flutter run --flavor dev --target lib/main_dev.dart

# Staging
flutter run --flavor staging --target lib/main_staging.dart

# Production
flutter build apk --flavor prod --target lib/main_prod.dart
flutter build appbundle --flavor prod --target lib/main_prod.dart
flutter build ios --flavor prod --target lib/main_prod.dart
```

### 13.3 App Signing

**Android:**
```bash
# Generate keystore
keytool -genkey -v -keystore medpharm-release.keystore \
  -alias medpharm -keyalg RSA -keysize 2048 -validity 10000

# Configure in android/key.properties
storePassword=<password>
keyPassword=<password>
keyAlias=medpharm
storeFile=../medpharm-release.keystore
```

**iOS:**
- Use Xcode automatic signing with Apple Developer account
- Configure provisioning profiles for App Store distribution
- Enable capabilities: Push Notifications, Background Modes

### 13.4 Release Checklist

- [ ] All tests passing (unit, widget, integration)
- [ ] Code coverage ≥80%
- [ ] No critical or high-severity bugs
- [ ] Performance profiling completed
- [ ] Accessibility audit passed (WCAG 2.1 AAA)
- [ ] Security audit completed (penetration testing)
- [ ] Privacy policy and consent forms reviewed by legal
- [ ] Regulatory compliance validated (FDA 21 CFR Part 11, GDPR, HIPAA)
- [ ] API endpoints configured for production
- [ ] Firebase projects configured (Analytics, Crashlytics, FCM)
- [ ] App store listings prepared (screenshots, descriptions)
- [ ] User documentation completed
- [ ] Support procedures documented
- [ ] Rollback plan prepared

---

## 14. Performance Optimization

### 14.1 Database Optimization

- **Indexes:** Create indexes on frequently queried columns (study_id, timestamp, sync_status)
- **Batch Operations:** Use batch inserts for multiple records
- **Prepared Statements:** Use parameterized queries to prevent SQL injection
- **Connection Pooling:** Reuse database connections
- **Vacuum:** Periodic database optimization with `VACUUM`

### 14.2 UI Optimization

- **Lazy Loading:** Load assessment history incrementally
- **Memoization:** Cache expensive calculations with `useMemoized`
- **const Constructors:** Use `const` for immutable widgets
- **Image Optimization:** Compress and cache badge images
- **Avoid Rebuilds:** Use `Consumer` or `select` in Riverpod for targeted rebuilds

### 14.3 Network Optimization

- **Request Batching:** Batch multiple assessments in single API call
- **Response Caching:** Cache questionnaire configuration locally
- **Compression:** Enable gzip compression for API responses
- **Timeout Configuration:** Set appropriate timeouts (30s)

---

## Appendix A: Architectural Decision Records (ADRs)

### ADR-001: Clean Architecture
**Decision:** Use Clean Architecture pattern
**Rationale:** Separation of concerns, testability, maintainability
**Alternatives Considered:** MVC, MVVM
**Trade-offs:** More boilerplate, steeper learning curve

### ADR-002: Riverpod for State Management
**Decision:** Use Riverpod for state management
**Rationale:** Compile-time safety, better testability, no BuildContext required
**Alternatives Considered:** Provider, Bloc, GetX
**Trade-offs:** Newer package, less community content than Bloc

### ADR-003: SQLite for Local Database
**Decision:** Use SQLite (sqflite package)
**Rationale:** Mature, SQL support, excellent for relational data
**Alternatives Considered:** Hive, Isar
**Trade-offs:** More complex than NoSQL, requires schema migrations

### ADR-004: Dio for HTTP Client
**Decision:** Use Dio for HTTP requests
**Rationale:** Interceptors, better error handling, request/response transformation
**Alternatives Considered:** http package, Chopper
**Trade-offs:** Larger package size than http

---

## Appendix B: Glossary

- **Clean Architecture:** Architectural pattern separating concerns into layers
- **Repository Pattern:** Abstraction layer between business logic and data sources
- **Use Case:** Single-responsibility business operation
- **Entity:** Core business object with identity
- **Value Object:** Immutable object without identity
- **DTO (Data Transfer Object):** Object for transferring data between layers
- **Dependency Injection:** Design pattern for providing dependencies
- **Service Locator:** Registry for finding services/dependencies
- **Offline-First:** Architecture pattern where local data is source of truth
- **Exponential Backoff:** Retry strategy with increasing delays

---

**End of Technical Architecture Document**

**Next Steps:**
1. Review and approval by development team
2. Prototype key components (offline sync, assessment flow)
3. Set up project structure and dependencies
4. Begin sprint planning for MVP development
5. Establish CI/CD pipeline
6. Conduct architecture review session with stakeholders
