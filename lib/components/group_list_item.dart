import 'package:gamesarena/extensions/extensions.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../styles/colors.dart';
import '../utils/utils.dart';

class GroupListItem extends StatefulWidget {
  final Group group;
  const GroupListItem({super.key, required this.group});

  @override
  State<GroupListItem> createState() => _GroupListItemState();
}

class _GroupListItemState extends State<GroupListItem> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              backgroundColor: darkMode ? lightestWhite : lightestBlack,
              radius: 30,
              child: Text(
                widget.group.groupname.firstChar ?? "",
                style: const TextStyle(fontSize: 30, color: Colors.blue),
              ),
            ),
          ],
        ),
        const SizedBox(
          width: 4,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.group.groupname,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              widget.group.groupname,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}
