class AppVersionResponce {
  final String? minVersion;
  final bool forceUpdate;
  final String? updateUrl;

  AppVersionResponce(
      {this.minVersion, this.forceUpdate = false, this.updateUrl});

  factory AppVersionResponce.fromJson(Map<String, dynamic> json) {
    // Some endpoints return { success: true, data: { key: value } }
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    String? minVersion;
    bool forceUpdate = false;
    String? updateUrl;

    if (data.containsKey('min_app_version')) {
      minVersion = data['min_app_version']?.toString();
    }

    if (data.containsKey('force_update')) {
      final v = data['force_update'];
      forceUpdate = (v is bool) ? v : (int.tryParse('$v') == 1);
    }

    if (data.containsKey('update_url')) {
      updateUrl = data['update_url']?.toString();
    }

    return AppVersionResponce(
        minVersion: minVersion, forceUpdate: forceUpdate, updateUrl: updateUrl);
  }
}
