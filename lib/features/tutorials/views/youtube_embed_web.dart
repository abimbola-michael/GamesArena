// import 'dart:html';
// import 'dart:ui_web' as ui;

// import 'package:flutter/material.dart'; // For HtmlElementView (Web)

// Widget buildWebYouTubeView(String videoUrl) {
//   // Register an HTML iframe
//   final iframeId = 'youtube-iframe-${UniqueKey()}';
//   ui.platformViewRegistry.registerViewFactory(iframeId, (int viewId) {
//     final iframe = IFrameElement();
//     iframe.src = videoUrl; // Embed link
//     iframe.style.border = 'none';
//     iframe.allow =
//         "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture";
//     iframe.allowFullscreen = true;
//     return iframe;
//   });

//   return HtmlElementView(viewType: iframeId);
// }
