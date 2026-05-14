import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/api/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Load env.test file for testing
    final envFile = File('./env.test');
    final exists = await envFile.exists();
    if (exists) {
      final content = await envFile.readAsString();
      // Use testLoad to load from string
      dotenv.testLoad(fileInput: content);
    } else {
      throw Exception('env.test file not found');
    }
  });

  // Provide a mock handler for FlutterSecureStorage platform channel to avoid MissingPluginException.
  const MethodChannel secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  group('ApiProvider.socialLogin', () {
    late InterceptorsWrapper interceptor;

    setUp(() {
      // Mock platform channel for FlutterSecureStorage
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorageChannel,
              (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'read':
            return null;
          case 'write':
            return null;
          case 'delete':
            return null;
          case 'readAll':
            return <String, String>{};
          case 'writeAll':
            return null;
          case 'deleteAll':
            return null;
          default:
            return null;
        }
      });

      // Interceptor to fake /api/social-login responses
      interceptor = InterceptorsWrapper(onRequest: (options, handler) {
        if (options.path == 'social-login') {
          final data = options.data ?? {};
          final provider = data['provider'];
          final token = data['token'];

          if (provider == 'facebook' && token == 'valid_fb') {
            return handler.resolve(Response(
                requestOptions: options,
                data: {
                  'token': 'server_fb_token',
                  'user': {'id': 1, 'email': 'fb@example.com'}
                },
                statusCode: 200));
          }

          if (provider == 'google' && token == 'valid_google') {
            return handler.resolve(Response(
                requestOptions: options,
                data: {
                  'token': 'server_google_token',
                  'user': {'id': 2, 'email': 'g@example.com'}
                },
                statusCode: 200));
          }

          // invalid token
          return handler.resolve(Response(
              requestOptions: options,
              data: {'message': 'Invalid token'},
              statusCode: 401));
        }
        return handler.next(options);
      });

      ApiClient().dio.interceptors.add(interceptor);
    });

    tearDown(() async {
      ApiClient().dio.interceptors.remove(interceptor);
      // Clear the mocked platform handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorageChannel, null);
    });

    test('returns token and user for valid facebook login', () async {
      final resp = await ApiProvider().socialLogin('facebook', 'valid_fb');
      expect(resp['token'], 'server_fb_token');
      expect(resp['user']['email'], 'fb@example.com');
    });

    test('returns token and user for valid google login', () async {
      final resp = await ApiProvider().socialLogin('google', 'valid_google');
      expect(resp['token'], 'server_google_token');
      expect(resp['user']['email'], 'g@example.com');
    });

    test('returns message for invalid token', () async {
      final resp = await ApiProvider().socialLogin('facebook', 'invalid');
      expect(resp['message'], 'Invalid token');
    });
  });
}
