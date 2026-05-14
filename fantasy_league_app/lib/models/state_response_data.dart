class StateResponseData {
  int? success;
  List<StateList>? stateList;

  StateResponseData({this.success, this.stateList});

  StateResponseData.fromJson(Map<String, dynamic> json) {
    success = int.tryParse('${json['success']}') ?? 0;
    if (json['StateList'] != null) {
      stateList = <StateList>[];
      json['StateList'].forEach((v) {
        stateList!.add(StateList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Success'] = success;
    if (stateList != null) {
      data['StateList'] = stateList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class StateList {
  String? stateId;
  String? name;
  String? countryId;

  StateList({this.stateId, this.name, this.countryId});

  StateList.fromJson(Map<String, dynamic> json) {
    stateId = json['state_id'];
    name = json['name'];
    countryId = json['country_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['state_id'] = stateId;
    data['name'] = name;
    data['country_id'] = countryId;
    return data;
  }
}




