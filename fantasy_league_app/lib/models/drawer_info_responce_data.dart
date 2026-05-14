import 'package:fantasyleague/models/user_data.dart';

class UserDetail {
  String? success;
  String? message;
  UserData? data;

  UserDetail({this.success, this.message, this.data});

  UserDetail.fromJson(Map<String, dynamic> json) {
    // Some endpoints return an envelope { success, message, data },
    // while others return the user object directly. Handle both.
    success =
        json['success']?.toString() ?? (json.containsKey('id') ? '1' : '0');
    message = json['message'];
    if (json['data'] != null) {
      data = UserData.fromJson(Map<String, dynamic>.from(json['data']));
    } else if (json.containsKey('id') || json.containsKey('name')) {
      // The payload is the user object itself
      data = UserData.fromJson(Map<String, dynamic>.from(json));
    } else {
      data = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}
