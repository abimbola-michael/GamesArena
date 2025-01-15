import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gamesarena/features/game/models/player.dart';
import 'package:gamesarena/features/records/utils/utils.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/theme/colors.dart';

import '../../game/widgets/profile_photo.dart';
import '../../user/models/user.dart';

class PlayerItem extends StatelessWidget {
  final Player? player;
  final User? user;
  final VoidCallback onPressed;
  const PlayerItem(
      {super.key, this.player, this.user, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final user = player?.user ?? this.user;
    final games = user?.games != null ? getGamesString(user!.games) : "";
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                children: [
                  ProfilePhoto(
                      profilePhoto: user?.profile_photo,
                      name: user?.username ?? ""),
                  if (user?.checked != null && user!.checked!) ...[
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.check,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ]
                ],
              ),
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
                      if (player?.role != null && player?.role != "participant")
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            player!.role!,
                            style: context.bodySmall
                                ?.copyWith(color: primaryColor),
                          ),
                        )
                    ],
                  ),
                  if (games.isNotEmpty)
                    Text(
                      games,
                      style: context.bodySmall?.copyWith(color: lighterTint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
