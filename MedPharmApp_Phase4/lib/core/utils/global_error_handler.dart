
import 'dart:io';
import 'dart:async';

class GlobalErrorHandler {
  GlobalErrorHandler._internal();
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();
  factory GlobalErrorHandler() => _instance;

  ErrorResult handle(dynamic error, {String? context}) {
    print('Error${context != null ? ' in $context' : ''}: $error');

    // Classify and handle the error
    if (error is SocketException || error is NetworkException) {
      return ErrorResult(
        type: ErrorType.network,
        userMessage:
            'Brak połączenia z internetem. Twoje dane zostały zapisane lokalnie.',
        technicalMessage: error.toString(),
        canRetry: true,
        shouldSaveLocally: true,
      );
    }

    if (error is TimeoutException) {
      return ErrorResult(
        type: ErrorType.timeout,
        userMessage: 'Serwer nie odpowiada. Spróbuj ponownie za chwilę.',
        technicalMessage: error.toString(),
        canRetry: true,
        shouldSaveLocally: true,
      );
    }

    if (error is ApiException) {
      return _handleApiException(error);
    }

    if (error is AuthenticationException) {
      return ErrorResult(
        type: ErrorType.authentication,
        userMessage:
            error.userMessage ?? 'Sesja wygasła. Zaloguj się ponownie.',
        technicalMessage: error.toString(),
        canRetry: false,
        requiresReauth: true,
      );
    }

    if (error is ValidationException) {
      return ErrorResult(
        type: ErrorType.validation,
        userMessage: error.userMessage ?? 'Wprowadzone dane są niepoprawne.',
        technicalMessage: error.toString(),
        canRetry: false,
        fieldErrors: error.fieldErrors,
      );
    }

    if (error is DatabaseException) {
      return ErrorResult(
        type: ErrorType.database,
        userMessage:
            'Wystąpił błąd podczas zapisywania danych. Spróbuj ponownie.',
        technicalMessage: error.toString(),
        canRetry: true,
      );
    }

    if (error is SyncException) {
      return ErrorResult(
        type: ErrorType.sync,
        userMessage:
            'Synchronizacja nie powiodła się. Dane zostaną zsynchronizowane później.',
        technicalMessage: error.toString(),
        canRetry: true,
        shouldSaveLocally: true,
      );
    }

    return ErrorResult(
      type: ErrorType.unknown,
      userMessage: 'Wystąpił nieoczekiwany błąd. Spróbuj ponownie.',
      technicalMessage: error.toString(),
      canRetry: true,
    );
  }

  ErrorResult _handleApiException(ApiException error) {
    switch (error.statusCode) {
      case 400:
        return ErrorResult(
          type: ErrorType.validation,
          userMessage: error.userMessage ??
              'Nieprawidłowe dane. Sprawdź i spróbuj ponownie.',
          technicalMessage: error.toString(),
          canRetry: false,
        );

      case 401:
        return ErrorResult(
          type: ErrorType.authentication,
          userMessage: 'Sesja wygasła. Zaloguj się ponownie.',
          technicalMessage: error.toString(),
          canRetry: false,
          requiresReauth: true,
        );

      case 403:
        return ErrorResult(
          type: ErrorType.authorization,
          userMessage: 'Brak uprawnień do wykonania tej operacji.',
          technicalMessage: error.toString(),
          canRetry: false,
        );

      case 404:
        return ErrorResult(
          type: ErrorType.notFound,
          userMessage: 'Nie znaleziono żądanych danych.',
          technicalMessage: error.toString(),
          canRetry: false,
        );

      case 409:
        return ErrorResult(
          type: ErrorType.conflict,
          userMessage:
              'Dane zostały zmienione przez inną osobę. Odśwież i spróbuj ponownie.',
          technicalMessage: error.toString(),
          canRetry: true,
        );

      case 422:
        return ErrorResult(
          type: ErrorType.validation,
          userMessage: error.userMessage ?? 'Wprowadzone dane są niepoprawne.',
          technicalMessage: error.toString(),
          canRetry: false,
          fieldErrors: error.fieldErrors,
        );

      case 429:
        return ErrorResult(
          type: ErrorType.rateLimit,
          userMessage: 'Zbyt wiele żądań. Poczekaj chwilę i spróbuj ponownie.',
          technicalMessage: error.toString(),
          canRetry: true,
          retryAfterSeconds: error.retryAfter ?? 60,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ErrorResult(
          type: ErrorType.server,
          userMessage:
              'Serwer jest tymczasowo niedostępny. Spróbuj ponownie później.',
          technicalMessage: error.toString(),
          canRetry: true,
          shouldSaveLocally: true,
        );

      default:
        return ErrorResult(
          type: ErrorType.api,
          userMessage: error.userMessage ?? 'Błąd komunikacji z serwerem.',
          technicalMessage: error.toString(),
          canRetry: true,
        );
    }
  }

  String getUserMessage(dynamic error, {String? context}) {
    return handle(error, context: context).userMessage;
  }

  bool isRecoverable(dynamic error) {
    return handle(error).canRetry;
  }

  bool requiresReauth(dynamic error) {
    return handle(error).requiresReauth;
  }
}

enum ErrorType {
  network,
  timeout,
  authentication,
  authorization,
  validation,
  notFound,
  conflict,
  rateLimit,
  database,
  sync,
  server,
  api,
  unknown,
}

class ErrorResult {
  final ErrorType type;
  final String userMessage;
  final String technicalMessage;
  final bool canRetry;
  final bool shouldSaveLocally;
  final bool requiresReauth;
  final int? retryAfterSeconds;
  final Map<String, String>? fieldErrors;

  ErrorResult({
    required this.type,
    required this.userMessage,
    required this.technicalMessage,
    this.canRetry = false,
    this.shouldSaveLocally = false,
    this.requiresReauth = false,
    this.retryAfterSeconds,
    this.fieldErrors,
  });

  @override
  String toString() {
    return 'ErrorResult(type: $type, userMessage: $userMessage)';
  }
}


class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error']);

  @override
  String toString() => 'NetworkException: $message';
}

class ApiException implements Exception {
  final int statusCode;
  final String? code;
  final String? userMessage;
  final Map<String, String>? fieldErrors;
  final int? retryAfter;

  ApiException({
    required this.statusCode,
    this.code,
    this.userMessage,
    this.fieldErrors,
    this.retryAfter,
  });

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, code: $code, message: $userMessage)';
}

class AuthenticationException implements Exception {
  final String? userMessage;
  AuthenticationException([this.userMessage]);

  @override
  String toString() => 'AuthenticationException: $userMessage';
}

class ValidationException implements Exception {
  final String? userMessage;
  final Map<String, String>? fieldErrors;

  ValidationException({this.userMessage, this.fieldErrors});

  @override
  String toString() =>
      'ValidationException: $userMessage, fields: $fieldErrors';
}

class DatabaseException implements Exception {
  final String message;
  final dynamic originalError;

  DatabaseException(this.message, [this.originalError]);

  @override
  String toString() => 'DatabaseException: $message';
}

class SyncException implements Exception {
  final String message;
  final List<String>? failedItems;

  SyncException(this.message, [this.failedItems]);

  @override
  String toString() => 'SyncException: $message';
}
