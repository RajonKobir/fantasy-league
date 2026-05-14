class NotificationRespo {
  int? success;
  String? message;
  List<NotificationData>? notificationData;

  NotificationRespo({this.success, this.message, this.notificationData});

  NotificationRespo.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    if (json['notification_data'] != null) {
      notificationData = <NotificationData>[];
      json['notification_data'].forEach((v) {
        notificationData!.add(NotificationData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (notificationData != null) {
      data['notification_data'] =
          notificationData!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class NotificationData {
  String? type;
  String? notificationDetail;
  String? date;
  String? readAt;

  NotificationData(
      {this.type, this.notificationDetail, this.date, this.readAt});

  NotificationData.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    notificationDetail = json['notification_detail'];
    date = json['date'];
    readAt = json['read_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['notification_detail'] = notificationDetail;
    data['date'] = date;
    data['read_at'] = readAt;
    return data;
  }
}
