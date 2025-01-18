// ignore_for_file: public_member_api_docs, sort_constructors_first

enum ListChangeType { added, modified, removed }

class ListChange<T> {
  final ListChangeType type;
  final T value;
  final T? oldValue;
  final int index;
  final int oldIndex;
  ListChange({
    required this.index,
    required this.oldIndex,
    required this.type,
    required this.value,
    this.oldValue,
  });

  @override
  String toString() {
    return 'ListChange(type: $type, value: $value, oldValue: $oldValue, index: $index, oldIndex: $oldIndex)';
  }
}
