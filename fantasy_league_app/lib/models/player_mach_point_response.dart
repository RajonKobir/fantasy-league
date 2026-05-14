class PlayerMachPointResponse {
  List<PlayerData>? playerData;
  double? totalPoint;
  int? success;
  String? message;

  PlayerMachPointResponse(
      {this.playerData, this.totalPoint, this.success, this.message});

  PlayerMachPointResponse.fromJson(Map<String, dynamic> json) {
    if (json['player_data'] != null) {
      playerData = <PlayerData>[];
      json['player_data'].forEach((v) {
        playerData!.add(PlayerData.fromJson(v));
      });
    }
    totalPoint = double.parse('${json['total_point']}');
    success = json['success'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (playerData != null) {
      data['player_data'] = playerData!.map((v) => v.toJson()).toList();
    }
    data['total_point'] = totalPoint;
    data['success'] = success;
    data['message'] = message;
    return data;
  }
}

class PlayerData {
  int? matchId;
  TeamLogo? teamLogo;
  String? playedDate;
  String? playerPoint;

  PlayerData({this.matchId, this.teamLogo, this.playedDate, this.playerPoint});

  PlayerData.fromJson(Map<String, dynamic> json) {
    matchId = json['match_id'];
    teamLogo = json['team_logo'] != null
        ? TeamLogo.fromJson(json['team_logo'])
        : null;
    playedDate = json['played_date'];
    playerPoint = json['player_point'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['match_id'] = matchId;
    if (teamLogo != null) {
      data['team_logo'] = teamLogo!.toJson();
    }
    data['played_date'] = playedDate;
    data['player_point'] = playerPoint;
    return data;
  }
}

class TeamLogo {
  TeamLogoData? a;
  TeamLogoData? b;

  TeamLogo({this.a, this.b});

  TeamLogo.fromJson(Map<String, dynamic> json) {
    a = json['a'] != null ? TeamLogoData.fromJson(json['a']) : null;
    b = json['b'] != null ? TeamLogoData.fromJson(json['b']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (a != null) {
      data['a'] = a!.toJson();
    }
    if (b != null) {
      data['b'] = b!.toJson();
    }
    return data;
  }
}

class TeamLogoData {
  String? name;
  String? logoUrl;

  TeamLogoData({this.name, this.logoUrl});

  TeamLogoData.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    logoUrl = json['logo_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['logo_url'] = logoUrl;
    return data;
  }
}




