import 'package:flutter/cupertino.dart';

class HeadingText extends StatelessWidget {
  final String text;
  final bool isLarge;
  const HeadingText(this.text, {super.key, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isLarge ? 30 : 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
