import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/features/user/models/user_game.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../../theme/colors.dart';
import '../constants.dart';

class UserGameItem extends StatelessWidget {
  final UserGame userGame;
  final ValueChanged<String?>? onChanged;
  const UserGameItem(
      {super.key, required this.userGame, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(userGame.name, style: context.bodyMedium)),
              Text(
                userGame.ability,
                style: context.bodySmall?.copyWith(color: lightTint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(gameAbilities.length, (index) {
              final ability = gameAbilities[index];
              return Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: InkWell(
                    onTap: onChanged == null ? null : () => onChanged!(ability),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: userGame.ability == ability
                            ? primaryColor.withOpacity(0.5)
                            : transparent,
                      ),
                      child: Text(
                        ability,
                        style: context.bodySmall?.copyWith(color: lightTint),
                      ),
                    ),
                  ),
                  // child: Row(
                  //   mainAxisAlignment: MainAxisAlignment.start,
                  //   children: [
                  //     Radio<String?>(
                  //         value: ability,
                  //         groupValue: userGame.ability,
                  //         onChanged: onChanged),
                  //     Flexible(
                  //       child: Text(
                  //         ability,
                  //         style: context.bodySmall?.copyWith(color: lightTint),
                  //       ),
                  //     )
                  //   ],
                  // ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }
}
