import 'package:fantasyleague/api/api_client.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;

  Map<String, dynamic> _config = {};

  ConfigService._internal();

  Future<void> init() async {
    try {
      final resp = await ApiClient().get('config');
      if (resp.statusCode == 200) {
        _config = Map<String, dynamic>.from(resp.data['data'] ?? {});
      }
    } catch (e) {
      // ignore - config is optional
    }
  }

  String? getString(String key) => _config[key]?.toString();

  dynamic get(String key) => _config[key];
}




