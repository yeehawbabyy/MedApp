import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'api_config.dart';

typedef TokenRefreshCallback = Future<TokenPair?> Function(String refreshToken);

typedef LogoutCallback = Future<void> Function();

class TokenPair {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });
}

class ApiClient {
  final http.Client _httpClient;
  String? _authToken;
  String? _refreshToken;
  final bool _useMockApi;

  TokenRefreshCallback? _onTokenRefresh;
  LogoutCallback? _onLogout;

  bool _isRefreshing = false;
  final List<Completer<bool>> _refreshQueue = [];

  ApiClient({
    http.Client? httpClient,
    bool? useMockApi,
  })  : _httpClient = httpClient ?? http.Client(),
        _useMockApi = useMockApi ?? ApiConfig.useMockApi;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void setRefreshToken(String? token) {
    _refreshToken = token;
  }

  void setTokens({String? accessToken, String? refreshToken}) {
    _authToken = accessToken;
    _refreshToken = refreshToken;
  }

  void setTokenRefreshCallback(TokenRefreshCallback? callback) {
    _onTokenRefresh = callback;
  }

  void setLogoutCallback(LogoutCallback? callback) {
    _onLogout = callback;
  }

  String? get authToken => _authToken;

  String? get refreshToken => _refreshToken;

  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    final url = _buildUrl(endpoint, queryParams);
    return _makeRequest(
      method: 'GET',
      url: url,
      requiresAuth: requiresAuth,
    );
  }

  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final url = _buildUrl(endpoint);
    return _makeRequest(
      method: 'POST',
      url: url,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final url = _buildUrl(endpoint);
    return _makeRequest(
      method: 'PUT',
      url: url,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  Future<ApiResponse> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final url = _buildUrl(endpoint);
    return _makeRequest(
      method: 'DELETE',
      url: url,
      requiresAuth: requiresAuth,
    );
  }

  Uri _buildUrl(String endpoint, [Map<String, String>? queryParams]) {
    final fullUrl = '${ApiConfig.baseUrl}$endpoint';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Map<String, String> _buildHeaders(bool requiresAuth) {
    final headers = <String, String>{
      ApiHeaders.contentType: ApiHeaders.contentTypeJson,
      ApiHeaders.appVersion: '1.0.0',
      ApiHeaders.platform: Platform.operatingSystem,
      ApiHeaders.requestId: _generateRequestId(),
    };

    if (requiresAuth && _authToken != null) {
      headers[ApiHeaders.authorization] =
          '${ApiHeaders.bearerPrefix}$_authToken';
    }

    return headers;
  }

  String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'req_$timestamp$random';
  }

  Future<ApiResponse> _makeRequest({
    required String method,
    required Uri url,
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    bool isRetryAfterRefresh = false,
  }) async {
    if (_useMockApi) {
      return _mockRequest(method, url.path, body);
    }

    final headers = _buildHeaders(requiresAuth);
    final requestId = headers[ApiHeaders.requestId]!;

    print('API Request [$requestId]: $method ${url.path}');

    try {
      http.Response response;
      final bodyJson = body != null ? jsonEncode(body) : null;

      switch (method) {
        case 'GET':
          response = await _httpClient
              .get(url, headers: headers)
              .timeout(Duration(seconds: ApiConfig.connectionTimeoutSeconds));
          break;
        case 'POST':
          response = await _httpClient
              .post(url, headers: headers, body: bodyJson)
              .timeout(Duration(seconds: ApiConfig.connectionTimeoutSeconds));
          break;
        case 'PUT':
          response = await _httpClient
              .put(url, headers: headers, body: bodyJson)
              .timeout(Duration(seconds: ApiConfig.connectionTimeoutSeconds));
          break;
        case 'DELETE':
          response = await _httpClient
              .delete(url, headers: headers)
              .timeout(Duration(seconds: ApiConfig.connectionTimeoutSeconds));
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported');
      }

      print('API Response [$requestId]: ${response.statusCode}');

      if (response.statusCode == 401 && requiresAuth && !isRetryAfterRefresh) {
        print('API: Received 401, attempting token refresh...');
        final refreshed = await _attemptTokenRefresh();

        if (refreshed) {
          print('API: Token refreshed, retrying request...');
          return _makeRequest(
            method: method,
            url: url,
            body: body,
            requiresAuth: requiresAuth,
            isRetryAfterRefresh: true,
          );
        } else {
          print('API: Token refresh failed, logging out...');
          await _onLogout?.call();
          return ApiResponse(
            statusCode: 401,
            body: {
              'status': 'error',
              'error': {
                'code': 'SESSION_EXPIRED',
                'message': 'Sesja wygasła. Zaloguj się ponownie.',
              },
            },
          );
        }
      }

      return _parseResponse(response);
    } on SocketException catch (e) {
      print('API Error [$requestId]: Network error - $e');
      return ApiResponse.networkError('No internet connection');
    } on TimeoutException catch (e) {
      print('API Error [$requestId]: Timeout - $e');
      return ApiResponse.networkError('Request timed out');
    } catch (e) {
      print('API Error [$requestId]: $e');
      return ApiResponse.networkError('Request failed: $e');
    }
  }

  Future<bool> _attemptTokenRefresh() async {
    if (_isRefreshing) {
      print('API: Token refresh already in progress, waiting...');
      final completer = Completer<bool>();
      _refreshQueue.add(completer);
      return completer.future;
    }

    if (_refreshToken == null || _refreshToken!.isEmpty) {
      print('API: No refresh token available');
      return false;
    }

    if (_onTokenRefresh == null) {
      print('API: No token refresh callback set');
      return false;
    }

    _isRefreshing = true;

    try {
      final newTokens = await _onTokenRefresh!(_refreshToken!);

      if (newTokens != null) {
        _authToken = newTokens.accessToken;
        _refreshToken = newTokens.refreshToken;

        print('API: Token refresh successful');

        for (final completer in _refreshQueue) {
          completer.complete(true);
        }
        _refreshQueue.clear();

        return true;
      } else {
        print('API: Token refresh returned null');

        for (final completer in _refreshQueue) {
          completer.complete(false);
        }
        _refreshQueue.clear();

        return false;
      }
    } catch (e) {
      print('API: Token refresh error: $e');

      for (final completer in _refreshQueue) {
        completer.complete(false);
      }
      _refreshQueue.clear();

      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<TokenPair?> refreshTokenRequest(String refreshToken) async {
    try {
      final url = _buildUrl('/auth/refresh');
      final headers = {
        ApiHeaders.contentType: ApiHeaders.contentTypeJson,
      };

      final response = await _httpClient
          .post(
            url,
            headers: headers,
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeoutSeconds));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as Map<String, dynamic>?;

        if (data != null) {
          return TokenPair(
            accessToken: data['access_token'] as String,
            refreshToken: data['refresh_token'] as String,
            expiresAt: DateTime.parse(data['expires_at'] as String),
          );
        }
      }

      return null;
    } catch (e) {
      print('API: Refresh token request failed: $e');
      return null;
    }
  }

  ApiResponse _parseResponse(http.Response response) {
    try {
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return ApiResponse(
        statusCode: response.statusCode,
        body: body is Map<String, dynamic> ? body : {'data': body},
        headers: response.headers,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: response.statusCode,
        body: {'raw': response.body},
        headers: response.headers,
      );
    }
  }


  Future<ApiResponse> _mockRequest(
    String method,
    String endpoint,
    Map<String, dynamic>? body,
  ) async {
    await Future.delayed(
      Duration(milliseconds: ApiConfig.mockNetworkDelayMs),
    );

    print('Mock API: $method $endpoint');

    if (endpoint.contains('/enrollment/validate')) {
      return _mockEnrollmentValidate(body);
    } else if (endpoint.contains('/enrollment/consent')) {
      return _mockConsentConfirm(body);
    } else if (endpoint.contains('/assessments/sync/batch')) {
      return _mockBatchSync(body);
    } else if (endpoint.contains('/assessments/sync')) {
      return _mockAssessmentSync(body);
    } else if (endpoint.contains('/sync/status')) {
      return _mockSyncStatus();
    } else if (endpoint.contains('/audit/log')) {
      return _mockAuditLog(body);
    } else if (endpoint.contains('/alerts')) {
      return _mockAlert(body);
    }

    return ApiResponse(
      statusCode: 200,
      body: {
        'status': 'success',
        'data': {'message': 'Mock response for $endpoint'},
      },
    );
  }

  ApiResponse _mockEnrollmentValidate(Map<String, dynamic>? body) {
    final code = body?['enrollmentCode'] as String?;

    if (code == null || code.isEmpty) {
      return ApiResponse(
        statusCode: 400,
        body: {
          'status': 'error',
          'error': {
            'code': 'INVALID_ENROLLMENT_CODE',
            'message': 'Enrollment code is required',
          },
        },
      );
    }

    if (code.startsWith('MED-') || code.length >= 8) {
      return ApiResponse(
        statusCode: 200,
        body: {
          'status': 'success',
          'data': {
            'studyId': 'STUDY_${code}_${DateTime.now().millisecondsSinceEpoch}',
            'enrollmentCode': code,
            'trialSite': {
              'id': 'SITE-001',
              'name': 'AGH University Hospital',
              'location': 'Krakow, Poland',
            },
            'authToken': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
            'tokenExpiry':
                DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          },
        },
      );
    }

    return ApiResponse(
      statusCode: 404,
      body: {
        'status': 'error',
        'error': {
          'code': 'INVALID_ENROLLMENT_CODE',
          'message': 'The enrollment code is invalid',
        },
      },
    );
  }

  ApiResponse _mockConsentConfirm(Map<String, dynamic>? body) {
    return ApiResponse(
      statusCode: 201,
      body: {
        'status': 'success',
        'data': {
          'consentId': 'consent_${DateTime.now().millisecondsSinceEpoch}',
          'recordedAt': DateTime.now().toIso8601String(),
          'message': 'Consent successfully recorded.',
        },
      },
    );
  }

  ApiResponse _mockAssessmentSync(Map<String, dynamic>? body) {
    final assessmentId = body?['assessmentId'] as String?;

    return ApiResponse(
      statusCode: 201,
      body: {
        'status': 'success',
        'data': {
          'assessmentId': assessmentId,
          'syncedAt': DateTime.now().toIso8601String(),
          'serverTimestamp': DateTime.now().toIso8601String(),
          'message': 'Assessment successfully recorded.',
        },
      },
    );
  }

  ApiResponse _mockBatchSync(Map<String, dynamic>? body) {
    final assessments = body?['assessments'] as List? ?? [];
    final results = <Map<String, dynamic>>[];

    for (var i = 0; i < assessments.length; i++) {
      final assessment = assessments[i] as Map<String, dynamic>;
      results.add({
        'assessmentId': assessment['assessmentId'],
        'status': 'success',
        'syncedAt': DateTime.now().toIso8601String(),
      });
    }

    return ApiResponse(
      statusCode: 207,
      body: {
        'status': 'success',
        'data': {
          'totalReceived': assessments.length,
          'successful': assessments.length,
          'failed': 0,
          'results': results,
        },
      },
    );
  }

  ApiResponse _mockSyncStatus() {
    return ApiResponse(
      statusCode: 200,
      body: {
        'status': 'success',
        'data': {
          'serverTime': DateTime.now().toIso8601String(),
          'hasPendingChanges': false,
          'pendingFromServer': 0,
          'pendingFromClient': 0,
          'message': 'All synced.',
        },
      },
    );
  }

  ApiResponse _mockAuditLog(Map<String, dynamic>? body) {
    final logs = body?['logs'] as List? ?? [];
    return ApiResponse(
      statusCode: 201,
      body: {
        'status': 'success',
        'data': {
          'logsReceived': logs.length,
          'message': 'Audit logs successfully recorded.',
        },
      },
    );
  }

  ApiResponse _mockAlert(Map<String, dynamic>? body) {
    return ApiResponse(
      statusCode: 202,
      body: {
        'status': 'success',
        'data': {
          'alertId': 'alert_${DateTime.now().millisecondsSinceEpoch}',
          'queued': true,
          'message': 'Alert has been queued for delivery.',
        },
      },
    );
  }

  void dispose() {
    _httpClient.close();
  }
}

class ApiResponse {
  final int statusCode;
  final Map<String, dynamic> body;
  final Map<String, String>? headers;
  final bool isNetworkError;
  final String? networkErrorMessage;

  ApiResponse({
    required this.statusCode,
    required this.body,
    this.headers,
    this.isNetworkError = false,
    this.networkErrorMessage,
  });

  factory ApiResponse.networkError(String message) {
    return ApiResponse(
      statusCode: 0,
      body: {
        'status': 'error',
        'error': {
          'code': ApiErrorCodes.networkError,
          'message': message,
        },
      },
      isNetworkError: true,
      networkErrorMessage: message,
    );
  }

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  bool get isClientError => statusCode >= 400 && statusCode < 500;

  bool get isServerError => statusCode >= 500;

  bool get isRateLimited => statusCode == 429;

  bool get isTokenExpired =>
      statusCode == 401 && body['error']?['code'] == ApiErrorCodes.tokenExpired;

  String? get status => body['status'] as String?;

  Map<String, dynamic>? get data => body['data'] as Map<String, dynamic>?;

  Map<String, dynamic>? get error => body['error'] as Map<String, dynamic>?;

  String? get errorCode => error?['code'] as String?;

  String? get errorMessage => error?['message'] as String?;

  int? get retryAfterSeconds {
    final retryAfter = headers?['retry-after'] ?? error?['retryAfter'];
    if (retryAfter is int) return retryAfter;
    if (retryAfter is String) return int.tryParse(retryAfter);
    return null;
  }

  @override
  String toString() {
    if (isNetworkError)
      return 'ApiResponse(network error: $networkErrorMessage)';
    return 'ApiResponse($statusCode: $status)';
  }
}
