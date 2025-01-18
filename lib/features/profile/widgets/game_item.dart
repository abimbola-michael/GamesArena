import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

class GameItem extends StatelessWidget {
  final String game;
  final List<String> selectedGames;
  final void Function(bool?)? onChanged;
  const GameItem(
      {super.key,
      required this.game,
      required this.selectedGames,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile.adaptive(
        title: Text(game, style: context.bodyMedium),
        value: selectedGames.contains(game),
        onChanged: onChanged);
  }
}
