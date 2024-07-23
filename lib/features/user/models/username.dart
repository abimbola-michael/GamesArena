// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Username {
  String username;
  Username({
    required this.username,
  });

  Username copyWith({
    String? username,
  }) {
    return Username(
      username: username ?? this.username,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'username': username,
    };
  }

  factory Username.fromMap(Map<String, dynamic> map) {
    return Username(
      username: map['username'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Username.fromJson(String source) =>
      Username.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Username(username: $username)';

  @override
  bool operator ==(covariant Username other) {
    if (identical(this, other)) return true;

    return other.username == username;
  }

  @override
  int get hashCode => username.hashCode;
}
