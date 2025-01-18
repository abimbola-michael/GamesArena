// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Tutorial {
  String title;
  String link;
  int? id;
  Tutorial({
    required this.title,
    required this.link,
    this.id,
  });

  Tutorial copyWith({
    String? title,
    String? link,
    int? id,
  }) {
    return Tutorial(
      title: title ?? this.title,
      link: link ?? this.link,
      id: id ?? this.id,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'link': link,
      'id': id,
    };
  }

  factory Tutorial.fromMap(Map<String, dynamic> map) {
    return Tutorial(
      title: map['title'] as String,
      link: map['link'] as String,
      id: map['id'] != null ? map['id'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Tutorial.fromJson(String source) =>
      Tutorial.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Tutorial(title: $title, link: $link, id: $id)';

  @override
  bool operator ==(covariant Tutorial other) {
    if (identical(this, other)) return true;

    return other.title == title && other.link == link && other.id == id;
  }

  @override
  int get hashCode => title.hashCode ^ link.hashCode ^ id.hashCode;
}
