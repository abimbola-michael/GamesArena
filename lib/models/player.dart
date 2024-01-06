// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Player {
  String id;
  String time;
  Player({
    required this.id,
    required this.time,
  });

  Player copyWith({
    String? id,
    String? time,
  }) {
    return Player(
      id: id ?? this.id,
      time: time ?? this.time,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'time': time,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: (map["id"] ?? '') as String,
      time: (map["time"] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Player.fromJson(String source) =>
      Player.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Player(id: $id, time: $time)';

  @override
  bool operator ==(covariant Player other) {
    if (identical(this, other)) return true;

    return other.id == id && other.time == time;
  }

  @override
  int get hashCode => id.hashCode ^ time.hashCode;
}
