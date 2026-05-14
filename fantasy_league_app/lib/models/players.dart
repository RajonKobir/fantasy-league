class Player {
  int? id;
  String? name;
  String? role;
  String? team;
  String? imageUrl;

  Player({this.id, this.name, this.role, this.team, this.imageUrl});

  Player.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    role = json['role'];
    team = json['team'];
    imageUrl = json['image_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['role'] = role;
    data['team'] = team;
    data['image_url'] = imageUrl;
    return data;
  }
}




