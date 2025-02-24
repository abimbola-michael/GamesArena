// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class User {
  String user_id = "";
  String username = "";
  String email = "";
  String phone = "";
  String token = "";
  String time = "";
  String last_seen = "";
  bool checked = false;
  String action = "";
  User({
    required this.user_id,
    required this.username,
    required this.email,
    required this.phone,
    required this.token,
    required this.time,
    required this.last_seen,
  });

  User copyWith({
    String? user_id,
    String? username,
    String? email,
    String? phone,
    String? token,
    String? time,
    String? last_seen,
  }) {
    return User(
      user_id: user_id ?? this.user_id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      token: token ?? this.token,
      time: time ?? this.time,
      last_seen: last_seen ?? this.last_seen,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'user_id': user_id,
      'username': username,
      'email': email,
      'phone': phone,
      'token': token,
      'time': time,
      'last_seen': last_seen,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      user_id: (map["user_id"] ?? '') as String,
      username: (map["username"] ?? '') as String,
      email: (map["email"] ?? '') as String,
      phone: (map["phone"] ?? '') as String,
      token: (map["token"] ?? '') as String,
      time: (map["time"] ?? '') as String,
      last_seen: (map["last_seen"] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(user_id: $user_id, username: $username, email: $email, phone: $phone, token: $token, time: $time, last_seen: $last_seen)';
  }

  @override
  bool operator ==(covariant User other) {
    if (identical(this, other)) return true;

    return other.user_id == user_id &&
        other.username == username &&
        other.email == email &&
        other.phone == phone &&
        other.token == token &&
        other.time == time &&
        other.last_seen == last_seen;
  }

  @override
  int get hashCode {
    return user_id.hashCode ^
        username.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        token.hashCode ^
        time.hashCode ^
        last_seen.hashCode;
  }
}
