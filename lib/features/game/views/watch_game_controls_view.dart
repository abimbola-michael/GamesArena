import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/utils/utils.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../shared/models/models.dart';

class WatchGameControlsView extends StatefulWidget {
  final StreamController<double> watchTimerController;
  final int playersSize;
  final List<User?>? users;
  final List<Player>? players;
  final bool watching;
  final bool showWatchControls;
  final bool loadingDetails;
  final bool finishedRound;
  final double duration;
  final double endDuration;

  final VoidCallback onPressed;

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onRewind;
  final VoidCallback onForward;
  final VoidCallback onPlayPause;
  final void Function(double duration) onSeek;

  const WatchGameControlsView(
      {super.key,
      required this.watchTimerController,
      required this.playersSize,
      required this.duration,
      required this.endDuration,
      required this.onPressed,
      required this.onPrevious,
      required this.onNext,
      required this.onRewind,
      required this.onForward,
      required this.onPlayPause,
      required this.onSeek,
      required this.watching,
      required this.showWatchControls,
      required this.loadingDetails,
      required this.finishedRound,
      this.users,
      this.players});

  @override
  State<WatchGameControlsView> createState() => _WatchGameControlsViewState();
}

class _WatchGameControlsViewState extends State<WatchGameControlsView>
// with SingleTickerProviderStateMixin
{
  bool isRemaining = false;
  //late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    // animationController =
    //     AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    // animationController.dispose();
    super.dispose();
  }

  // void startAnimation() {

  //   animationController.forward(from: 0);
  // }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: !widget.showWatchControls
            ? Colors.transparent
            : Colors.black.withOpacity(0.5),
        child: !widget.showWatchControls
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 50,
                    child: Text(
                      getPlayersNames(widget.players ?? [],
                              users: widget.users,
                              playersSize: widget.playersSize)
                          .join(" vs "),
                      style: context.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: widget.onRewind,
                        icon: const Icon(EvaIcons.rewind_left_outline),
                        iconSize: 30,
                        color: Colors.white,
                      ),
                      IconButton(
                        onPressed: widget.onPrevious,
                        icon: const Icon(EvaIcons.arrow_left_outline),
                        iconSize: 30,
                        color: Colors.white,
                      ),
                      IconButton(
                        onPressed: widget.onPlayPause,
                        icon: Icon(widget.watching
                            ? EvaIcons.pause_circle_outline
                            : EvaIcons.play_circle_outline),
                        iconSize: 50,
                        color: Colors.white,
                      ),
                      IconButton(
                        onPressed: widget.onNext,
                        icon: const Icon(EvaIcons.arrow_right_outline),
                        iconSize: 30,
                        color: Colors.white,
                      ),
                      IconButton(
                        onPressed: widget.onForward,
                        icon: const Icon(EvaIcons.rewind_right_outline),
                        iconSize: 30,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  StreamBuilder<double>(
                      stream: widget.watchTimerController.stream,
                      builder: (context, snapshot) {
                        final duration = snapshot.data ?? widget.duration;
                        // startAnimation();
                        // return AnimatedBuilder(
                        //     animation: animationController,
                        //     builder: (context, child) {
                        //       final value = animationController.value;
                        //       final duration = durationValue + value;

                        return Padding(
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, bottom: 30),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                child: Text(
                                  duration.toInt().toDurationString(true),
                                  style: context.bodySmall
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                    value: duration < 0
                                        ? 0
                                        : duration > widget.endDuration
                                            ? widget.endDuration
                                            : duration,
                                    min: 0,
                                    max: widget.endDuration,
                                    onChanged: (pos) => widget.onSeek(pos)),
                              ),
                              SizedBox(
                                width: 40,
                                child: GestureDetector(
                                  onTap: () {
                                    isRemaining = !isRemaining;
                                    setState(() {});
                                  },
                                  child: Text(
                                    !widget.finishedRound
                                        ? "Live"
                                        : (isRemaining
                                                ? widget.endDuration - duration
                                                : widget.endDuration)
                                            .toInt()
                                            .toDurationString(true),
                                    style: context.bodySmall?.copyWith(
                                        color: !widget.finishedRound
                                            ? Colors.red
                                            : Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        // });
                      })
                ],
              ),
      ),
    );
  }
}
