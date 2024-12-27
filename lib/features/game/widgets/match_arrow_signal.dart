import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../../../shared/utils/utils.dart';
import '../../game/models/match.dart';

class MatchArrowSignal extends StatelessWidget {
  final Match match;
  const MatchArrowSignal({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 15,
      width: 15,
      decoration: BoxDecoration(
        // color: primaryColor,
        shape: BoxShape.circle,
        // border: Border.all(color: white),
        //match.creator_id != myId &&
        color: (match.time_start == "" || match.time_start == null)
            ? Colors.red
            : Colors.blue,
      ),
      child: Transform.rotate(
        angle: 45,
        child: Icon(
          match.creator_id == myId ? Icons.arrow_upward : Icons.arrow_downward,
          color: Colors.white,
          size: 15,
        ),
      ),
    );
  }
}
