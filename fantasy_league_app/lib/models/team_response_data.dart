class TeamData {
  String? teamId;
  String? teamName;
  String? logoUrl;
  String? captun;
  String? wiseCaptun;
  String? wicketKeeper;
  String? bowler;
  String? bastman;
  String? allRounder;
  String? userId;
  String? createdTime;
  String? updatedTime;
  String? isDelete;
  String? matchKey;
  String? competitionId;
  String? winningStatus;
  String? pointsStatus;
  bool? isSelected;
  double? points;

  TeamData(
      {this.teamId,
      this.teamName,
      this.logoUrl,
      this.captun,
      this.wiseCaptun,
      this.wicketKeeper,
      this.bowler,
      this.bastman,
      this.allRounder,
      this.userId,
      this.createdTime,
      this.updatedTime,
      this.isDelete,
      this.matchKey,
      this.competitionId,
      this.isSelected,
      this.winningStatus,
      this.pointsStatus,
      this.points});

  TeamData.fromJson(Map<String, dynamic> json) {
    teamId = json['team_id'] ?? '';
    teamName = json['team_name'] ?? '';
    logoUrl = json['logo_url'] ?? '';
    captun = json['captun'] ?? '';
    wiseCaptun = json['wise_captun'] ?? '';
    wicketKeeper = json['wicket_keeper'] ?? '';
    bowler = json['bowler'] ?? '';
    bastman = json['bastman'] ?? '';
    allRounder = json['all_rounder'] ?? '';
    userId = json['user_id'] ?? '';
    createdTime = json['created_time'] ?? '';
    updatedTime = json['updated_time'] ?? '';
    isDelete = json['is_delete'] ?? '';
    matchKey = json['match_key'] ?? '';
    competitionId = json['competition_id'] ?? '';
    winningStatus = json['winning_status'] ?? '';
    pointsStatus = json['points_status'] ?? '';
    isSelected = false;
    points = double.tryParse('${json['points']}') ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['team_id'] = teamId;
    data['team_name'] = teamName;
    data['logo_url'] = logoUrl;
    data['captun'] = captun;
    data['wise_captun'] = wiseCaptun;
    data['wicket_keeper'] = wicketKeeper;
    data['bowler'] = bowler;
    data['bastman'] = bastman;
    data['all_rounder'] = allRounder;
    data['user_id'] = userId;
    data['created_time'] = createdTime;
    data['updated_time'] = updatedTime;
    data['is_delete'] = isDelete;
    data['match_key'] = matchKey;
    data['competition_id'] = competitionId;
    data['isSelected'] = isSelected;
    data['points'] = points;
    return data;
  }
}

class GetTeamResponseData {
  List<TeamData>? teamData;
  int? success;
  String? message;

  GetTeamResponseData({this.teamData, this.success, this.message});

  GetTeamResponseData.fromJson(Map<String, dynamic> json) {
    if (json['team_data'] != null) {
      teamData = <TeamData>[];
      json['team_data'].forEach((v) {
        teamData!.add(TeamData.fromJson(v));
      });
    }
    success = int.tryParse('${json['success']}') ?? 0;
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (teamData != null) {
      data['team_data'] = teamData!.map((v) => v.toJson()).toList();
    }
    data['success'] = success;
    data['message'] = message;
    return data;
  }
}




