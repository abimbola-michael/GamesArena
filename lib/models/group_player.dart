// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class GroupPlayer {
  String id;
  String time;
  GroupPlayer({
    required this.id,
    required this.time,
  });

  GroupPlayer copyWith({
    String? id,
    String? time,
  }) {
    return GroupPlayer(
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

  factory GroupPlayer.fromMap(Map<String, dynamic> map) {
    return GroupPlayer(
      id: (map["id"] ?? '') as String,
      time: (map["time"] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory GroupPlayer.fromJson(String source) =>
      GroupPlayer.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'GroupPlayer(id: $id, time: $time)';

  @override
  bool operator ==(covariant GroupPlayer other) {
    if (identical(this, other)) return true;

    return other.id == id && other.time == time;
  }

  @override
  int get hashCode => id.hashCode ^ time.hashCode;
}
