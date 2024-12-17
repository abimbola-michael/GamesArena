// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:gamesarena/features/user/models/user_game.dart';

class User {
  String user_id;
  String username;
  String email;
  String phone;
  String token;
  String time;
  String? time_modified;
  String? time_deleted;
  String last_seen;
  String? profile_photo;
  List<UserGame>? user_games;
  bool? answeredRequests;
  String? subExpiryTime;
  String? sub;
  bool checked = false;
  String action = "";
  String? phoneName;
  User({
    required this.user_id,
    required this.username,
    required this.email,
    required this.phone,
    required this.token,
    required this.time,
    this.time_modified,
    this.time_deleted,
    required this.last_seen,
    this.profile_photo,
    this.user_games,
    this.answeredRequests,
    this.subExpiryTime,
    this.sub,
  });

  User copyWith({
    String? user_id,
    String? username,
    String? email,
    String? phone,
    String? token,
    String? time,
    String? time_modified,
    String? time_deleted,
    String? last_seen,
    String? profile_photo,
    List<UserGame>? user_games,
    bool? answeredRequests,
    String? subExpiryTime,
    String? sub,
  }) {
    return User(
      user_id: user_id ?? this.user_id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      token: token ?? this.token,
      time: time ?? this.time,
      time_modified: time_modified ?? this.time_modified,
      time_deleted: time_deleted ?? this.time_deleted,
      last_seen: last_seen ?? this.last_seen,
      profile_photo: profile_photo ?? this.profile_photo,
      user_games: user_games ?? this.user_games,
      answeredRequests: answeredRequests ?? this.answeredRequests,
      subExpiryTime: subExpiryTime ?? this.subExpiryTime,
      sub: sub ?? this.sub,
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
      'time_modified': time_modified,
      'time_deleted': time_deleted,
      'last_seen': last_seen,
      'profile_photo': profile_photo,
      'user_games': user_games?.map((x) => x?.toMap()).toList(),
      'answeredRequests': answeredRequests,
      'subExpiryTime': subExpiryTime,
      'sub': sub,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      user_id: map['user_id'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      token: map['token'] as String,
      time: map['time'] as String,
      time_modified:
          map['time_modified'] != null ? map['time_modified'] as String : null,
      time_deleted:
          map['time_deleted'] != null ? map['time_deleted'] as String : null,
      last_seen: map['last_seen'] as String,
      profile_photo:
          map['profile_photo'] != null ? map['profile_photo'] as String : null,
      user_games: map['user_games'] != null
          ? List<UserGame>.from(
              (map['user_games'] as List<dynamic>).map<UserGame?>(
                (x) => UserGame.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      answeredRequests: map['answeredRequests'] != null
          ? map['answeredRequests'] as bool
          : null,
      subExpiryTime:
          map['subExpiryTime'] != null ? map['subExpiryTime'] as String : null,
      sub: map['sub'] != null ? map['sub'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(user_id: $user_id, username: $username, email: $email, phone: $phone, token: $token, time: $time, time_modified: $time_modified, time_deleted: $time_deleted, last_seen: $last_seen, profile_photo: $profile_photo, user_games: $user_games, answeredRequests: $answeredRequests, subExpiryTime: $subExpiryTime, sub: $sub)';
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
        other.time_modified == time_modified &&
        other.time_deleted == time_deleted &&
        other.last_seen == last_seen &&
        other.profile_photo == profile_photo &&
        listEquals(other.user_games, user_games) &&
        other.answeredRequests == answeredRequests &&
        other.subExpiryTime == subExpiryTime &&
        other.sub == sub;
  }

  @override
  int get hashCode {
    return user_id.hashCode ^
        username.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        token.hashCode ^
        time.hashCode ^
        time_modified.hashCode ^
        time_deleted.hashCode ^
        last_seen.hashCode ^
        profile_photo.hashCode ^
        user_games.hashCode ^
        answeredRequests.hashCode ^
        subExpiryTime.hashCode ^
        sub.hashCode;
  }
}
