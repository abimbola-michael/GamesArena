// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class PrivateKey {
  String mobileAdUnit;
  String webAdUnit;
  String firebaseAuthKey;
  String vapidKey;
  String chatGptApiKey;
  PrivateKey({
    required this.mobileAdUnit,
    required this.webAdUnit,
    required this.firebaseAuthKey,
    required this.vapidKey,
    required this.chatGptApiKey,
  });

  PrivateKey copyWith({
    String? mobileAdUnit,
    String? webAdUnit,
    String? firebaseAuthKey,
    String? vapidKey,
    String? chatGptApiKey,
  }) {
    return PrivateKey(
      mobileAdUnit: mobileAdUnit ?? this.mobileAdUnit,
      webAdUnit: webAdUnit ?? this.webAdUnit,
      firebaseAuthKey: firebaseAuthKey ?? this.firebaseAuthKey,
      vapidKey: vapidKey ?? this.vapidKey,
      chatGptApiKey: chatGptApiKey ?? this.chatGptApiKey,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mobileAdUnit': mobileAdUnit,
      'webAdUnit': webAdUnit,
      'firebaseAuthKey': firebaseAuthKey,
      'vapidKey': vapidKey,
      'chatGptApiKey': chatGptApiKey,
    };
  }

  factory PrivateKey.fromMap(Map<String, dynamic> map) {
    return PrivateKey(
      mobileAdUnit: map['mobileAdUnit'] as String,
      webAdUnit: map['webAdUnit'] as String,
      firebaseAuthKey: map['firebaseAuthKey'] as String,
      vapidKey: map['vapidKey'] as String,
      chatGptApiKey: map['chatGptApiKey'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PrivateKey.fromJson(String source) =>
      PrivateKey.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PrivateKey(mobileAdUnit: $mobileAdUnit, webAdUnit: $webAdUnit, firebaseAuthKey: $firebaseAuthKey, vapidKey: $vapidKey, chatGptApiKey: $chatGptApiKey)';
  }

  @override
  bool operator ==(covariant PrivateKey other) {
    if (identical(this, other)) return true;

    return other.mobileAdUnit == mobileAdUnit &&
        other.webAdUnit == webAdUnit &&
        other.firebaseAuthKey == firebaseAuthKey &&
        other.vapidKey == vapidKey &&
        other.chatGptApiKey == chatGptApiKey;
  }

  @override
  int get hashCode {
    return mobileAdUnit.hashCode ^
        webAdUnit.hashCode ^
        firebaseAuthKey.hashCode ^
        vapidKey.hashCode ^
        chatGptApiKey.hashCode;
  }
}
