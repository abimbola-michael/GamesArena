// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gamesarena/extensions/extensions.dart';

class Dice extends StatelessWidget {
  final int value;
  final int size;
  const Dice({super.key, required this.value, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(size.toDouble().percentValue(5))),
        width: size.toDouble(),
        height: size.toDouble(),
        alignment: Alignment.center,
        child: value == 1
            ? dot()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: getDots(value == 3 ? 3 : 2),
                  ),
                  if (value > 4) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: getDots(value == 5 ? 1 : 2),
                    ),
                  ],
                  if (value > 3) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: getDots(2),
                    ),
                  ]
                ],
              ));
  }

  Widget dot() {
    return Padding(
      padding: EdgeInsets.all(size.toDouble().percentValue(5)),
      child: CircleAvatar(
        radius: size.toDouble().percentValue(10),
        backgroundColor: Colors.black,
      ),
    );
  }

  List<Widget> getDots(int value) {
    return List.generate(value, (index) => dot());
  }
}

class RollingDice extends StatefulWidget {
  final void Function(int dice1, int dice2) onUpdate, onComplete;
  final int size;
  const RollingDice({
    super.key,
    required this.onUpdate,
    required this.onComplete,
    required this.size,
  });

  @override
  State<RollingDice> createState() => _RollingDiceState();
}

class _RollingDiceState extends State<RollingDice>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int dice1 = 1, dice2 = 1;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    getDiceValues();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        setState(() {
          getDiceValues();
        });
      });

    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete(dice1, dice2);
        _animationController.reset();
      }
    });
    _rollDice();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void getDiceValues() {
    dice1 = _random.nextInt(6) + 1;
    dice2 = _random.nextInt(6) + 1;
    widget.onUpdate(dice1, dice2);
  }

  void _rollDice() {
    if (_animationController.isAnimating) {
      return;
    }
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animation.value * pi * 2,
              child: Dice(value: dice1, size: widget.size),
            );
          },
        ),
        const SizedBox(
          width: 8,
        ),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animation.value * pi * 2,
              child: Dice(value: 2, size: widget.size),
            );
          },
        ),
      ],
    );
  }
}
