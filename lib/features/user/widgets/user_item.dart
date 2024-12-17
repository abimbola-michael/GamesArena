import 'package:cached_network_image/cached_network_image.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';

import '../../../shared/services.dart';
import '../../../shared/models/models.dart';
import '../../../theme/colors.dart';
import '../../../shared/utils/utils.dart';
import '../../game/widgets/profile_photo.dart';

class UserItem extends StatelessWidget {
  final User? user;
  final String type;
  final VoidCallback onPressed;

  const UserItem(
      {super.key,
      required this.user,
      required this.type,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ProfilePhoto(
                  profilePhoto: user?.profile_photo,
                  name: user?.username ?? ""),
              if (user?.checked ?? false) ...[
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onPressed,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        type == "select" &&
                                user != null &&
                                user!.user_id != myId
                            ? Icons.close
                            : Icons.check,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              ],
            ],
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            user?.username ?? "",
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
