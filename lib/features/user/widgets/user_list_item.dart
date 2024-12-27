import 'package:gamesarena/features/game/widgets/profile_photo.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/models.dart';

class UserListItem extends StatefulWidget {
  final User user;
  final VoidCallback onPressed;
  const UserListItem({
    super.key,
    required this.user,
    required this.onPressed,
  });

  @override
  State<UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<UserListItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: widget.onPressed,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        widget.user.username,
        style: const TextStyle(fontSize: 16),
      ),
      leading: Stack(
        children: [
          ProfilePhoto(
              profilePhoto: widget.user.profile_photo,
              name: widget.user.username),
          if (widget.user.checked) ...[
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
    );
  }
}
