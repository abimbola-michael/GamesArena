// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/features/game/widgets/profile_photo.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/theme/colors.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../shared/utils/utils.dart';
import '../../profile/pages/profile_page.dart';
import '../../user/models/user.dart';

class MatchOrRecordPlayerScoreItem extends StatelessWidget {
  final List<User> users;
  final String playerId;
  final int score;
  final List<String>? winners;
  final String message;
  const MatchOrRecordPlayerScoreItem(
      {super.key,
      required this.users,
      required this.playerId,
      required this.score,
      required this.winners,
      this.message = ""});

  @override
  Widget build(BuildContext context) {
    final user = users.firstWhereNullable((user) => user.user_id == playerId);
    final name = user?.username ?? "Player $playerId";
    final profilePhoto = user?.profile_photo;
    final win = winners?.contains(playerId) ?? false;

    void gotoProfilePage() {
      context.pushTo(ProfilePage(id: playerId));
    }

    return InkWell(
      onTap: gotoProfilePage,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ProfilePhoto(
              profilePhoto: profilePhoto,
              name: name,
              size: 35,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: context.bodyMedium,
                  ),
                  if (message.isNotEmpty) ...[
                    // const SizedBox(height: 2),
                    Text(
                      message,
                      style: context.bodySmall?.copyWith(color: lighterTint),
                    ),
                  ]
                ],
              ),
            ),
            if (win) ...[
              const SizedBox(width: 4),
              const Icon(
                EvaIcons.checkmark_circle,
                color: primaryColor,
                size: 14,
              )
            ],
            if (score != -1) ...[
              const SizedBox(width: 10),
              Text(
                "$score",
                style:
                    context.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
