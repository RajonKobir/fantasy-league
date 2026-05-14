class ScorecardResponce {
  List<Teams>? teams;
  String? statusNote;
  int? success;
  String? message;

  ScorecardResponce({this.teams, this.statusNote, this.success, this.message});

  ScorecardResponce.fromJson(Map<String, dynamic> json) {
    if (json['teams'] != null) {
      teams = <Teams>[];
      json['teams'].forEach((v) {
        teams!.add(Teams.fromJson(v));
      });
    }
    statusNote = json['status_note'];
    success = json['success'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (teams != null) {
      data['teams'] = teams!.map((v) => v.toJson()).toList();
    }
    data['status_note'] = statusNote;
    data['success'] = success;
    data['message'] = message;
    return data;
  }
}

class Teams {
  String? teamId;
  String? name;
  String? shortName;
  String? scoresFull;
  String? scores;
  String? overs;

  Teams(
      {this.teamId,
      this.name,
      this.shortName,
      this.scoresFull,
      this.scores,
      this.overs});

  Teams.fromJson(Map<String, dynamic> json) {
    teamId = json['team_id'] ?? '';
    name = json['name'] ?? '';
    shortName = json['short_name'] ?? '';
    scoresFull = json['scores_full'] ?? '';
    scores = json['scores'] ?? '';
    overs = json['overs'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['team_id'] = teamId;
    data['name'] = name;
    data['short_name'] = shortName;
    data['scores_full'] = scoresFull;
    data['scores'] = scores;
    data['overs'] = overs;
    return data;
  }
}




