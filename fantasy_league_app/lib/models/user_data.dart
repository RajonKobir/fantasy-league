class UserData {
  String? userId;
  String? email;
  String? mobileNumber;
  String? cashBonus;
  String? balance;
  String? deposit;
  String? winingAmount;
  String? referral;
  String? name;
  String? dob;
  String? gender;
  String? favouriteTeams;
  String? address;
  String? city;
  String? state;
  String? country;
  String? pincode;
  String? isVeryfy;
  String? createdTime;
  String? updatedTime;
  String? isDelete;
  String? image;
  String? referralCode;
  String? totalLeague;
  String? totalMatches;
  String? totalSeries;
  String? totalWins;

  UserData({
    this.userId = '',
    this.email = '',
    this.mobileNumber = '',
    this.cashBonus = '',
    this.balance = '0',
    this.winingAmount = '',
    this.referral = '',
    this.name = '',
    this.dob = '',
    this.gender = '',
    this.favouriteTeams = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.pincode = '',
    this.isVeryfy = '',
    this.createdTime = '',
    this.updatedTime = '',
    this.isDelete = '',
    this.image = '',
    this.referralCode = '',
    this.totalLeague = '',
    this.totalMatches = '',
    this.deposit = '',
    this.totalSeries = '',
    this.totalWins = '',
  });

  UserData.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'] ?? json['id']?.toString() ?? '';
    // Support multiple possible email keys
    email = json['email'] ?? json['user_email'] ?? json['email_address'] ?? '';
    mobileNumber = json['mobile_number'] ?? '';
    cashBonus = json['cash_bonus'] ?? '';
    balance = json['balance'] ?? json['wallet_balance'] ?? '0';
    winingAmount = json['wining_amount'] ?? '';
    referral = json['referral'] ?? '';

    // Prefer 'name' but fall back to first_name + last_name if available
    if (json['name'] != null && json['name'].toString().trim().isNotEmpty) {
      name = json['name'];
    } else if (json['first_name'] != null || json['last_name'] != null) {
      final fn = (json['first_name'] ?? '').toString();
      final ln = (json['last_name'] ?? '').toString();
      name = (fn + (ln.isNotEmpty ? ' ' + ln : '')).trim();
    } else {
      name = '';
    }

    dob = json['dob'] ?? '';
    gender = json['gender'] ?? '';
    favouriteTeams = json['favourite_teams'] ?? '';
    address = json['address'] ?? '';
    city = json['city'] ?? '';
    state = json['state'] ?? '';
    country = json['country'] ?? '';
    pincode = json['pincode'] ?? '';
    isVeryfy = json['is_veryfy'] ?? '';
    createdTime = json['created_time'] ?? '';
    updatedTime = json['updated_time'] ?? '';
    isDelete = json['is_delete'] ?? '';
    // Support alternate image keys used by backend
    image = json['image'] ??
        json['avatar'] ??
        json['avatar_url'] ??
        json['profile_pic'] ??
        json['photo'] ??
        '';
    referralCode = json['referral_code'] ?? '';
    totalLeague = json['total_league'] ?? '';
    totalMatches = json['total_matches'] ?? '';
    deposit = json['deposit'] ?? '';
    totalSeries = json['total_series'] ?? '';
    totalWins = json['total_wins'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_id'] = userId;
    data['email'] = email;
    data['mobile_number'] = mobileNumber;
    data['cash_bonus'] = cashBonus;
    data['balance'] = balance;
    data['wining_amount'] = winingAmount;
    data['referral'] = referral;
    data['name'] = name;
    data['dob'] = dob;
    data['gender'] = gender;
    data['favourite_teams'] = favouriteTeams;
    data['address'] = address;
    data['city'] = city;
    data['state'] = state;
    data['country'] = country;
    data['pincode'] = pincode;
    data['pincode'] = pincode;
    data['is_veryfy'] = isVeryfy;
    data['created_time'] = createdTime;
    data['updated_time'] = updatedTime;
    data['is_delete'] = isDelete;
    data['image'] = image;
    data['referral_code'] = referralCode;
    data['total_league'] = totalLeague;
    data['total_matches'] = totalMatches;
    data['deposit'] = deposit;
    data['total_series'] = totalSeries;
    data['total_weries'] = totalWins;
    return data;
  }
}
