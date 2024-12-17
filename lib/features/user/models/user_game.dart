// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class UserGame {
  String name;
  String ability;
  UserGame({
    required this.name,
    required this.ability,
  });

  UserGame copyWith({
    String? name,
    String? ability,
  }) {
    return UserGame(
      name: name ?? this.name,
      ability: ability ?? this.ability,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'ability': ability,
    };
  }

  factory UserGame.fromMap(Map<String, dynamic> map) {
    return UserGame(
      name: map['name'] as String,
      ability: map['ability'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserGame.fromJson(String source) =>
      UserGame.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'UserGame(name: $name, ability: $ability)';

  @override
  bool operator ==(covariant UserGame other) {
    if (identical(this, other)) return true;

    return other.name == name && other.ability == ability;
  }

  @override
  int get hashCode => name.hashCode ^ ability.hashCode;
}
