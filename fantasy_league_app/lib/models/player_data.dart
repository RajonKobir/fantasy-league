class PlayerData {
  String? status;
  Response? response;
  String? etag;
  String? modified;
  String? datetime;
  String? apiVersion;

  PlayerData(
      {this.status,
      this.response,
      this.etag,
      this.modified,
      this.datetime,
      this.apiVersion});

  PlayerData.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    response = json['response'] != null
        ? Response.fromJson(json['response'])
        : null;
    etag = json['etag'];
    modified = json['modified'];
    datetime = json['datetime'];
    apiVersion = json['api_version'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    if (response != null) {
      data['response'] = response!.toJson();
    }
    data['etag'] = etag;
    data['modified'] = modified;
    data['datetime'] = datetime;
    data['api_version'] = apiVersion;
    return data;
  }
}

class Response {
  String? squadType;
  List<Squads>? squads;

  Response({this.squadType, this.squads});

  Response.fromJson(Map<String, dynamic> json) {
    squadType = json['squad_type'];
    if (json['squads'] != null) {
      squads = <Squads>[];
      json['squads'].forEach((v) {
        squads!.add(Squads.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['squad_type'] = squadType;
    if (squads != null) {
      data['squads'] = squads!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Squads {
  String? teamId;
  String? title;
  Team? team;
  List<Players>? players;
  List<LastMatchPlayed>? lastMatchPlayed;

  Squads(
      {this.teamId, this.title, this.team, this.players, this.lastMatchPlayed});

  Squads.fromJson(Map<String, dynamic> json) {
    teamId = json['team_id'];
    title = json['title'];
    team = json['team'] != null ? Team.fromJson(json['team']) : null;
    if (json['players'] != null) {
      players = <Players>[];
      json['players'].forEach((v) {
        players!.add(Players.fromJson(v));
      });
    }
    if (json['last_match_played'] != null) {
      lastMatchPlayed = <LastMatchPlayed>[];
      json['last_match_played'].forEach((v) {
        lastMatchPlayed!.add(LastMatchPlayed.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['team_id'] = teamId;
    data['title'] = title;
    if (team != null) {
      data['team'] = team!.toJson();
    }
    if (players != null) {
      data['players'] = players!.map((v) => v.toJson()).toList();
    }
    if (lastMatchPlayed != null) {
      data['last_match_played'] =
          lastMatchPlayed!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Team {
  int? tid;
  String? title;
  String? abbr;
  String? altName;
  String? type;
  String? thumbUrl;
  String? logoUrl;
  String? country;
  String? sex;

  Team(
      {this.tid,
      this.title,
      this.abbr,
      this.altName,
      this.type,
      this.thumbUrl,
      this.logoUrl,
      this.country,
      this.sex});

  Team.fromJson(Map<String, dynamic> json) {
    tid = json['tid'];
    title = json['title'];
    abbr = json['abbr'];
    altName = json['alt_name'];
    type = json['type'];
    thumbUrl = json['thumb_url'];
    logoUrl = json['logo_url'];
    country = json['country'];
    sex = json['sex'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tid'] = tid;
    data['title'] = title;
    data['abbr'] = abbr;
    data['alt_name'] = altName;
    data['type'] = type;
    data['thumb_url'] = thumbUrl;
    data['logo_url'] = logoUrl;
    data['country'] = country;
    data['sex'] = sex;
    return data;
  }
}

class Players {
  int? pid;
  String? title;
  String? shortName;
  String? firstName;
  String? lastName;
  String? middleName;
  String? birthdate;
  String? birthplace;
  String? country;
  List<void>? primaryTeam;
  String? logoUrl;
  String? playingRole;
  String? battingStyle;
  String? bowlingStyle;
  String? fieldingPosition;
  int? recentMatch;
  int? recentAppearance;
  double? fantasyPlayerRating;
  String? altName;
  String? facebookProfile;
  String? twitterProfile;
  String? instagramProfile;
  String? debutData;
  String? thumbUrl;
  String? nationality;

  Players(
      {this.pid,
      this.title,
      this.shortName,
      this.firstName,
      this.lastName,
      this.middleName,
      this.birthdate,
      this.birthplace,
      this.country,
      this.primaryTeam,
      this.logoUrl,
      this.playingRole,
      this.battingStyle,
      this.bowlingStyle,
      this.fieldingPosition,
      this.recentMatch,
      this.recentAppearance,
      this.fantasyPlayerRating,
      this.altName,
      this.facebookProfile,
      this.twitterProfile,
      this.instagramProfile,
      this.debutData,
      this.thumbUrl,
      this.nationality});

  Players.fromJson(Map<String, dynamic> json) {
    pid = json['pid'];
    title = json['title'];
    shortName = json['short_name'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    middleName = json['middle_name'];
    birthdate = json['birthdate'];
    birthplace = json['birthplace'];
    country = json['country'];
    // if (json['primary_team'] != null) {
    //   primaryTeam = <Null>[];
    //   json['primary_team'].forEach((v) {
    //     primaryTeam!.add(new Null.fromJson(v));
    //   });
    // }
    logoUrl = json['logo_url'];
    playingRole = json['playing_role'];
    battingStyle = json['batting_style'];
    bowlingStyle = json['bowling_style'];
    fieldingPosition = json['fielding_position'];
    recentMatch = json['recent_match'];
    recentAppearance = json['recent_appearance'];
    fantasyPlayerRating = json['fantasy_player_rating'];
    altName = json['alt_name'];
    facebookProfile = json['facebook_profile'];
    twitterProfile = json['twitter_profile'];
    instagramProfile = json['instagram_profile'];
    debutData = json['debut_data'];
    thumbUrl = json['thumb_url'];
    nationality = json['nationality'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pid'] = pid;
    data['title'] = title;
    data['short_name'] = shortName;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['middle_name'] = middleName;
    data['birthdate'] = birthdate;
    data['birthplace'] = birthplace;
    data['country'] = country;
    // if (this.primaryTeam != null) {
    //   data['primary_team'] = this.primaryTeam!.map((v) => v.toJson()).toList();
    // }
    data['logo_url'] = logoUrl;
    data['playing_role'] = playingRole;
    data['batting_style'] = battingStyle;
    data['bowling_style'] = bowlingStyle;
    data['fielding_position'] = fieldingPosition;
    data['recent_match'] = recentMatch;
    data['recent_appearance'] = recentAppearance;
    data['fantasy_player_rating'] = fantasyPlayerRating;
    data['alt_name'] = altName;
    data['facebook_profile'] = facebookProfile;
    data['twitter_profile'] = twitterProfile;
    data['instagram_profile'] = instagramProfile;
    data['debut_data'] = debutData;
    data['thumb_url'] = thumbUrl;
    data['nationality'] = nationality;
    return data;
  }
}

class LastMatchPlayed {
  String? playerId;
  String? title;

  LastMatchPlayed({this.playerId, this.title});

  LastMatchPlayed.fromJson(Map<String, dynamic> json) {
    playerId = json['player_id'];
    title = json['title'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['player_id'] = playerId;
    data['title'] = title;
    return data;
  }
}




