import 'package:intl/intl.dart';
import 'package:fantasyleague/models/schedule_response_data.dart';

class ShedualResults {
  ShedualData? shedual;
  List<LeagueData>? leagueData;

  ShedualResults({this.shedual, this.leagueData});

  ShedualResults.fromJson(Map<String, dynamic> json) {
    shedual = json['shedual'] != null
        ? ShedualData.fromJson(json['shedual'])
        : null;
    if (json['league_data'] != null) {
      leagueData = <LeagueData>[];
      json['league_data'].forEach((v) {
        leagueData!.add(LeagueData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (shedual != null) {
      data['shedual'] = shedual!.toJson();
    }
    if (leagueData != null) {
      data['league_data'] = leagueData!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ModifiedLeagueList {
  LeagueData? contestsHedder;
  List<LeagueData>? contestsLeagueListData = <LeagueData>[];

  ModifiedLeagueList({this.contestsHedder, this.contestsLeagueListData});
}

class LeagueData {
  String? leagueId;
  String? teamId;
  String? matchKey;
  String? userId;
  String? teamName;
  String? isFull;
  String? entryFees;
  String? totalTeam;
  String? remainingTeam;
  String? totalWiner;
  String? totalWiningAmount;
  String? winningAmount;
  String? pointsStatus;
  String? winningStatus;
  String? isResult;
  int? createdTime;
  int? rank;
  double? points;

  LeagueData({
    this.leagueId,
    this.teamId,
    this.matchKey,
    this.userId,
    this.teamName,
    this.isFull,
    this.entryFees,
    this.totalTeam,
    this.remainingTeam,
    this.totalWiner,
    this.totalWiningAmount,
    this.winningAmount,
    this.rank,
    this.pointsStatus,
    this.winningStatus,
    this.createdTime,
    this.isResult = '0',
    this.points,
  });

  LeagueData.fromJson(Map<String, dynamic> json) {
    leagueId = json['league_id'] ?? '';
    teamId = json['team_id'] ?? '';
    matchKey = json['match_key'] ?? '';
    userId = json['user_id'] ?? '';
    teamName = json['team_name'] ?? '';
    isFull = json['is_full'] ?? '';
    entryFees = json['entry_fees'] ?? '';
    totalTeam = json['total_team'] ?? '';
    remainingTeam = json['remaining_team'] ?? '';
    totalWiner = json['total_winer'] ?? '';
    totalWiningAmount = json['total_wining_amount'] ?? '';
    winningAmount = json['winning_amount'] ?? '';
    isResult = json['is_result'] ?? '0';
    rank = json['rank'] ?? 0;
    var txt = json['created_time'] ?? '';
    if (txt != '') {
      try {
        createdTime = DateFormat('yyyy-MM-dd HH:mm:ss')
            .parse(txt.trim())
            .millisecondsSinceEpoch;
      } catch (e) {
        createdTime = 0;
      }
    } else {
      createdTime = 0;
    }
    pointsStatus = json['points_status'] ?? '';
    winningStatus = json['winning_status'] ?? '';
    points = double.tryParse('${json['points']}');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['league_id'] = leagueId;
    data['team_id'] = teamId;
    data['match_key'] = matchKey;
    data['user_id'] = userId;
    data['team_name'] = teamName;
    data['winning_amount'] = winningAmount;
    data['is_full'] = isFull;
    data['entry_fees'] = entryFees;
    data['total_team'] = totalTeam;
    data['remaining_team'] = remainingTeam;
    data['total_winer'] = totalWiner;
    data['total_wining_amount'] = totalWiningAmount;
    data['rank'] = rank;
    data['points'] = points;
    data['createdTime'] = createdTime;
    data['points_status'] = pointsStatus;
    data['winning_status'] = winningStatus;
    return data;
  }
}




