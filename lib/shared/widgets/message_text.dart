import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../theme/colors.dart';

class MessageText extends StatelessWidget {
  final String text;
  final String prefix;
  final String title;
  const MessageText(this.text, {super.key, this.prefix = '', this.title = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
          text: TextSpan(text: "", style: context.bodyMedium, children: [
        if (prefix.isNotEmpty)
          TextSpan(
              text: "$prefix ",
              style: TextStyle(fontWeight: FontWeight.bold, color: tint)),
        if (title.isNotEmpty)
          TextSpan(
              text: "$title: ",
              style: TextStyle(fontWeight: FontWeight.bold, color: tint)),
        TextSpan(text: text, style: TextStyle(fontSize: 14, color: tint))
      ])),
    );
  }
}
