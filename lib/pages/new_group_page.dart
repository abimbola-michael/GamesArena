import 'package:gamesarena/blocs/firebase_service.dart';
import 'package:gamesarena/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../components/components.dart';
import '../models/models.dart';
import '../styles/styles.dart';
import '../utils/utils.dart';

class NewGroupPage extends StatefulWidget {
  final List<User> users;
  const NewGroupPage({super.key, required this.users});

  @override
  State<NewGroupPage> createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {
  TextEditingController controller = TextEditingController();
  FirebaseService fs = FirebaseService();
  List<User> users = [];
  String gameId = "", myId = "";
  bool creating = false;
  @override
  void initState() {
    super.initState();
    myId = fs.myId;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: SizedBox(
              height: 50,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: darkMode ? lightWhite : lightBlack)),
                    hintText: "Enter groupname"),
              ),
            ),
          ),
          Text(
            "${users.length} Players",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4),
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return UserItem(
                  user: user,
                  type: "",
                  onPressed: () {},
                );
              }),
        ],
      ),
      bottomNavigationBar: ActionButton("Create Group", onPressed: () {
        createGroup();
      }, height: 50),
    ));
  }

  void createGroup() async {
    if (creating) return;
    final groupname = controller.text;
    final groupId = fs.getId(["groups"]);
    if (groupname != "") {
      final group =
          Group(group_id: groupId, groupname: groupname, creator_id: myId);
      setState(() {
        creating = true;
      });
      await fs.creatGroup(group, users.map((e) => e.user_id).toList());
      //await fs.createGame(group_id, users.map((e) => e.user_id).toList());
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(msg: "Groupname is required");
    }
  }

  void searchUser() async {
    String value = controller.text;
    String type = "";
    if (value.isValidEmail()) {
      type = "email";
    } else if (value.isOnlyNumber()) {
      type = "phone";
    } else {
      type = "username";
    }
    final user = await fs.searchUser(type, value);
  }
}
