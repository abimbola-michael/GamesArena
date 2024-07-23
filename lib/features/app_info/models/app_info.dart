class SubInfo {
  String title;
  List<String> texts;
  SubInfo({required this.title, required this.texts});
}

class AppInfo {
  String name;
  String intro;
  List<SubInfo> subInfos;
  String outro;
  AppInfo(
      {required this.name,
      required this.intro,
      required this.subInfos,
      required this.outro});
}
