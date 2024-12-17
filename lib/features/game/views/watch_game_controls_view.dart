import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/utils/utils.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../shared/models/models.dart';

class WatchGameControlsView extends StatefulWidget {
  final StreamController<int> watchTimerController;
  final int playersSize;
  final List<User?>? users;
  final List<Player>? players;
  final bool watching;
  final bool showWatchControls;
  final bool loadingDetails;
  final int timeStart;
  final int watchTime;
  final int? timeEnd;
  final int duration;

  final VoidCallback onPressed;

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onRewind;
  final VoidCallback onForward;
  final VoidCallback onPlayPause;
  final void Function(int watchTime) onSeek;

  const WatchGameControlsView(
      {super.key,
      required this.watchTimerController,
      required this.playersSize,
      required this.watchTime,
      required this.timeStart,
      required this.timeEnd,
      required this.duration,
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
      this.users,
      this.players});

  @override
  State<WatchGameControlsView> createState() => _WatchGameControlsViewState();
}

class _WatchGameControlsViewState extends State<WatchGameControlsView> {
  bool isRemaining = false;

  // int get gameDuration => widget.timeEnd != null
  //     ? widget.timeEnd! - widget.timeStart
  //     : widget.duration;
  double get end =>
      widget.timeEnd?.toDouble() ??
      (widget.timeStart + widget.duration).toDouble();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

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
                  StreamBuilder<int>(
                      stream: widget.watchTimerController.stream,
                      builder: (context, snapshot) {
                        final watchTime = snapshot.data ?? widget.watchTime;
                        return SizedBox(
                          height: 50,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    ((watchTime - widget.timeStart) ~/ 1000)
                                        .toDurationString(),
                                    style: context.bodySmall
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                      value: watchTime < widget.timeStart
                                          ? widget.timeStart.toDouble()
                                          : watchTime > end
                                              ? end
                                              : watchTime.toDouble(),
                                      min: widget.timeStart.toDouble(),
                                      max: end,
                                      onChanged: (pos) =>
                                          widget.onSeek(pos.toInt())),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: GestureDetector(
                                    onTap: widget.timeEnd == null
                                        ? null
                                        : () {
                                            isRemaining = !isRemaining;
                                            setState(() {});
                                          },
                                    child: Text(
                                      widget.timeEnd == null
                                          ? "Live"
                                          : isRemaining
                                              ? ((widget.timeEnd! -
                                                          watchTime) ~/
                                                      1000)
                                                  .toDurationString()
                                              : ((widget.timeEnd! -
                                                          widget.timeStart) ~/
                                                      1000)
                                                  .toDurationString(),
                                      style: context.bodySmall?.copyWith(
                                          color: widget.timeEnd == null
                                              ? Colors.red
                                              : Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                ],
              ),
      ),
    );
  }
}
