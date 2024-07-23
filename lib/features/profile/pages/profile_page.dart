import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/onboarding/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../core/firebase/firebase_methods.dart';
import '../../../shared/services.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../theme/colors.dart';
import '../../../shared/utils/utils.dart';
import '../../group/services.dart';
import '../../user/services.dart';

class ProfilePage extends StatefulWidget {
  final String id;
  final String type;
  const ProfilePage({super.key, required this.id, required this.type});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "", email = "", phone = "";
  String type = "", id = "", myId = "";
  FirebaseMethods fm = FirebaseMethods();
  List<String> options = ["Username", "Email", "Phone", "Password"];
  BuildContext? bottomSheetContext;

  GlobalKey<ScaffoldState> scaffoldStateKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    type = widget.type;
    id = widget.id;
    myId = myId;
    readUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      key: scaffoldStateKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: darkMode ? lightestWhite : lightestBlack,
            child: Text(
              name.firstChar ?? "",
              style: const TextStyle(fontSize: 30, color: Colors.blue),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          // Text(
          //   name,
          //   style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          // ),
          ...List.generate(options.length, (index) {
            String value = index == 0
                ? name
                : index == 1
                    ? email
                    : index == 2
                        ? phone
                        : "";
            return ListTile(
              title: Text(options[index]),
              subtitle: Text(value),
              onTap: () {
                if (id == myId) {
                  showEditAccountBottomSheet(context, options[index], value);
                }
              },
            );
          })
        ],
      ),
      bottomNavigationBar: id != myId
          ? null
          : ActionButton(
              "Logout",
              onPressed: () {
                logOut();
              },
              height: 50,
              color: Colors.blue,
              textColor: Colors.white,
            ),
    ));
  }

  void showEditAccountBottomSheet(
      BuildContext context, String type, String value) {
    scaffoldStateKey.currentState!.showBottomSheet((context) {
      bottomSheetContext = context;
      return EditProfileDialog(
        type: type,
        value: value,
        onSaved: () {
          readUser();
        },
      );
    });
    // showModalBottomSheet(
    //   shape: const RoundedRectangleBorder(
    //       borderRadius: BorderRadius.only(
    //           topLeft: Radius.circular(20), topRight: Radius.circular(20))),
    //   context: context,
    //   builder: (context) {
    //     return EditProfileDialog(type: type, value: value);
    //   },
    // );
  }

  void logOut() {
    fm.logOut().then((value) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: ((context) => const LoginPage(login: true))),
          (route) => false);
    }).onError((error, stackTrace) {
      Fluttertoast.showToast(msg: "Unable to logout");
    });
  }

  void readUser() async {
    final user = await getUser(id);
    if (user != null) {
      name = user.username;
      email = user.email;
      phone = user.phone;
    }
    setState(() {});
  }

  void readGroup() async {
    final group = await getGroup(id);
    if (group != null) {
      name = group.groupname;
    }
    setState(() {});
  }
}

class EditProfileDialog extends StatefulWidget {
  final String type;
  final String value;
  final VoidCallback onSaved;
  const EditProfileDialog({
    super.key,
    required this.type,
    required this.value,
    required this.onSaved,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController controller;
  GlobalKey<FormFieldState> formFieldStateKey = GlobalKey<FormFieldState>();
  bool? passwordComfirmed;
  bool alreadyExist = false;
  bool loading = false;
  FirebaseMethods fm = FirebaseMethods();
  String type = "", name = "", value = "";
  bool showPassword = false;
  late VoidCallback onSaved;

  @override
  void initState() {
    super.initState();
    type = widget.type;
    value = widget.value;
    name = type.toLowerCase();
    onSaved = widget.onSaved;
    controller = TextEditingController();
    controller.text = passwordComfirmed == null ? "" : value;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: darkMode ? lightestWhite : lightestBlack,
            borderRadius: BorderRadius.circular(20)
            // borderRadius: const BorderRadius.only(
            //     topLeft: Radius.circular(20), topRight: Radius.circular(20))
            ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                passwordComfirmed != null && passwordComfirmed!
                    ? "Enter New $type"
                    : "Enter Password",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: TextFormField(
                key: formFieldStateKey,
                autofocus: true,
                controller: controller,
                validator: (string) {
                  return passwordComfirmed == null
                      ? null
                      : !passwordComfirmed!
                          ? "Incorrect Password"
                          : fm.checkValidity(
                              string?.trim() ?? "",
                              name,
                              name == "username"
                                  ? 4
                                  : name == "phone" || name == "password"
                                      ? 6
                                      : 0,
                              name == "username"
                                  ? 25
                                  : name == "phone"
                                      ? 20
                                      : name == "password"
                                          ? 30
                                          : 0,
                              exists: name == "username" || name == "email"
                                  ? alreadyExist
                                  : false);
                },
                obscureText: (name == "password" ||
                        (passwordComfirmed == null || !passwordComfirmed!)) &&
                    !showPassword,
                keyboardType: passwordComfirmed == null || !passwordComfirmed!
                    ? TextInputType.text
                    : name == "email"
                        ? TextInputType.emailAddress
                        : name == "phone"
                            ? TextInputType.phone
                            : TextInputType.text,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: darkMode ? lightWhite : lightBlack)),
                    hintText: passwordComfirmed == null || !passwordComfirmed!
                        ? "Password"
                        : type,
                    suffix: (name == "password" ||
                            (passwordComfirmed == null || !passwordComfirmed!))
                        ? GestureDetector(
                            child: Text(
                              showPassword ? "Hide" : "Show",
                              style: const TextStyle(color: Colors.blue),
                            ),
                            onTap: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                          )
                        : null),
              ),
            ),
            if (loading) ...[
              Container(
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              )
            ],
            if (myId != "") ...[
              ActionButton(
                passwordComfirmed != null && passwordComfirmed!
                    ? loading
                        ? "Saving..."
                        : "Save"
                    : loading
                        ? "Comfirming..."
                        : "Comfirm",
                onPressed: () {
                  if (loading) return;
                  if (passwordComfirmed != null && passwordComfirmed!) {
                    saveDetail(type.toLowerCase(), value);
                  } else {
                    comfirmPassword();
                  }
                  FocusScope.of(context).unfocus();
                },
                height: 50,
                color: loading
                    ? darkMode
                        ? lightWhite
                        : lighterBlack
                    : Colors.blue,
                textColor: loading ? null : Colors.white,
              ),
            ],
          ],
        ));
  }

  void comfirmPassword() {
    setState(() {
      showPassword = false;
      loading = true;
    });
    final text = controller.text.trim();
    fm.comfirmPassword(text).then((value) {
      controller.clear();
      loading = false;
      setState(() {
        passwordComfirmed = value;
      });
    }).onError((error, stackTrace) {
      controller.clear();
      Fluttertoast.showToast(msg: "${error.toString().split("]").second}");
      loading = false;
      setState(() {
        passwordComfirmed = false;
      });
    });
  }

  void saveDetail(String type, String prevValue) async {
    final text = controller.text;
    if (formFieldStateKey.currentState?.validate() ?? false) {
      setState(() {
        showPassword = false;
        loading = true;
      });
      if (type == "email") {
        alreadyExist = await fm.checkIfEmailExists(text);
      } else if (type == "username") {
        alreadyExist = await fm.checkIfUsernameExists(text);
      }
      if (alreadyExist) {
        setState(() {
          loading = false;
        });
        return;
      }
      if (type == "email") {
        await fm.updateEmail(text);
      } else if (type == "password") {
        await fm.updatePassword(text);
      } else if (type == "username") {
        await fm.setValue(["usernames", text], value: {"username": text});
        await fm.removeValue(["usernames", prevValue]);
      }
      await updateUserDetails(type, text);
      loading = false;
      passwordComfirmed = null;
      setState(() {});
      onSaved();
      if (type == "email" || type == "password") {
        logOut();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void logOut() {
    fm.logOut().then((value) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: ((context) => const LoginPage(login: true))),
          (route) => false);
    }).onError((error, stackTrace) {
      Fluttertoast.showToast(msg: "Unable to logout");
    });
  }
}
