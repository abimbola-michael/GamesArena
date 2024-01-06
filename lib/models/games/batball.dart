// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';


class BatBallDetails {
  double? player1X;
  double? player2X;
  double? player1Y;
  double? player2Y;
  double? player1ScreenWidth;
  double? player1ScreenHeight;
  double? player2ScreenWidth;
  double? player2ScreenHeight;
  int? speed;
  int? angle;
  String? hDir;
  String? vDir;

  BatBallDetails({
    this.player1X,
    this.player2X,
    this.player1Y,
    this.player2Y,
    this.player1ScreenWidth,
    this.player1ScreenHeight,
    this.player2ScreenWidth,
    this.player2ScreenHeight,
    this.speed,
    this.angle,
    this.hDir,
    this.vDir,
  });

  BatBallDetails copyWith({
    double? player1X,
    double? player2X,
    double? player1Y,
    double? player2Y,
    double? player1ScreenWidth,
    double? player1ScreenHeight,
    double? player2ScreenWidth,
    double? player2ScreenHeight,
    int? speed,
    int? angle,
    String? hDir,
    String? vDir,
  }) {
    return BatBallDetails(
      player1X: player1X ?? this.player1X,
      player2X: player2X ?? this.player2X,
      player1Y: player1Y ?? this.player1Y,
      player2Y: player2Y ?? this.player2Y,
      player1ScreenWidth: player1ScreenWidth ?? this.player1ScreenWidth,
      player1ScreenHeight: player1ScreenHeight ?? this.player1ScreenHeight,
      player2ScreenWidth: player2ScreenWidth ?? this.player2ScreenWidth,
      player2ScreenHeight: player2ScreenHeight ?? this.player2ScreenHeight,
      speed: speed ?? this.speed,
      angle: angle ?? this.angle,
      hDir: hDir ?? this.hDir,
      vDir: vDir ?? this.vDir,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'player1X': player1X,
      'player2X': player2X,
      'player1Y': player1Y,
      'player2Y': player2Y,
      'player1ScreenWidth': player1ScreenWidth,
      'player1ScreenHeight': player1ScreenHeight,
      'player2ScreenWidth': player2ScreenWidth,
      'player2ScreenHeight': player2ScreenHeight,
      'speed': speed,
      'angle': angle,
      'hDir': hDir,
      'vDir': vDir,
    };
  }

  factory BatBallDetails.fromMap(Map<String, dynamic> map) {
    return BatBallDetails(
      player1X:
          map['player1X'] != null ? map["player1X"] ?? 0.0 : null,
      player2X:
          map['player2X'] != null ? map["player2X"] ?? 0.0 : null,
      player1Y:
          map['player1Y'] != null ? map["player1Y"] ?? 0.0 : null,
      player2Y:
          map['player2Y'] != null ? map["player2Y"] ?? 0.0 : null,
      player1ScreenWidth: map['player1ScreenWidth'] != null
          ? map["player1ScreenWidth"] ?? 0.0
          : null,
      player1ScreenHeight: map['player1ScreenHeight'] != null
          ? map["player1ScreenHeight"] ?? 0.0
          : null,
      player2ScreenWidth: map['player2ScreenWidth'] != null
          ? map["player2ScreenWidth"] ?? 0.0
          : null,
      player2ScreenHeight: map['player2ScreenHeight'] != null
          ? map["player2ScreenHeight"] ?? 0.0
          : null,
      speed: map['speed'] != null ? map["speed"] ?? 0 : null,
      angle: map['angle'] != null ? map["angle"] ?? 0 : null,
      hDir: map['hDir'] != null ? map["hDir"] ?? '' : null,
      vDir: map['vDir'] != null ? map["vDir"] ?? '' : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BatBallDetails.fromJson(String source) =>
      BatBallDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BatBallDetails(player1X: $player1X, player2X: $player2X, player1Y: $player1Y, player2Y: $player2Y, player1ScreenWidth: $player1ScreenWidth, player1ScreenHeight: $player1ScreenHeight, player2ScreenWidth: $player2ScreenWidth, player2ScreenHeight: $player2ScreenHeight, speed: $speed, angle: $angle, hDir: $hDir, vDir: $vDir)';
  }

  @override
  bool operator ==(covariant BatBallDetails other) {
    if (identical(this, other)) return true;

    return other.player1X == player1X &&
        other.player2X == player2X &&
        other.player1Y == player1Y &&
        other.player2Y == player2Y &&
        other.player1ScreenWidth == player1ScreenWidth &&
        other.player1ScreenHeight == player1ScreenHeight &&
        other.player2ScreenWidth == player2ScreenWidth &&
        other.player2ScreenHeight == player2ScreenHeight &&
        other.speed == speed &&
        other.angle == angle &&
        other.hDir == hDir &&
        other.vDir == vDir;
  }

  @override
  int get hashCode {
    return player1X.hashCode ^
        player2X.hashCode ^
        player1Y.hashCode ^
        player2Y.hashCode ^
        player1ScreenWidth.hashCode ^
        player1ScreenHeight.hashCode ^
        player2ScreenWidth.hashCode ^
        player2ScreenHeight.hashCode ^
        speed.hashCode ^
        angle.hashCode ^
        hDir.hashCode ^
        vDir.hashCode;
  }
}
