import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/models.dart';
import '../../../theme/colors.dart';
import '../../../shared/utils/utils.dart';

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
          CircleAvatar(
            backgroundColor: darkMode ? lightestWhite : lightestBlack,
            radius: 30,
            child: Text(
              widget.user.username.firstChar ?? "",
              style: const TextStyle(fontSize: 30, color: Colors.blue),
            ),
          ),
          if (widget.user.checked) ...[
            const Positioned(
              bottom: 4,
              right: 4,
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
