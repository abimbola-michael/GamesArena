import 'package:gamesarena/custom_paint/shapes_paint.dart';
import 'package:gamesarena/enums/emums.dart';
import 'package:gamesarena/extensions/extensions.dart';
import 'package:gamesarena/models/games/whot.dart';
import 'package:flutter/material.dart';
import '../../styles/colors.dart';
import '../../utils/utils.dart';
import '../blinking_border_container.dart';

Color cardColor = const Color(0xff722f37);

class WhotCard extends StatefulWidget {
  final double height, width;
  final Whot whot;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  final bool isBackCard;
  final bool blink;
  const WhotCard({
    super.key,
    required this.height,
    required this.width,
    required this.whot,
    this.onPressed,
    this.onLongPressed,
    this.isBackCard = false,
    required this.blink,
  });

  @override
  State<WhotCard> createState() => _WhotCardState();
}

class _WhotCardState extends State<WhotCard> {
  double get fontSize => widget.width.percentValue(15);
  double get iconSize => widget.width.percentValue(50);
  double get radiusSize => widget.width.percentValue(10);
  double get paddingSize => widget.width.percentValue(5);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.whot.id,
      child: GestureDetector(
        onTap: widget.onPressed,
        onLongPress: widget.onLongPressed,
        child: BlinkingBorderContainer(
            blink: widget.blink,
            width: widget.width,
            height: widget.height,
            padding: EdgeInsets.all(paddingSize),
            margin: EdgeInsets.all(paddingSize),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radiusSize),
                color: widget.isBackCard ? cardColor : Colors.white,
                border: Border.all(color: cardColor, width: 1)),
            child: widget.isBackCard
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Whot",
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Bookman",
                        ),
                      ),
                      SizedBox(
                        height: paddingSize,
                      ),
                      RotatedBox(
                        quarterTurns: 2,
                        child: Text(
                          "Whot",
                          style: TextStyle(
                            fontSize: fontSize,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Bookman",
                          ),
                        ),
                      )
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                          width: double.infinity,
                          alignment: Alignment.topLeft,
                          child: widget.whot.number == -1
                              ? null
                              : WhotShapeWithText(
                                  whot: widget.whot,
                                  width: widget.width,
                                )),
                      Center(
                          child: getWhotIconWidget(
                              widget.whot,
                              widget.whot.shape == 5 ? fontSize : iconSize,
                              "Whot")),
                      Container(
                          alignment: Alignment.bottomRight,
                          width: double.infinity,
                          child: widget.whot.number == -1
                              ? null
                              : RotatedBox(
                                  quarterTurns: 2,
                                  child: WhotShapeWithText(
                                    whot: widget.whot,
                                    width: widget.width,
                                  ),
                                )),
                    ],
                  )),
      ),
    );
  }
}

class WhotShapeWithText extends StatefulWidget {
  final Whot whot;
  final double width;
  const WhotShapeWithText({super.key, required this.whot, required this.width});

  @override
  State<WhotShapeWithText> createState() => _WhotShapeWithTextState();
}

class _WhotShapeWithTextState extends State<WhotShapeWithText> {
  double get fontSize => widget.width.percentValue(15);
  double get iconSize => widget.width.percentValue(15);
  double get paddingSize => widget.width.percentValue(5);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(paddingSize),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${widget.whot.number}",
            style: TextStyle(fontSize: fontSize, color: cardColor),
          ),
          getWhotIconWidget(widget.whot, iconSize)
        ],
      ),
    );
  }
}

Widget getWhotIconWidget(Whot whot, double size, [String text = "W"]) {
  final shape = whotCardShapes[whot.shape];
  if (shape == WhotCardShape.circle) {
    return Icon(Icons.circle, size: size, color: cardColor);
  }
  if (shape == WhotCardShape.square) {
    return Icon(Icons.square, size: size, color: cardColor);
  }
  if (shape == WhotCardShape.star) {
    return Icon(Icons.star, size: size, color: cardColor);
  }
  if (shape == WhotCardShape.triangle || shape == WhotCardShape.cross) {
    //
    return CustomPaint(
      size:
          Size(size - (size.percentValue(30)), size - (size.percentValue(30))),
      painter: ShapesPainter(color: cardColor, thickness: 1, cardShape: shape),
    );
  }

  if (shape == WhotCardShape.whot) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: cardColor,
            fontFamily: "Bookman",
          ),
        ),
        if (text == "Whot") ...[
          RotatedBox(
            quarterTurns: 2,
            child: Text(
              text,
              style: TextStyle(
                fontFamily: "Bookman",
                fontSize: size,
                fontWeight: FontWeight.bold,
                color: cardColor,
              ),
            ),
          ),
        ]
      ],
    );
  }

  return Container();
}

// IconData getWhotIcon(Whot whot) {
//   if (whot.shape == WhotCardShape.circle) return Icons.circle;
//   if (whot.shape == WhotCardShape.triangle) return Icons.train;
//   if (whot.shape == WhotCardShape.cross) return Icons.plus_one;
//   if (whot.shape == WhotCardShape.square) return Icons.square;
//   if (whot.shape == WhotCardShape.star) return Icons.star;
//   return Icons.nat;
// }
class WhotCountWidget extends StatelessWidget {
  final int count;
  final Color? color, textColor;
  const WhotCountWidget(
      {super.key, required this.count, this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: CircleAvatar(
        radius: 10,
        backgroundColor: color ?? (darkMode ? lightestWhite : lightestBlack),
        child: Text(
          "$count",
          style: TextStyle(
              fontSize: 10, color: textColor ?? (darkMode ? white : black)),
        ),
      ),
    );
  }
}
