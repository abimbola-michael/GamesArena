import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

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
          text: TextSpan(
              text: "",
              style: TextStyle(
                  fontSize: 16,
                  color: context.isDarkMode ? Colors.white : Colors.black),
              children: [
            if (prefix.isNotEmpty)
              TextSpan(
                  text: "$prefix ",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  )),
            if (title.isNotEmpty)
              TextSpan(
                  text: "$title: ",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  )),
            TextSpan(
                text: text,
                style: const TextStyle(
                  fontSize: 16,
                ))
          ])),
    );
    // return Container(
    //   width: double.infinity,
    //   padding: const EdgeInsets.symmetric(vertical: 4.0),
    //   child: Row(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       if (prefix.isNotEmpty)
    //         Padding(
    //           padding: const EdgeInsets.only(right: 8.0),
    //           child: Text(
    //             "$prefix ",
    //             style: const TextStyle(
    //               fontSize: 18,
    //               fontWeight: FontWeight.bold,
    //             ),
    //           ),
    //         ),
    //       if (title.isNotEmpty)
    //         Padding(
    //           padding: const EdgeInsets.only(right: 8.0),
    //           child: Text(
    //             "$title: ",
    //             style: const TextStyle(
    //               fontSize: 18,
    //               fontWeight: FontWeight.bold,
    //             ),
    //           ),
    //         ),
    //       Text(
    //         text,
    //         style: const TextStyle(
    //           fontSize: 18,
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }
}
