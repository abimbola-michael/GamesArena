// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class PrivateKey {
  String mobileAdUnit;
  String webAdUnit;
  String firebaseAuthKey;
  String vapidKey;
  String chatGptApiKey;
  String geminiApiKey;
  String clientEmail;
  String clientId;
  String privateKey;
  String projectId;
  PrivateKey({
    required this.mobileAdUnit,
    required this.webAdUnit,
    required this.firebaseAuthKey,
    required this.vapidKey,
    required this.chatGptApiKey,
    required this.geminiApiKey,
    required this.clientEmail,
    required this.clientId,
    required this.privateKey,
    required this.projectId,
  });

  PrivateKey copyWith({
    String? mobileAdUnit,
    String? webAdUnit,
    String? firebaseAuthKey,
    String? vapidKey,
    String? chatGptApiKey,
    String? geminiApiKey,
    String? clientEmail,
    String? clientId,
    String? privateKey,
    String? projectId,
  }) {
    return PrivateKey(
      mobileAdUnit: mobileAdUnit ?? this.mobileAdUnit,
      webAdUnit: webAdUnit ?? this.webAdUnit,
      firebaseAuthKey: firebaseAuthKey ?? this.firebaseAuthKey,
      vapidKey: vapidKey ?? this.vapidKey,
      chatGptApiKey: chatGptApiKey ?? this.chatGptApiKey,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      clientEmail: clientEmail ?? this.clientEmail,
      clientId: clientId ?? this.clientId,
      privateKey: privateKey ?? this.privateKey,
      projectId: projectId ?? this.projectId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mobileAdUnit': mobileAdUnit,
      'webAdUnit': webAdUnit,
      'firebaseAuthKey': firebaseAuthKey,
      'vapidKey': vapidKey,
      'chatGptApiKey': chatGptApiKey,
      'geminiApiKey': geminiApiKey,
      'clientEmail': clientEmail,
      'clientId': clientId,
      'privateKey': privateKey,
      'projectId': projectId,
    };
  }

  factory PrivateKey.fromMap(Map<String, dynamic> map) {
    return PrivateKey(
      mobileAdUnit: map['mobileAdUnit'] as String,
      webAdUnit: map['webAdUnit'] as String,
      firebaseAuthKey: map['firebaseAuthKey'] as String,
      vapidKey: map['vapidKey'] as String,
      chatGptApiKey: map['chatGptApiKey'] as String,
      geminiApiKey: map['geminiApiKey'] as String,
      clientEmail: map['clientEmail'] as String,
      clientId: map['clientId'] as String,
      privateKey: map['privateKey'] as String,
      projectId: map['projectId'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PrivateKey.fromJson(String source) =>
      PrivateKey.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PrivateKey(mobileAdUnit: $mobileAdUnit, webAdUnit: $webAdUnit, firebaseAuthKey: $firebaseAuthKey, vapidKey: $vapidKey, chatGptApiKey: $chatGptApiKey, geminiApiKey: $geminiApiKey, clientEmail: $clientEmail, clientId: $clientId, privateKey: $privateKey, projectId: $projectId)';
  }

  @override
  bool operator ==(covariant PrivateKey other) {
    if (identical(this, other)) return true;

    return other.mobileAdUnit == mobileAdUnit &&
        other.webAdUnit == webAdUnit &&
        other.firebaseAuthKey == firebaseAuthKey &&
        other.vapidKey == vapidKey &&
        other.chatGptApiKey == chatGptApiKey &&
        other.geminiApiKey == geminiApiKey &&
        other.clientEmail == clientEmail &&
        other.clientId == clientId &&
        other.privateKey == privateKey &&
        other.projectId == projectId;
  }

  @override
  int get hashCode {
    return mobileAdUnit.hashCode ^
        webAdUnit.hashCode ^
        firebaseAuthKey.hashCode ^
        vapidKey.hashCode ^
        chatGptApiKey.hashCode ^
        geminiApiKey.hashCode ^
        clientEmail.hashCode ^
        clientId.hashCode ^
        privateKey.hashCode ^
        projectId.hashCode;
  }
}
