// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/features/game/widgets/profile_photo.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/theme/colors.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../user/models/user.dart';

class MatchOrRecordPlayerScoreItem extends StatelessWidget {
  final List<User> users;
  final String playerId;
  final int score;
  final List<String>? winners;
  const MatchOrRecordPlayerScoreItem({
    super.key,
    required this.users,
    required this.playerId,
    required this.score,
    required this.winners,
  });

  @override
  Widget build(BuildContext context) {
    final user = users.firstWhereNullable((user) => user.user_id == playerId);
    final name = user?.username ?? "Player $playerId";
    final profilePhoto = user?.profile_photo;
    final win = winners?.contains(playerId) ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ProfilePhoto(
            profilePhoto: profilePhoto,
            name: name,
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: context.bodyMedium,
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
          const SizedBox(width: 10),
          Text(
            "$score",
            style: context.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
