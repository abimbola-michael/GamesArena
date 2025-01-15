// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ExemptPlayer {
  int index;
  String? playerId;
  String action;
  int time;
  ExemptPlayer({
    required this.index,
    this.playerId,
    required this.action,
    required this.time,
  });

  ExemptPlayer copyWith({
    int? index,
    String? playerId,
    String? action,
    int? time,
  }) {
    return ExemptPlayer(
      index: index ?? this.index,
      playerId: playerId ?? this.playerId,
      action: action ?? this.action,
      time: time ?? this.time,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'index': index,
      'playerId': playerId,
      'action': action,
      'time': time,
    };
  }

  factory ExemptPlayer.fromMap(Map<String, dynamic> map) {
    return ExemptPlayer(
      index: map['index'] as int,
      playerId: map['playerId'] != null ? map['playerId'] as String : null,
      action: map['action'] as String,
      time: map['time'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory ExemptPlayer.fromJson(String source) =>
      ExemptPlayer.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ExemptPlayer(index: $index, playerId: $playerId, action: $action, time: $time)';
  }

  @override
  bool operator ==(covariant ExemptPlayer other) {
    if (identical(this, other)) return true;

    return other.index == index &&
        other.playerId == playerId &&
        other.action == action &&
        other.time == time;
  }

  @override
  int get hashCode {
    return index.hashCode ^ playerId.hashCode ^ action.hashCode ^ time.hashCode;
  }
}
