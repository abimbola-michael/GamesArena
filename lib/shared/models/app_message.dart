// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AppMessages {
  Map<String, dynamic>? general;
  Map<String, dynamic>? web;
  Map<String, dynamic>? android;
  Map<String, dynamic>? ios;
  Map<String, dynamic>? windows;
  Map<String, dynamic>? macos;
  Map<String, dynamic>? linux;
  Map<String, dynamic>? fuchsia;

  AppMessages({
    this.general,
    this.web,
    this.android,
    this.ios,
    this.windows,
    this.macos,
    this.linux,
    this.fuchsia,
  });

  AppMessages copyWith({
    Map<String, dynamic>? general,
    Map<String, dynamic>? web,
    Map<String, dynamic>? android,
    Map<String, dynamic>? ios,
    Map<String, dynamic>? windows,
    Map<String, dynamic>? macos,
    Map<String, dynamic>? linux,
    Map<String, dynamic>? fuchsia,
  }) {
    return AppMessages(
      general: general ?? this.general,
      web: web ?? this.web,
      android: android ?? this.android,
      ios: ios ?? this.ios,
      windows: windows ?? this.windows,
      macos: macos ?? this.macos,
      linux: linux ?? this.linux,
      fuchsia: fuchsia ?? this.fuchsia,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'general': general,
      'web': web,
      'android': android,
      'ios': ios,
      'windows': windows,
      'macos': macos,
      'linux': linux,
      'fuchsia': fuchsia,
    };
  }

  factory AppMessages.fromMap(Map<String, dynamic> map) {
    return AppMessages(
      general: map['general'] != null
          ? Map<String, dynamic>.from((map['general'] as Map<String, dynamic>))
          : null,
      web: map['web'] != null
          ? Map<String, dynamic>.from((map['web'] as Map<String, dynamic>))
          : null,
      android: map['android'] != null
          ? Map<String, dynamic>.from((map['android'] as Map<String, dynamic>))
          : null,
      ios: map['ios'] != null
          ? Map<String, dynamic>.from((map['ios'] as Map<String, dynamic>))
          : null,
      windows: map['windows'] != null
          ? Map<String, dynamic>.from((map['windows'] as Map<String, dynamic>))
          : null,
      macos: map['macos'] != null
          ? Map<String, dynamic>.from((map['macos'] as Map<String, dynamic>))
          : null,
      linux: map['linux'] != null
          ? Map<String, dynamic>.from((map['linux'] as Map<String, dynamic>))
          : null,
      fuchsia: map['fuchsia'] != null
          ? Map<String, dynamic>.from((map['fuchsia'] as Map<String, dynamic>))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppMessages.fromJson(String source) =>
      AppMessages.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AppMessages(general: $general, web: $web, android: $android, ios: $ios, windows: $windows, macos: $macos, linux: $linux, fuchsia: $fuchsia)';
  }

  @override
  bool operator ==(covariant AppMessages other) {
    if (identical(this, other)) return true;

    return mapEquals(other.general, general) &&
        mapEquals(other.web, web) &&
        mapEquals(other.android, android) &&
        mapEquals(other.ios, ios) &&
        mapEquals(other.windows, windows) &&
        mapEquals(other.macos, macos) &&
        mapEquals(other.linux, linux) &&
        mapEquals(other.fuchsia, fuchsia);
  }

  @override
  int get hashCode {
    return general.hashCode ^
        web.hashCode ^
        android.hashCode ^
        ios.hashCode ^
        windows.hashCode ^
        macos.hashCode ^
        linux.hashCode ^
        fuchsia.hashCode;
  }

  AppMessage? get generalAppMessage {
    return general != null ? AppMessage.fromMap(general!) : null;
  }

  AppMessage? get appMessage {
    Map<String, dynamic>? map;
    if (kIsWeb) map = web;
    if (Platform.isAndroid) map = android;
    if (Platform.isIOS) map = ios;
    if (Platform.isWindows) map = windows;
    if (Platform.isMacOS) map = macos;
    if (Platform.isLinux) map = linux;
    if (Platform.isFuchsia) map = fuchsia;
    return map != null ? AppMessage.fromMap(map) : null;
  }
}

class AppMessage {
  String? announcement;
  String? version;
  List<String>? features;
  String time;
  AppMessage({
    this.announcement,
    this.version,
    this.features,
    required this.time,
  });

  AppMessage copyWith({
    String? announcement,
    String? version,
    List<String>? features,
    String? time,
  }) {
    return AppMessage(
      announcement: announcement ?? this.announcement,
      version: version ?? this.version,
      features: features ?? this.features,
      time: time ?? this.time,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'announcement': announcement,
      'version': version,
      'features': features,
      'time': time,
    };
  }

  factory AppMessage.fromMap(Map<String, dynamic> map) {
    return AppMessage(
      announcement:
          map['announcement'] != null ? map['announcement'] as String : null,
      version: map['version'] != null ? map['version'] as String : null,
      features: map['features'] != null
          ? List<String>.from((map['features'] as List<dynamic>))
          : null,
      time: (map['time'] as Timestamp).millisecondsSinceEpoch.toString(),
    );
  }

  String toJson() => json.encode(toMap());

  factory AppMessage.fromJson(String source) =>
      AppMessage.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AppMessage(announcement: $announcement, version: $version, features: $features, time: $time)';
  }

  @override
  bool operator ==(covariant AppMessage other) {
    if (identical(this, other)) return true;

    return other.announcement == announcement &&
        other.version == version &&
        listEquals(other.features, features) &&
        other.time == time;
  }

  @override
  int get hashCode {
    return announcement.hashCode ^
        version.hashCode ^
        features.hashCode ^
        time.hashCode;
  }
}
