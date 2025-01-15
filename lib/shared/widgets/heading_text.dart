import 'package:flutter/cupertino.dart';

class HeadingText extends StatelessWidget {
  final String text;
  final bool isLarge;
  const HeadingText(this.text, {super.key, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
              fontSize: isLarge ? 20 : 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
