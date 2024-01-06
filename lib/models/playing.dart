// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Playing {
  String id;
  String action;
  String game;
  int order;
  bool accept;
  Playing({
    required this.id,
    required this.action,
    required this.game,
    required this.order,
    required this.accept,
  });

  Playing copyWith({
    String? id,
    String? action,
    String? game,
    int? order,
    bool? accept,
  }) {
    return Playing(
      id: id ?? this.id,
      action: action ?? this.action,
      game: game ?? this.game,
      order: order ?? this.order,
      accept: accept ?? this.accept,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'action': action,
      'game': game,
      'order': order,
      'accept': accept,
    };
  }

  factory Playing.fromMap(Map<String, dynamic> map) {
    return Playing(
      id: (map["id"] ?? '') as String,
      action: (map["action"] ?? '') as String,
      game: (map["game"] ?? '') as String,
      order: (map["order"] ?? 0) as int,
      accept: (map["accept"] ?? false) as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory Playing.fromJson(String source) =>
      Playing.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Playing(id: $id, action: $action, game: $game, order: $order, accept: $accept)';
  }

  @override
  bool operator ==(covariant Playing other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.action == action &&
        other.game == game &&
        other.order == order &&
        other.accept == accept;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        action.hashCode ^
        game.hashCode ^
        order.hashCode ^
        accept.hashCode;
  }
}
