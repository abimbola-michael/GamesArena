// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:gamesarena/features/user/models/user_game.dart';

class User {
  String user_id;
  String username;
  String email;
  String phone;
  List<String>? tokens;
  String time;
  String? time_modified;
  String? time_deleted;
  String last_seen;
  String? profile_photo;
  List<String>? games;
  bool? answeredRequests;
  String? subExpiryTime;
  String? sub;
  String? phoneName;
  bool? checked;

  User({
    required this.user_id,
    required this.username,
    required this.email,
    required this.phone,
    this.tokens,
    required this.time,
    this.time_modified,
    this.time_deleted,
    required this.last_seen,
    this.profile_photo,
    this.games,
    this.answeredRequests,
    this.subExpiryTime,
    this.sub,
    this.phoneName,
    this.checked,
  });

  User copyWith({
    String? user_id,
    String? username,
    String? email,
    String? phone,
    List<String>? tokens,
    String? time,
    String? time_modified,
    String? time_deleted,
    String? last_seen,
    String? profile_photo,
    List<String>? games,
    bool? answeredRequests,
    String? subExpiryTime,
    String? sub,
    String? phoneName,
    bool? checked,
  }) {
    return User(
      user_id: user_id ?? this.user_id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      tokens: tokens ?? this.tokens,
      time: time ?? this.time,
      time_modified: time_modified ?? this.time_modified,
      time_deleted: time_deleted ?? this.time_deleted,
      last_seen: last_seen ?? this.last_seen,
      profile_photo: profile_photo ?? this.profile_photo,
      games: games ?? this.games,
      answeredRequests: answeredRequests ?? this.answeredRequests,
      subExpiryTime: subExpiryTime ?? this.subExpiryTime,
      sub: sub ?? this.sub,
      phoneName: phoneName ?? this.phoneName,
      checked: checked ?? this.checked,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'user_id': user_id,
      'username': username,
      'email': email,
      'phone': phone,
      'tokens': tokens,
      'time': time,
      'time_modified': time_modified,
      'time_deleted': time_deleted,
      'last_seen': last_seen,
      'profile_photo': profile_photo,
      'games': games,
      'answeredRequests': answeredRequests,
      'subExpiryTime': subExpiryTime,
      'sub': sub,
      'phoneName': phoneName,
      'checked': checked,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      user_id: map['user_id'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      tokens: map['tokens'] != null
          ? List<String>.from((map['tokens'] as List<dynamic>))
          : null,
      time: map['time'] as String,
      time_modified:
          map['time_modified'] != null ? map['time_modified'] as String : null,
      time_deleted:
          map['time_deleted'] != null ? map['time_deleted'] as String : null,
      last_seen: map['last_seen'] as String,
      profile_photo:
          map['profile_photo'] != null ? map['profile_photo'] as String : null,
      games: map['games'] != null
          ? List<String>.from((map['games'] as List<dynamic>))
          : null,
      answeredRequests: map['answeredRequests'] != null
          ? map['answeredRequests'] as bool
          : null,
      subExpiryTime:
          map['subExpiryTime'] != null ? map['subExpiryTime'] as String : null,
      sub: map['sub'] != null ? map['sub'] as String : null,
      phoneName: map['phoneName'] != null ? map['phoneName'] as String : null,
      checked: map['checked'] != null ? map['checked'] as bool : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(user_id: $user_id, username: $username, email: $email, phone: $phone, tokens: $tokens, time: $time, time_modified: $time_modified, time_deleted: $time_deleted, last_seen: $last_seen, profile_photo: $profile_photo, games: $games, answeredRequests: $answeredRequests, subExpiryTime: $subExpiryTime, sub: $sub, phoneName: $phoneName, checked: $checked)';
  }

  @override
  bool operator ==(covariant User other) {
    if (identical(this, other)) return true;

    return other.user_id == user_id &&
        other.username == username &&
        other.email == email &&
        other.phone == phone &&
        listEquals(other.tokens, tokens) &&
        other.time == time &&
        other.time_modified == time_modified &&
        other.time_deleted == time_deleted &&
        other.last_seen == last_seen &&
        other.profile_photo == profile_photo &&
        listEquals(other.games, games) &&
        other.answeredRequests == answeredRequests &&
        other.subExpiryTime == subExpiryTime &&
        other.sub == sub &&
        other.phoneName == phoneName &&
        other.checked == checked;
  }

  @override
  int get hashCode {
    return user_id.hashCode ^
        username.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        tokens.hashCode ^
        time.hashCode ^
        time_modified.hashCode ^
        time_deleted.hashCode ^
        last_seen.hashCode ^
        profile_photo.hashCode ^
        games.hashCode ^
        answeredRequests.hashCode ^
        subExpiryTime.hashCode ^
        sub.hashCode ^
        phoneName.hashCode ^
        checked.hashCode;
  }
}
