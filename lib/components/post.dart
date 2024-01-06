import 'package:flutter/material.dart';
import '../utils/utils.dart';

class Post extends StatelessWidget {
  final int width, height;
  final bool down;
  const Post(
      {super.key,
      required this.height,
      required this.width,
      this.down = false});

  @override
  Widget build(BuildContext context) {
    BorderSide borderSide = BorderSide(
        width: 5,
        color: darkMode ? Colors.white : Colors.black,
        style: BorderStyle.solid);
    return Container(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      height: height.toDouble(),
      width: width.toDouble(),
      decoration: BoxDecoration(
          color: Colors.transparent,
          // borderRadius: BorderRadius.only(
          //     topLeft: Radius.circular(10), topRight: Radius.circular(10)),
          // border: Border.all(  width: 5, color: darkMode ? Colors.white : Colors.black)
          border: Border(
            left: borderSide,
            right: borderSide,
            /*top: down ? BorderSide.none : borderSide,
            bottom: !down ? BorderSide.none : borderSide,*/
          )),
    );
  }
}
