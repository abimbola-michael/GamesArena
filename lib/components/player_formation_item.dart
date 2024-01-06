import 'package:gamesarena/components/components.dart';
import 'package:gamesarena/models/models.dart';
import 'package:flutter/material.dart';

class PlayersFormationItem extends StatelessWidget {
  final PlayersFormation playersFormation;
  const PlayersFormationItem({super.key, required this.playersFormation});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (playersFormation.user1 != null) ...[
            UserItem(user: playersFormation.user1, type: "", onPressed: () {})
          ],
          if (playersFormation.user2 != null) ...[
            UserItem(user: playersFormation.user2, type: "", onPressed: () {})
          ],
          if (playersFormation.user3 != null) ...[
            UserItem(user: playersFormation.user3, type: "", onPressed: () {})
          ],
          if (playersFormation.user4 != null) ...[
            UserItem(user: playersFormation.user4, type: "", onPressed: () {})
          ],
        ],
      ),
    );
  }
  // @override
  // Widget build(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.all(8.0),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Text(
  //           playersFormation.user1?.username ?? "",
  //           textAlign: TextAlign.center,
  //           style: TextStyle(color: tintColor, fontSize: 18),
  //         ),
  //         const SizedBox(width: 8),
  //         CircleAvatar(
  //           radius: 20,
  //           child: Text(
  //             playersFormation.user1?.username.firstChar ?? "",
  //             style: const TextStyle(fontSize: 20, color: Colors.blue),
  //           ),
  //         ),
  //         if (playersFormation.player1Score != null) ...[
  //           const SizedBox(width: 8),
  //           Text(
  //             "${playersFormation.player1Score}",
  //             textAlign: TextAlign.center,
  //             style: TextStyle(
  //                 color: tintColor, fontSize: 20, fontWeight: FontWeight.bold),
  //           ),
  //         ],
  //         if (playersFormation.user2 != null) ...[
  //           if (playersFormation.player2Score != null) ...[
  //             const SizedBox(width: 8),
  //             Text(
  //               "${playersFormation.player2Score}",
  //               textAlign: TextAlign.center,
  //               style: TextStyle(
  //                   color: tintColor,
  //                   fontSize: 20,
  //                   fontWeight: FontWeight.bold),
  //             ),
  //           ],
  //           const SizedBox(width: 16),
  //           Text(
  //             "v",
  //             textAlign: TextAlign.center,
  //             style: TextStyle(color: tintColor),
  //           ),
  //           const SizedBox(width: 16),
  //           CircleAvatar(
  //             radius: 20,
  //             child: Text(
  //               playersFormation.user2?.username.firstChar ?? "",
  //               style: const TextStyle(fontSize: 20, color: Colors.blue),
  //             ),
  //           ),
  //           const SizedBox(width: 8),
  //           Text(
  //             playersFormation.user2?.username ?? "",
  //             textAlign: TextAlign.center,
  //             style: TextStyle(color: tintColor, fontSize: 18),
  //           ),
  //         ]
  //       ],
  //     ),
  //   );
  // }
}
