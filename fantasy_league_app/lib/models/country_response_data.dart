class CoutnryResponseData {
  int? success;
  List<CountryList>? countryList;

  CoutnryResponseData({this.success, this.countryList});

  CoutnryResponseData.fromJson(Map<String, dynamic> json) {
    success = json['Success'];
    if (json['CountryList'] != null) {
      countryList = <CountryList>[];
      json['CountryList'].forEach((v) {
        countryList!.add(CountryList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Success'] = success;
    if (countryList != null) {
      data['CountryList'] = countryList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CountryList {
  String? countryId;
  String? name;
  String? phonecode;

  CountryList({this.countryId, this.name, this.phonecode});

  CountryList.fromJson(Map<String, dynamic> json) {
    countryId = json['country_id'];
    name = json['name'];
    phonecode = json['phonecode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['country_id'] = countryId;
    data['name'] = name;
    data['phonecode'] = phonecode;
    return data;
  }
}




