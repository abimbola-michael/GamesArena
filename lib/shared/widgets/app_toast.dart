import 'dart:async';
import 'package:flutter/material.dart';

class AppToast extends StatefulWidget {
  final String message;
  final int duration;
  final VoidCallback onComplete;
  const AppToast(
      {super.key,
      required this.message,
      required this.onComplete,
      this.duration = 3});

  @override
  State<AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<AppToast>
    with SingleTickerProviderStateMixin {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(seconds: 2), () {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return timer == null || !timer!.isActive
        ? Container()
        : Container(
            decoration: BoxDecoration(
                color: Colors.black, borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            margin: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              widget.message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          );
  }
}
