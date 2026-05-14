class LeagueWiner {
  String leagueWinerId = '';
  String leagueId = '';
  String postion = '';
  String price = '';

  LeagueWiner.fromJson(Map<String, dynamic> json)
      : leagueWinerId = json['league_winer_id']?.toString() ?? '',
        leagueId = json['league_id']?.toString() ?? '',
        postion = json['postion']?.toString() ?? '',
        price = json['price']?.toString() ?? '';
}

class ContestsLeagueListData {
  String isFull = '0';
  String mainLeagueId = '';
  List<LeagueWiner> leagueWiner = [];

  ContestsLeagueListData();

  ContestsLeagueListData.fromJson(Map<String, dynamic> json) {
    isFull = json['is_full']?.toString() ?? json['isFull']?.toString() ?? '0';
    mainLeagueId = json['main_league_id']?.toString() ?? '';
    final list = json['league_winer'] ?? [];
    if (list is List) {
      leagueWiner = list
          .map((e) => LeagueWiner.fromJson(Map<String, dynamic>.from(e ?? {})))
          .toList();
    }
  }
}

class ContestsLeagueCategoryListResponseData {
  String? categoryName;
  String? categoryDescription;
  List<ContestsLeagueListData>? contestsCategoryLeagueListData;

  ContestsLeagueCategoryListResponseData(
      {this.categoryName,
      this.categoryDescription,
      this.contestsCategoryLeagueListData});

  factory ContestsLeagueCategoryListResponseData.fromJson(
      Map<String, dynamic> json) {
    return ContestsLeagueCategoryListResponseData(
      categoryName: json['categoryName']?.toString(),
      categoryDescription: json['categoryDescription']?.toString(),
      contestsCategoryLeagueListData:
          (json['contestsCategoryLeagueListData'] as List<dynamic>?)
              ?.map((e) => ContestsLeagueListData.fromJson(
                  Map<String, dynamic>.from(e ?? {})))
              .toList(),
    );
  }
}

class ContestsLeagueResponseData {
  List<String> teamlist = [];
  int totalcontest = 0;
  List<ContestsLeagueCategoryListResponseData>? contestsCategoryLeagueListData;

  ContestsLeagueResponseData();

  factory ContestsLeagueResponseData.fromJson(Map<String, dynamic> json) {
    return ContestsLeagueResponseData()
      ..teamlist = (json['teamlist'] is String
          ? (json['teamlist'] as String).split(',')
          : <String>[])
      ..totalcontest = int.tryParse('${json['totalcontest'] ?? 0}') ?? 0
      ..contestsCategoryLeagueListData =
          (json['contestsCategoryLeagueListData'] as List<dynamic>?)
              ?.map((e) => ContestsLeagueCategoryListResponseData.fromJson(
                  Map<String, dynamic>.from(e ?? {})))
              .toList();
  }
}
