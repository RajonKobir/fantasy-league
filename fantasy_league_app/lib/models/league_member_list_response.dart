class LeagueMemberListResponse {
  int? success;
  String? message;
  List<Leagues>? leagues;

  LeagueMemberListResponse({this.success, this.message, this.leagues});

  LeagueMemberListResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    if (json['leagues'] != null) {
      leagues = <Leagues>[];
      json['leagues'].forEach((v) {
        leagues!.add(Leagues.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (leagues != null) {
      data['leagues'] = leagues!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Leagues {
  String? leagueId;
  String? leagueName;
  List<LeagueMember>? leagueMember;

  Leagues({this.leagueId, this.leagueName, this.leagueMember});

  Leagues.fromJson(Map<String, dynamic> json) {
    leagueId = json['league_id'];
    leagueName = json['league_name'];
    if (json['league_member'] != null) {
      leagueMember = <LeagueMember>[];
      json['league_member'].forEach((v) {
        leagueMember!.add(LeagueMember.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['league_id'] = leagueId;
    data['league_name'] = leagueName;
    if (leagueMember != null) {
      data['league_member'] =
          leagueMember!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class LeagueMember {
  String? teamId;
  String? userId;
  String? image;
  double? points;
  String? teamName;
  String? winningStatus;
  String? winningAmount;
  String? pointsStatus;
  int? rank;

  LeagueMember({
    this.teamId,
    this.userId,
    this.points,
    this.teamName,
    this.winningAmount,
    this.rank,
    this.image,
  });

  LeagueMember.fromJson(Map<String, dynamic> json) {
    teamId = json['team_id'];
    userId = json['user_id'] ?? '';
    points = double.parse('${json['points']}');
    teamName = json['team_name'] ?? '';
    image = json['image'] ?? '';
    winningStatus = json['winning_status'] ?? '';
    pointsStatus = json['points_status'] ?? '';
    winningAmount = json['winning_amount'] ?? '';
    rank = json['rank'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['team_id'] = teamId;
    data['user_id'] = userId;
    data['points'] = points;
    data['team_name'] = teamName;
    data['rank'] = rank;
    data['image'] = image;
    data['winning_amount'] = winningAmount;
    return data;
  }
}




