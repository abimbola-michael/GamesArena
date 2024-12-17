import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gamesarena/features/game/models/player.dart';
import 'package:gamesarena/features/records/utils/utils.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/theme/colors.dart';

import '../../game/widgets/profile_photo.dart';

class PlayerItem extends StatelessWidget {
  final Player player;
  final VoidCallback onPressed;
  const PlayerItem({super.key, required this.player, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final user = player.user;
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        child: Row(
          children: [
            ProfilePhoto(
              profilePhoto: user?.profile_photo,
              name: user?.username ?? "",
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user?.username ?? "",
                          style: context.bodyMedium,
                        ),
                      ),
                      if (player.role != null && player.role != "participant")
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            player.role!,
                            style: context.bodySmall
                                ?.copyWith(color: primaryColor),
                          ),
                        )
                    ],
                  ),
                  Text(
                    user?.user_games != null
                        ? getUserGamesString(user!.user_games)
                        : "Any game",
                    style: context.bodySmall?.copyWith(color: lighterTint),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
