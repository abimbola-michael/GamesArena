// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../enums.dart';

class PhoneContact {
  String phone;
  String? name;
  String createdAt;
  String? modifiedAt;
  ContactStatus? contactStatus;
  List<String>? userIds;

  PhoneContact({
    required this.phone,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    required this.contactStatus,
    this.userIds,
  });

  PhoneContact copyWith({
    String? phone,
    String? name,
    String? createdAt,
    String? modifiedAt,
    ContactStatus? contactStatus,
    List<String>? userIds,
  }) {
    return PhoneContact(
      phone: phone ?? this.phone,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      contactStatus: contactStatus ?? this.contactStatus,
      userIds: userIds ?? this.userIds,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'phone': phone,
      'name': name,
      'createdAt': createdAt,
      'modifiedAt': modifiedAt,
      'contactStatus': contactStatus?.index,
      'userIds': userIds,
    };
  }

  factory PhoneContact.fromMap(Map<String, dynamic> map) {
    return PhoneContact(
      phone: map['phone'] as String,
      name: map['name'] != null ? map['name'] as String : null,
      createdAt: map['createdAt'] as String,
      modifiedAt:
          map['modifiedAt'] != null ? map['modifiedAt'] as String : null,
      contactStatus: map['contactStatus'] != null
          ? ContactStatus.values[map['contactStatus']]
          : null,
      userIds: map['userIds'] != null
          ? List<String>.from((map['userIds'] as List<dynamic>))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PhoneContact.fromJson(String source) =>
      PhoneContact.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PhoneContact(phone: $phone, name: $name, createdAt: $createdAt, modifiedAt: $modifiedAt, contactStatus: $contactStatus, userIds: $userIds)';
  }

  @override
  bool operator ==(covariant PhoneContact other) {
    if (identical(this, other)) return true;

    return other.phone == phone &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.modifiedAt == modifiedAt &&
        other.contactStatus == contactStatus &&
        listEquals(other.userIds, userIds);
  }

  @override
  int get hashCode {
    return phone.hashCode ^
        name.hashCode ^
        createdAt.hashCode ^
        modifiedAt.hashCode ^
        contactStatus.hashCode ^
        userIds.hashCode;
  }
}
