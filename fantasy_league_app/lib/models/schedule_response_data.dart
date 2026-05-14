class ScheduleResponseData {
  int? success;
  String? message;
  List<ShedualData>? shedualData;

  ScheduleResponseData({this.success, this.message, this.shedualData});

  ScheduleResponseData.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    if (json['shedual_data'] != null) {
      shedualData = <ShedualData>[];
      json['shedual_data'].forEach((v) {
        shedualData!.add(ShedualData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (shedualData != null) {
      data['shedual_data'] = shedualData!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ShedualData {
  int? matchId;
  String? match;
  String? preSquad;
  int? competitionId;
  String? seriesName;
  String? isResult;
  String? dateStart;
  String? timeStart;
  TeamLogo? teamLogo;
  String? lineupsOut;
  String? teamAName;
  String? teamBName;

  ShedualData({
    this.matchId,
    this.match,
    this.preSquad,
    this.competitionId,
    this.seriesName,
    this.dateStart,
    this.lineupsOut,
    this.isResult = '',
    this.timeStart,
    this.teamLogo,
  });

  ShedualData.fromJson(Map<String, dynamic> json) {
    matchId = json['match_id'];
    match = json['match'];
    preSquad = json['pre_squad'];
    competitionId = json['competition_id'];
    seriesName = json['series_name'];
    dateStart = json['date_start'];
    lineupsOut = json['lineups_out'];
    timeStart = json['time_start'];
    teamLogo = json['team_logo'] != null
        ? TeamLogo.fromJson(json['team_logo'])
        : null;
    isResult = '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['match_id'] = matchId;
    data['match'] = match;
    data['pre_squad'] = preSquad;
    data['lineups_out'] = lineupsOut;
    data['competition_id'] = competitionId;
    data['series_name'] = seriesName;
    data['date_start'] = dateStart;
    data['time_start'] = timeStart;
    if (teamLogo != null) {
      data['team_logo'] = teamLogo!.toJson();
    }
    return data;
  }
}

class TeamLogo {
  TeamData? a;
  TeamData? b;

  TeamLogo({this.a, this.b});

  TeamLogo.fromJson(Map<String, dynamic> json) {
    a = json['a'] != null ? TeamData.fromJson(json['a']) : null;
    b = json['b'] != null ? TeamData.fromJson(json['b']) : null;
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

class TeamData {
  int? teamId;
  String? name;
  String? shortName;
  String? logoUrl;

  TeamData({this.teamId, this.name, this.shortName, this.logoUrl});

  TeamData.fromJson(Map<String, dynamic> json) {
    teamId = json['team_id'];
    name = json['name'];
    shortName = json['short_name'];
    logoUrl = json['logo_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['team_id'] = teamId;
    data['name'] = name;
    data['short_name'] = shortName;
    data['logo_url'] = logoUrl;
    return data;
  }
}




