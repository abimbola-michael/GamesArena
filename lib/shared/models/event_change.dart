// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:firebase_database/firebase_database.dart';

class EventChange<T> {
  final DatabaseEventType type;
  final T value;

  EventChange({
    required this.type,
    required this.value,
  });

  @override
  String toString() => 'EventChange(type: $type, value: $value)';
}
