// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class OnboardingInfo {
  String title;
  String message;
  String image;
  OnboardingInfo({
    required this.title,
    required this.message,
    required this.image,
  });

  OnboardingInfo copyWith({
    String? title,
    String? message,
    String? image,
  }) {
    return OnboardingInfo(
      title: title ?? this.title,
      message: message ?? this.message,
      image: image ?? this.image,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'message': message,
      'image': image,
    };
  }

  factory OnboardingInfo.fromMap(Map<String, dynamic> map) {
    return OnboardingInfo(
      title: map['title'] as String,
      message: map['message'] as String,
      image: map['image'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory OnboardingInfo.fromJson(String source) =>
      OnboardingInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'OnboardingInfo(title: $title, message: $message, image: $image)';

  @override
  bool operator ==(covariant OnboardingInfo other) {
    if (identical(this, other)) return true;

    return other.title == title &&
        other.message == message &&
        other.image == image;
  }

  @override
  int get hashCode => title.hashCode ^ message.hashCode ^ image.hashCode;
}
