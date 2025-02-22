import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/features/tutorials/services.dart';
import 'package:gamesarena/shared/widgets/app_appbar.dart';
// import 'package:webview_all/webview_all.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../main.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/app_button.dart';
import '../models/tutorial.dart';
import '../views/youtube_embed_others.dart';
// import '../views/youtube_embed_web.dart'
//     if (dart.library.io) '../views/youtube_embed_others.dart';

class TutorialsPage extends StatefulWidget {
  final String type;
  const TutorialsPage({super.key, this.type = "all"});

  @override
  State<TutorialsPage> createState() => _TutorialsPageState();
}

class _TutorialsPageState extends State<TutorialsPage> {
  //List<Tutorial> tutorials = [];

  //int currentIndex = -1;
  late WebViewController controller;
  String link = "";
  String title = "";
  @override
  void initState() {
    super.initState();
    readTutorialLink();
  }

  void readTutorialLink() async {
    if (isAndroidAndIos) {
      controller = WebViewController();
    }
    tutorialsMap ??= await getAppTutorials();
    if (tutorialsMap == null) return;
    final tutorial = tutorialsMap![widget.type];
    if (tutorial == null) return;

    link = tutorial.link;
    title = tutorial.title;

    if (isAndroidAndIos) {
      playVideo();
    }
    setState(() {});
  }

  // void readTutorials() async {
  //   tutorialsMap ??= await getAppTutorials();
  //   if (tutorialsMap == null) return;
  //   if (tutorialsMap![widget.type] != null) {
  //     tutorials.add(tutorialsMap![widget.type]!);
  //   }
  //   // if (widget.type != null) {
  //   //   if (tutorialsMap![widget.type] != null) {
  //   //     tutorials.add(tutorialsMap![widget.type]!);
  //   //   }
  //   // } else {
  //   //   tutorials = tutorialsMap!.values.toList();
  //   //   tutorials.sortList((tutorial) => tutorial.id ?? 0, false);
  //   // }
  //   // print("tutorials = $tutorials");
  //   if (tutorials.isEmpty) return;
  //   currentIndex = 0;

  //   playVideo();
  //   setState(() {});
  // }

  // void playNext() {
  //   if (currentIndex >= tutorials.length - 1) return;
  //   currentIndex++;
  //   playVideo();
  // }

  // void playPrev() {
  //   if (currentIndex <= 0) return;
  //   currentIndex--;
  //   playVideo();
  // }

  // void playVideo() {
  //   final tutorial = tutorials[currentIndex];
  //   String link = tutorial.link;
  //   if (link.isEmpty) {
  //     playNext();
  //     return;
  //   }
  //   // if (link.isEmpty) {
  //   //   link = currentIndex == 0
  //   //       ? "https://www.youtube.com/watch?v=Rwo2nRFz240"
  //   //       : currentIndex == 1
  //   //           ? "https://www.youtube.com/watch?v=4rEE8acnkGw"
  //   //           : "https://www.youtube.com/watch?v=hUfaBfqiZ_s";
  //   // }
  //   controller = WebViewController()
  //     ..setJavaScriptMode(JavaScriptMode.unrestricted)
  //     ..setNavigationDelegate(
  //       NavigationDelegate(
  //         onProgress: (int progress) {
  //           // Update loading bar.
  //         },
  //         onPageStarted: (String url) {},
  //         onPageFinished: (String url) {},
  //         onHttpError: (HttpResponseError error) {},
  //         onWebResourceError: (WebResourceError error) {},
  //         onNavigationRequest: (NavigationRequest request) {
  //           // if (request.url.startsWith('https://www.youtube.com/')) {
  //           //   return NavigationDecision.prevent;
  //           // }
  //           return NavigationDecision.navigate;
  //         },
  //       ),
  //     )
  //     ..loadRequest(Uri.parse(link));
  // }

  void playVideo() {
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {},
        onPageFinished: (String url) {},
        onHttpError: (HttpResponseError error) {},
        // onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          // if (request.url.startsWith('https://www.youtube.com/')) {
          //   return NavigationDecision.prevent;
          // }
          return NavigationDecision.navigate;
        },
      ),
    );
    controller.loadRequest(Uri.parse(convertToEmbedUrl(link)));
  }

  String convertToEmbedUrl(String url) {
    if (url.contains("playlist?list=")) {
      final playlistId = Uri.parse(url).queryParameters['list'];
      return "https://www.youtube.com/embed/videoseries?list=$playlistId";
    } else if (url.contains("watch?v=")) {
      final videoId = Uri.parse(url).queryParameters['v'];
      return "https://www.youtube.com/embed/$videoId";
    } else {
      return url;
      //throw ArgumentError("Invalid YouTube URL");
    }
  }

  // Widget buildOtherPlatformsYoutubeView() {
  //   return WebViewWidget(controller: controller);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: title.isEmpty ? "Tutorials" : title,
        // subtitle: currentIndex == -1 ? null : tutorials[currentIndex].title,
      ),
      body: link.isEmpty
          ? Container()
          : isAndroidAndIos
              ? buildOtherPlatformsYoutubeView(controller)
              : InAppWebView(
                  initialUrlRequest:
                      URLRequest(url: WebUri(convertToEmbedUrl(link))),

                  // initialOptions: InAppWebViewGroupOptions(
                  //   crossPlatform: InAppWebViewOptions(
                  //     useShouldOverrideUrlLoading: true,
                  //     javaScriptEnabled: true,
                  //   ),
                  // ),
                ),

      //: buildOtherPlatformsYoutubeView(controller),

      // body: link.isEmpty ? Container() : Webview(url: convertToEmbedUrl(link))

      // : Webview(url: kIsWeb ? convertToEmbedUrl(link) : link)
      // body: Column(
      //   children: [
      //     Expanded(
      //       child: controller == null
      //           ? Container(
      //               width: double.infinity,
      //               height: double.infinity,
      //               color: offtint,
      //             )
      //           : WebViewWidget(controller: controller!),
      //     ),
      //     Row(
      //       children: [
      //         Expanded(
      //           child: currentIndex <= 0
      //               ? Container()
      //               : AppButton(title: "Previous", onPressed: playPrev),
      //         ),
      //         Expanded(
      //           child: currentIndex >= tutorials.length - 1
      //               ? Container()
      //               : AppButton(title: "Next", onPressed: playNext),
      //         )
      //       ],
      //     )
      //   ],
      // ),
    );
  }
}
