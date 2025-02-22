import 'package:gamesarena/features/games/card/whot/widgets/whot_shapes_paint.dart';
import 'package:gamesarena/enums/emums.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/games/card/whot/models/whot.dart';
import 'package:flutter/material.dart';
import '../../../../../theme/colors.dart';
import '../../../../../shared/utils/utils.dart';
import '../../../../../shared/widgets/blinking_border_container.dart';
import '../pages/whot_game_page.dart';

Color cardColor = const Color(0xff722f37);

class WhotCard extends StatelessWidget {
  final double height, width;
  final Whot whot;
  final int? count;
  final VoidCallback? onPressed;
  final VoidCallback? onDoubleTap;

  final VoidCallback? onLongPressed;
  final bool isBackCard;
  final bool blink;
  final bool highlight;

  final double? margin;
  const WhotCard({
    super.key,
    required this.height,
    required this.width,
    required this.whot,
    this.count,
    this.onPressed,
    this.onDoubleTap,
    this.onLongPressed,
    this.isBackCard = false,
    required this.blink,
    required this.highlight,
    this.margin,
  });

  double get fontSize => width.percentValue(15);

  double get iconSize => width.percentValue(50);

  double get radiusSize => width.percentValue(10);

  double get paddingSize => width.percentValue(5);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      onLongPress: onLongPressed,
      onDoubleTap: onDoubleTap,
      child: BlinkingBorderContainer(
          blink: blink,
          width: width,
          height: height,
          // padding: EdgeInsets.all(paddingSize),
          // margin: EdgeInsets.all(widget.margin ?? paddingSize),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radiusSize),
              color: isBackCard ? cardColor : Colors.white,
              border: Border.all(
                  color: highlight ? gameHintColor : cardColor,
                  width: highlight ? 3 : 1)),
          child: Stack(
            children: [
              isBackCard
                  ? Center(
                      child: Column(
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
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                            width: double.infinity,
                            alignment: Alignment.topLeft,
                            child: whot.number == -1
                                ? null
                                : WhotShapeWithText(
                                    whot: whot,
                                    width: width,
                                  )),
                        Center(
                            child: getWhotIconWidget(whot,
                                whot.shape == 5 ? fontSize : iconSize, "Whot")),
                        Container(
                            alignment: Alignment.bottomRight,
                            width: double.infinity,
                            child: whot.number == -1
                                ? null
                                : RotatedBox(
                                    quarterTurns: 2,
                                    child: WhotShapeWithText(
                                      whot: whot,
                                      width: width,
                                    ),
                                  )),
                      ],
                    ),
              if (count != null) ...[
                Positioned(
                  top: width.percentValue(5),
                  right: width.percentValue(5),
                  child: CountWidget(
                    count: count!,
                    size: width.percentValue(20),
                    color: isBackCard
                        ? Colors.white.withOpacity(0.1)
                        : cardColor.withOpacity(0.1),
                    textColor: isBackCard ? Colors.white : cardColor,
                  ),
                ),
              ]
            ],
          )),
    );
  }
}

class WhotShapeWithText extends StatelessWidget {
  final Whot whot;
  final double width;
  const WhotShapeWithText({super.key, required this.whot, required this.width});

  double get fontSize => width.percentValue(15);

  double get iconSize => width.percentValue(15);

  double get paddingSize => width.percentValue(5);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(paddingSize),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${whot.number}",
            style: TextStyle(fontSize: fontSize, color: cardColor),
          ),
          getWhotIconWidget(whot, iconSize)
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
class CountWidget extends StatelessWidget {
  final int count;
  final Color? color, textColor;
  final double? size;
  const CountWidget(
      {super.key, required this.count, this.color, this.textColor, this.size});

  @override
  Widget build(BuildContext context) {
    double countSize = size != null ? (size! / 2) : 10;
    return CircleAvatar(
      radius: countSize,
      backgroundColor: color ?? (darkMode ? lightestWhite : lightestBlack),
      child: Text(
        "$count",
        style: TextStyle(
            fontSize: countSize,
            color: textColor ?? (darkMode ? white : black)),
      ),
    );
  }
}
