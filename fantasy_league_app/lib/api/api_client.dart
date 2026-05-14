import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
// package_info_plus removed for performance; fallback persisted via SharedPreferences
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // App version can be provided at build time with --dart-define=APP_VERSION=1.2.3
  // or via the `.env` file key `APP_VERSION`.
  static const String _kAppVersionFromDefine =
      String.fromEnvironment('APP_VERSION', defaultValue: '');

  /// Optional callback invoked when server indicates a forced or required update.
  void Function(Map<String, dynamic> updateData)? onUpdateRequired;

  // Load from .env file, fallback to emulator host for development
  // Android emulator: 10.0.2.2, iOS simulator: localhost
  static String _getDefaultBaseUrl() {
    try {
      final envUrl = dotenv.env['API_BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        return envUrl;
      }
    } catch (e) {
      // dotenv not initialized yet, will use fallback
    }
    // Fallback for development without .env or if dotenv not initialized
    return 'http://10.0.2.2:8000/api';
  }

  static const String _prefKey = 'api_base_url_override';

  late String _baseUrl;
  bool _initialized = false;
  String _fallbackAppVersion = '';

  ApiClient._internal() {
    _baseUrl = _getDefaultBaseUrl();
    dio = Dio(BaseOptions(
        baseUrl: _baseUrl, headers: {'Accept': 'application/json'}));

    dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      final token = await storage.read(key: 'token');

      // Always log for users/me requests
      final isUsersMeRequest = options.path.contains('users/me');

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        if (kDebugMode && isUsersMeRequest) {
          debugPrint(
              '[ApiClient] ✓ Token found and Authorization header added');
          debugPrint('[ApiClient] Request: ${options.method} ${options.path}');
          debugPrint(
              '[ApiClient] Token length: ${token.length}, Preview: ${token.substring(0, 20)}...');
          debugPrint(
              '[ApiClient] Authorization header: Bearer ${token.substring(0, 20)}...');
        }
      } else {
        if (kDebugMode && isUsersMeRequest) {
          debugPrint('[ApiClient] ✗ **CRITICAL**: No token found in storage!');
          debugPrint(
              '[ApiClient] Request: ${options.method} ${options.path} will be UNAUTHENTICATED');
        }
      }

      // App version header: prefer compile-time define, fallback to .env
      String appVersion = _kAppVersionFromDefine;
      // Read from dotenv only if it has been initialized to avoid exceptions
      try {
        if (dotenv.isInitialized) {
          final envVersion = dotenv.env['APP_VERSION'];
          if (envVersion != null && envVersion.isNotEmpty) {
            appVersion = envVersion;
          }
        }
      } catch (e) {
        // ignore errors reading dotenv at this time
      }

      // If APP version still empty, fallback to package info value populated during init()
      if (appVersion.isEmpty && _fallbackAppVersion.isNotEmpty) {
        appVersion = _fallbackAppVersion;
      }

      if (appVersion.isNotEmpty) {
        options.headers['X-App-Version'] = appVersion;
      }

      return handler.next(options);
    }, onResponse: (response, handler) async {
      // Some servers may respond with HTTP 200 but with a JSON body indicating update_required.
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['code'] == 'update_required') {
          // Notify UI and allow the caller to handle (we still return the response)
          try {
            if (onUpdateRequired != null) {
              onUpdateRequired!(Map<String, dynamic>.from(data['data'] ?? {}));
            }
          } catch (_) {}
        }
      }
      return handler.next(response);
    }, onError: (e, handler) async {
      // If server returns 426 Upgrade Required, surface it via callback so UI can block
      final response = e.response;
      if (response != null && response.statusCode == 426) {
        try {
          final data = response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : {};
          if (onUpdateRequired != null) {
            onUpdateRequired!(Map<String, dynamic>.from(data['data'] ?? {}));
          }
        } catch (_) {}
      }

      return handler.next(e);
    }));

    // Add a lightweight retry interceptor with exponential backoff for
    // transient network/server errors. This reduces load spikes caused by
    // many clients immediately retrying on timeouts/errors.
    dio.interceptors.add(InterceptorsWrapper(onError: (err, handler) async {
      try {
        // Work with DioException (v5) for clarity
        final requestOptions = err.requestOptions;
        const retriesKey = 'x_retry_count';
        int retries = 0;
        if (requestOptions.extra.containsKey(retriesKey)) {
          final dynamic v = requestOptions.extra[retriesKey];
          if (v is int) retries = v;
        }

        const int maxRetries = 3;

        // Only retry on network/connect/timeouts or server errors (5xx)
        bool shouldRetry = false;
        try {
          final t = err.type;
          if (t == DioExceptionType.connectionError ||
              t == DioExceptionType.connectionTimeout ||
              t == DioExceptionType.receiveTimeout ||
              t == DioExceptionType.sendTimeout) {
            shouldRetry = true;
          }
        } catch (_) {}

        final status = err.response?.statusCode;
        if (!shouldRetry && status != null && status >= 500) {
          shouldRetry = true;
        }

        if (!shouldRetry || retries >= maxRetries) {
          return handler.next(err);
        }

        retries += 1;
        requestOptions.extra[retriesKey] = retries;

        // Exponential backoff (base 200ms): 200ms, 400ms, 800ms
        final backoffMs = 200 * (1 << (retries - 1));
        await Future.delayed(Duration(milliseconds: backoffMs));

        // Re-send the request using the same Dio instance. Use fetch to avoid
        // going through the high-level convenience methods which may bypass
        // the current options state.
        try {
          final resp = await dio.fetch(requestOptions);
          return handler.resolve(resp);
        } catch (e) {
          // If retry attempt fails, let next interceptor or final handler receive it
          return handler.next(err);
        }
      } catch (e) {
        return handler.next(err);
      }
    }));

    // Kick off a background attempt to populate fallback app version from
    // persisted SharedPreferences value so early requests can still get a value
    // without using package_info_plus (which caused startup jank).
    SharedPreferences.getInstance().then((prefs) {
      _fallbackAppVersion = prefs.getString('app_version') ?? '';
    }).catchError((e) {
      // Silently ignore errors reading early fallback version
    });
  }

  /// Initialize ApiClient by loading any persisted base URL override and reloading from dotenv.
  Future<void> init() async {
    // First, re-read base URL from dotenv (now that it's loaded in main())
    if (!_initialized) {
      _baseUrl = _getDefaultBaseUrl();
      dio.options.baseUrl = _baseUrl;
    }

    // Then check for any persisted override
    final prefs = await SharedPreferences.getInstance();
    final override = prefs.getString(_prefKey);
    if (override != null && override.isNotEmpty) {
      _baseUrl = override;
      dio.options.baseUrl = _baseUrl;
    }
    // Populate a fallback app version from shared preferences so we always have
    // a sensible X-App-Version header if .env or dart-define are missing.
    try {
      final prefs = await SharedPreferences.getInstance();
      _fallbackAppVersion = prefs.getString('app_version') ?? '';
    } catch (e) {
      // Silently ignore persistence errors; header will use available values
      _fallbackAppVersion = '';
    }

    _initialized = true;
  }

  String get baseUrl => _baseUrl;

  /// Set the base URL at runtime. If [persist] is true, the value will be saved
  /// to SharedPreferences as an override.
  Future<void> setBaseUrl(String url, {bool persist = true}) async {
    _baseUrl = url;
    dio.options.baseUrl = _baseUrl;
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, url);
    }
  }

  /// Clear any persisted override and reset to the default base URL.
  Future<void> clearBaseUrlOverride() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    _baseUrl = _getDefaultBaseUrl();
    dio.options.baseUrl = _baseUrl;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get(path, queryParameters: queryParameters);
  }

  /// Perform a conditional GET using ETag/If-None-Match stored in SharedPreferences.
  /// Returns the Dio [Response]. Callers should handle `statusCode == 304`
  /// and fall back to cached payloads when needed.
  Future<Response> getWithEtag(String path,
      {Map<String, dynamic>? queryParameters}) async {
    final prefs = await SharedPreferences.getInstance();
    // Build a stable cache key including sorted query parameters
    String keyUri;
    try {
      final uri = Uri(path: path, queryParameters: queryParameters);
      keyUri = uri.toString();
    } catch (_) {
      keyUri = path;
    }

    final etagKey = 'etag:$keyUri';
    final cachedEtag = prefs.getString(etagKey) ?? '';

    final extraHeaders = <String, dynamic>{};
    if (cachedEtag.isNotEmpty) {
      extraHeaders['If-None-Match'] = cachedEtag;
    }

    final response = await dio.get(path,
        queryParameters: queryParameters,
        options: Options(
            headers: extraHeaders,
            validateStatus: (status) =>
                status != null && (status < 400 || status == 304)));

    // Persist any ETag returned by the server for future conditional requests
    try {
      final returnedEtag = response.headers.value('etag') ??
          response.headers.value('ETag') ??
          '';
      if (returnedEtag.isNotEmpty) {
        await prefs.setString(etagKey, returnedEtag);
      }
    } catch (_) {}

    return response;
  }

  Future<Response> post(String path, {dynamic data}) {
    return dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return dio.delete(path);
  }
}
