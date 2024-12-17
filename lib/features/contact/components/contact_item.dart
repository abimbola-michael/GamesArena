import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_container.dart';
import '../../../theme/colors.dart';
import '../../game/widgets/profile_photo.dart';
import '../../user/models/user.dart';
import '../enums.dart';

class ContactItem extends StatelessWidget {
  final User user;
  final bool? selected;
  final VoidCallback onPressed;
  final List<String> availablePlatforms;
  final void Function(String platform)? onShare;
  final ContactStatus? contactStatus;
  final bool isInvite;

  const ContactItem(
      {super.key,
      required this.user,
      this.selected,
      required this.onPressed,
      required this.onShare,
      this.contactStatus,
      this.availablePlatforms = const [],
      this.isInvite = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (user.email.isEmpty) {
          return;
        } else {
          onPressed();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Stack(
              children: [
                ProfilePhoto(
                    profilePhoto: user.profile_photo,
                    name: user.phoneName ?? user.username),
                if (selected != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: AppContainer(
                      isCircular: true,
                      height: 24,
                      width: 24,
                      color: selected! ? primaryColor : tint,
                      borderColor: selected! ? primaryColor : tint,
                      child: selected!
                          ? const Icon(
                              EvaIcons.checkmark,
                              size: 16,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(
              width: 6,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.phoneName ?? user.username,
                    style: context.bodyMedium?.copyWith(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.username.isNotEmpty ? user.username : user.phone,
                    style: context.bodyMedium?.copyWith(color: lighterTint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // if (user.email.isNotEmpty)
                  //   Text(
                  //     getUserBio(user),
                  //     style: context.bodyMedium?.copyWith(color: lighterTint),
                  //     maxLines: 1,
                  //     overflow: TextOverflow.ellipsis,
                  //   ),
                ],
              ),
            ),
            const SizedBox(
              width: 6,
            ),
            if (contactStatus == ContactStatus.requested || isInvite)
              if (availablePlatforms.contains("WhatsApp"))
                PopupMenuButton<String>(
                  itemBuilder: (context) {
                    return availablePlatforms.map((option) {
                      return PopupMenuItem(
                        value: option,
                        child: Text(
                          option,
                          style: context.bodySmall,
                        ),
                      );
                    }).toList();
                  },
                  onSelected: onShare,
                  child: const AppButton(title: "Invite", wrapped: true),
                )
              else
                AppButton(title: "Invite", wrapped: true, onPressed: onPressed)
            else if (contactStatus == ContactStatus.unadded)
              AppButton(
                title: "Add",
                wrapped: true,
                onPressed: onPressed,
              )
            else if (contactStatus == null)
              PopupMenuButton<String>(
                itemBuilder: (context) {
                  return availablePlatforms.map((option) {
                    return PopupMenuItem(
                      value: option,
                      child: Text(
                        option,
                        style: context.bodySmall,
                      ),
                    );
                  }).toList();
                },
                onSelected: onShare,
                child: const Icon(EvaIcons.share_outline, color: white),
              )
          ],
        ),
      ),
    );
  }
}
