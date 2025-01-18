import '../../core/firebase/firestore_methods.dart';
import 'models/tutorial.dart';

FirestoreMethods fm = FirestoreMethods();

Future<Map<String, Tutorial>> getAppTutorials() async {
  final tutorialMap = await fm.getValue((map) => map, ["public", "tutorials"]);
  return tutorialMap != null
      ? tutorialMap.map((key, value) => MapEntry(key, Tutorial.fromMap(value)))
      : {};
}
