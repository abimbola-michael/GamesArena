import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';

import '../../../shared/services.dart';
import '../../../shared/models/models.dart';
import '../../../theme/colors.dart';
import '../../../shared/utils/utils.dart';

class UserItem extends StatefulWidget {
  final User? user;
  final String type;
  final VoidCallback onPressed;

  const UserItem(
      {super.key,
      required this.user,
      required this.type,
      required this.onPressed});

  @override
  State<UserItem> createState() => _UserItemState();
}

class _UserItemState extends State<UserItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              CircleAvatar(
                backgroundColor: darkMode ? lightestWhite : lightestBlack,
                radius: 30,
                child: Text(
                  widget.user?.username.firstChar ?? "",
                  style: const TextStyle(fontSize: 30, color: Colors.blue),
                ),
              ),
              if (widget.user?.checked ?? false) ...[
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: widget.onPressed,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        widget.type == "select" &&
                                widget.user != null &&
                                widget.user!.user_id != myId
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
            widget.user?.username ?? "",
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
