// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Username {
  String username;
  String email;
  Username({
    required this.username,
    required this.email,
  });

  

  Username copyWith({
    String? username,
    String? email,
  }) {
    return Username(
      username: username ?? this.username,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'username': username,
      'email': email,
    };
  }

  factory Username.fromMap(Map<String, dynamic> map) {
    return Username(
      username: (map["username"] ?? '') as String,
      email: (map["email"] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Username.fromJson(String source) => Username.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Username(username: $username, email: $email)';

  @override
  bool operator ==(covariant Username other) {
    if (identical(this, other)) return true;
  
    return 
      other.username == username &&
      other.email == email;
  }

  @override
  int get hashCode => username.hashCode ^ email.hashCode;
}
