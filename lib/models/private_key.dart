// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class PrivateKey {
  String mobileAdUnit;
  String webAdUnit;
  String firebaseAuthKey;
  String vapidKey;
  PrivateKey({
    required this.mobileAdUnit,
    required this.webAdUnit,
    required this.firebaseAuthKey,
    required this.vapidKey,
  });

  PrivateKey copyWith({
    String? mobileAdUnit,
    String? webAdUnit,
    String? firebaseAuthKey,
    String? vapidKey,
  }) {
    return PrivateKey(
      mobileAdUnit: mobileAdUnit ?? this.mobileAdUnit,
      webAdUnit: webAdUnit ?? this.webAdUnit,
      firebaseAuthKey: firebaseAuthKey ?? this.firebaseAuthKey,
      vapidKey: vapidKey ?? this.vapidKey,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mobileAdUnit': mobileAdUnit,
      'webAdUnit': webAdUnit,
      'firebaseAuthKey': firebaseAuthKey,
      'vapidKey': vapidKey,
    };
  }

  factory PrivateKey.fromMap(Map<String, dynamic> map) {
    return PrivateKey(
      mobileAdUnit: (map["mobileAdUnit"] ?? '') as String,
      webAdUnit: (map["webAdUnit"] ?? '') as String,
      firebaseAuthKey: (map["firebaseAuthKey"] ?? '') as String,
      vapidKey: (map["vapidKey"] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PrivateKey.fromJson(String source) =>
      PrivateKey.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PrivateKey(mobileAdUnit: $mobileAdUnit, webAdUnit: $webAdUnit, firebaseAuthKey: $firebaseAuthKey, vapidKey: $vapidKey)';
  }

  @override
  bool operator ==(covariant PrivateKey other) {
    if (identical(this, other)) return true;

    return other.mobileAdUnit == mobileAdUnit &&
        other.webAdUnit == webAdUnit &&
        other.firebaseAuthKey == firebaseAuthKey &&
        other.vapidKey == vapidKey;
  }

  @override
  int get hashCode {
    return mobileAdUnit.hashCode ^
        webAdUnit.hashCode ^
        firebaseAuthKey.hashCode ^
        vapidKey.hashCode;
  }
}
