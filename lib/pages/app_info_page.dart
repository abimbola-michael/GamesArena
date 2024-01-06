import 'package:flutter/material.dart';
import 'package:gamesarena/components/HeadingText.dart';
import 'package:gamesarena/components/MessageText.dart';
import 'package:gamesarena/models/app_info.dart';
import 'package:gamesarena/pages/app_info_words.dart';

class AppInfoPage extends StatefulWidget {
  final String type;
  final bool isAccept;
  const AppInfoPage({super.key, required this.type, this.isAccept = false});

  @override
  State<AppInfoPage> createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  List<AppInfo> typeAppInfos = [];
  @override
  void initState() {
    super.initState();
    if (widget.type == "Terms and Conditions and Privacy Policy") {
      typeAppInfos.add(appInfos["Terms and Conditions"]!);
      typeAppInfos.add(appInfos["Privacy Policy"]!);
    } else {
      typeAppInfos.add(appInfos[widget.type]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ...typeAppInfos.map((typeAppInfo) => Column(
                children: [
                  HeadingText(
                    typeAppInfo.name,
                    isLarge: true,
                  ),
                  MessageText(typeAppInfo.intro),
                  ...List.generate(
                      typeAppInfo.subInfos.length,
                      (index) => Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HeadingText(
                                  "${index + 1}. ${typeAppInfo.subInfos[index].title}"),
                              ...List.generate(
                                typeAppInfo.subInfos[index].texts.length,
                                (index2) => MessageText(
                                  typeAppInfo.subInfos[index].texts[index2],
                                  prefix: "${index2 + 1}. ",
                                ),
                              )
                            ],
                          )),
                  MessageText(typeAppInfo.outro),
                ],
              ))
        ],
      ),
      // bottomNavigationBar: widget.isAccept
      //     ? ActionButton("Accept", onPressed: () {
      //         Navigator.of(context).pop(true);
      //       }, height: 50)
      //     : null,
    );
  }
}
