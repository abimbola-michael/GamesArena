// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Idtime {
  String id;
  String time;
   Idtime({
    required this.id,
    required this.time,
  });

  Idtime copyWith({
    String? id,
    String? time,
  }) {
    return Idtime(
      id: id ?? this.id,
      time: time ?? this.time,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'time': time,
    };
  }

  factory Idtime.fromMap(Map<String, dynamic> map) {
    return Idtime(
      id: (map["id"] ?? '') as String,
      time: (map["time"] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Idtime.fromJson(String source) => Idtime.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Idtime(id: $id, time: $time)';

  @override
  bool operator ==(covariant Idtime other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.time == time;
  }

  @override
  int get hashCode => id.hashCode ^ time.hashCode;
}
