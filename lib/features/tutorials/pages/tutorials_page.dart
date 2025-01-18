import 'package:flutter/material.dart';
import 'package:gamesarena/features/tutorials/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/widgets/app_appbar.dart';
import 'package:gamesarena/theme/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../main.dart';
import '../../../shared/widgets/app_button.dart';
import '../models/tutorial.dart';

class TutorialsPage extends StatefulWidget {
  final String? type;
  const TutorialsPage({super.key, this.type});

  @override
  State<TutorialsPage> createState() => _TutorialsPageState();
}

class _TutorialsPageState extends State<TutorialsPage> {
  List<Tutorial> tutorials = [];

  int currentIndex = -1;
  WebViewController? controller;
  @override
  void initState() {
    super.initState();
    readTutorials();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void readTutorials() async {
    tutorialsMap ??= await getAppTutorials();
    if (tutorialsMap == null) return;
    if (widget.type != null) {
      if (tutorialsMap![widget.type] != null) {
        tutorials.add(tutorialsMap![widget.type]!);
      }
    } else {
      tutorials = tutorialsMap!.values.toList();
      tutorials.sortList((tutorial) => tutorial.id ?? 0, false);
    }
    if (tutorials.isEmpty) return;
    currentIndex = 0;

    playVideo();
    setState(() {});
  }

  void playNext() {
    if (currentIndex >= tutorials.length - 1) return;
    currentIndex++;
    playVideo();
  }

  void playPrev() {
    if (currentIndex <= 0) return;
    currentIndex--;
    playVideo();
  }

  void playVideo() {
    final tutorial = tutorials[currentIndex];
    String link = tutorial.link;
    if (link.isEmpty) {
      playNext();
      return;
    }
    // if (link.isEmpty) {
    //   link = currentIndex == 0
    //       ? "https://www.youtube.com/watch?v=Rwo2nRFz240"
    //       : currentIndex == 1
    //           ? "https://www.youtube.com/watch?v=4rEE8acnkGw"
    //           : "https://www.youtube.com/watch?v=hUfaBfqiZ_s";
    // }
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(link));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppAppBar(
            title: "Tutorials",
            subtitle:
                currentIndex == -1 ? null : tutorials[currentIndex].title),
        body: Column(
          children: [
            Expanded(
              child: controller == null
                  ? Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: offtint,
                    )
                  : WebViewWidget(controller: controller!),
            ),
            Row(
              children: [
                Expanded(
                  child: currentIndex == 0
                      ? Container()
                      : AppButton(title: "Previous", onPressed: playPrev),
                ),
                Expanded(
                  child: currentIndex == tutorials.length - 1
                      ? Container()
                      : AppButton(title: "Next", onPressed: playNext),
                )
              ],
            )
          ],
        ));
  }
}
