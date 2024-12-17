import 'package:flutter/material.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/theme/colors.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../core/firebase/auth_methods.dart';
import '../../../core/firebase/firebase_methods.dart';
import '../../../core/firebase/firestore_methods.dart';
import '../../../shared/extensions/special_context_extensions.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../shared/widgets/app_appbar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../game/services.dart';
import '../../onboarding/pages/auth_page.dart';

class EditProfilePage extends StatefulWidget {
  final String? groupId;
  final String type;
  final String value;
  const EditProfilePage({
    super.key,
    this.groupId,
    required this.type,
    required this.value,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController textController;
  late TextEditingController passwordController;

  GlobalKey<FormState> formFieldStateKey = GlobalKey<FormState>();
  bool? passwordComfirmed;
  bool alreadyExist = false;
  bool loading = false;
  AuthMethods am = AuthMethods();
  FirestoreMethods fm = FirestoreMethods();

  String type = "", name = "", value = "";
  bool showPassword = false;

  @override
  void initState() {
    super.initState();
    type = widget.type;
    value = widget.value;
    name = type.toLowerCase();
    textController = TextEditingController(text: value);
    passwordController = TextEditingController();

    passwordComfirmed = widget.groupId != null;
    //controller.text = passwordComfirmed == null ? "" : value;
  }

  @override
  void dispose() {
    textController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future comfirmPassword() async {
    if (!(formFieldStateKey.currentState?.validate() ?? false)) return;

    setState(() {
      showPassword = false;
      loading = true;
    });

    final password = passwordController.text.trim();
    try {
      passwordComfirmed = await am.comfirmPassword(password);
      if (passwordComfirmed == false) {
        passwordController.clear();
        showErrorToast("Incorrect Password. Retry");
      }
    } catch (e) {
      print("e = $e");
      showErrorToast("${e.toString().split("]").second}");
      passwordController.clear();

      passwordComfirmed = false;
    } finally {
      loading = false;
      setState(() {});
    }
  }

  void saveDetail(String type) async {
    if (!(formFieldStateKey.currentState?.validate() ?? false)) return;

    if (passwordComfirmed == null || !passwordComfirmed!) {
      await comfirmPassword();
      if (!passwordComfirmed! || !mounted) return;
    }

    final text = textController.text;

    if (value == text) {
      context.pop();
      return;
    }
    setState(() {
      showPassword = false;
      loading = true;
    });
    if (type == "email") {
      alreadyExist = await am.checkIfEmailExists(text);
    } else if (type == "username") {
      alreadyExist = await fm.checkIfUsernameExists(text);
    }
    if (alreadyExist) {
      setState(() {
        loading = false;
      });
      showErrorToast("Username already exist. Please try another");

      return;
    }
    if (type == "email") {
      await am.updateEmail(text);
    } else if (type == "password") {
      await am.updatePassword(text);
    } else if (type == "username") {
      await fm.setValue(["usernames", text], value: {"username": text});
      await fm.removeValue(["usernames", value]);
    }
    if (type == "groupname" && widget.groupId != null) {
      await updateGameGroupName(widget.groupId!, text);
    }
    if (type.toLowerCase() != "password" && type != "groupname") {
      await updateUserDetails(type, text);
    }
    loading = false;
    passwordComfirmed = null;
    setState(() {});
    if (type == "email" || type == "password") {
      logOut();
    } else {
      if (!mounted) return;
      Navigator.of(context).pop(text);
    }
  }

  void logOut() {
    am.logOut().then((value) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: ((context) => const AuthPage())),
          (route) => false);
    }).onError((error, stackTrace) {
      showErrorToast("Unable to logout");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: "Change ${type.capitalize}"),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: formFieldStateKey,
          child: Column(
            children: [
              if (widget.groupId == null) ...[
                AppTextField(
                    controller: passwordController,
                    titleText: "Password",
                    hintText: "Enter Password"),
                const SizedBox(height: 10),
              ],
              AppTextField(
                  controller: textController,
                  titleText: "New ${type.capitalize}",
                  hintText: "Enter New ${type.capitalize}"),
              const SizedBox(height: 10),
              AppButton(
                wrapped: true,
                loading: loading,
                title: passwordComfirmed != null && passwordComfirmed!
                    ? "Saving..."
                    : "Save",
                // loading
                //     ? passwordComfirmed != null && passwordComfirmed!
                //         ? "Saving..."
                //         : "Comfirming Password..."
                //     : "Save",
                onPressed: () {
                  if (loading) return;
                  saveDetail(type.toLowerCase());

                  // if (passwordComfirmed != null && passwordComfirmed!) {
                  //   saveDetail(type.toLowerCase(), value);
                  // } else {
                  //   comfirmPassword();
                  // }
                  FocusScope.of(context).unfocus();
                },
                // height: 50,
                // color: loading ? tint : Colors.blue,
                // textColor: loading ? null : Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
    // return Container(
    //     // decoration: BoxDecoration(
    //     //     //  color: lightestTint,
    //     //     borderRadius: BorderRadius.circular(20)
    //     //     // borderRadius: const BorderRadius.only(
    //     //     //     topLeft: Radius.circular(20), topRight: Radius.circular(20))
    //     //     ),
    //     padding: const EdgeInsets.all(16),
    //     child: Column(
    //       //mainAxisSize: MainAxisSize.min,
    //       children: [
    //         Padding(
    //           padding: const EdgeInsets.all(16.0),
    //           child: Text(
    //             passwordComfirmed != null && passwordComfirmed!
    //                 ? "Enter New $type"
    //                 : "Enter Password",
    //             style:
    //                 const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    //           ),
    //         ),
    //         Padding(
    //           padding:
    //               const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
    //           child: TextFormField(
    //             key: formFieldStateKey,
    //             autofocus: true,
    //             controller: controller,
    //             validator: (string) {
    //               return passwordComfirmed == null
    //                   ? null
    //                   : !passwordComfirmed!
    //                       ? "Incorrect Password"
    //                       : fm.checkValidity(
    //                           string?.trim() ?? "",
    //                           name,
    //                           name == "username" || name == "groupname"
    //                               ? 4
    //                               : name == "phone" || name == "password"
    //                                   ? 6
    //                                   : 0,
    //                           name == "username"
    //                               ? 25
    //                               : name == "phone"
    //                                   ? 20
    //                                   : name == "password"
    //                                       ? 30
    //                                       : 0,
    //                           exists: name == "username" || name == "email"
    //                               ? alreadyExist
    //                               : false);
    //             },
    //             obscureText: (name == "password" ||
    //                     (passwordComfirmed == null || !passwordComfirmed!)) &&
    //                 !showPassword,
    //             keyboardType: passwordComfirmed == null || !passwordComfirmed!
    //                 ? TextInputType.text
    //                 : name == "email"
    //                     ? TextInputType.emailAddress
    //                     : name == "phone"
    //                         ? TextInputType.phone
    //                         : TextInputType.text,
    //             decoration: InputDecoration(
    //               border: OutlineInputBorder(
    //                   borderRadius: BorderRadius.circular(10),
    //                   borderSide: BorderSide(color: lightTint)),
    //               hintText: passwordComfirmed == null || !passwordComfirmed!
    //                   ? "Password"
    //                   : type,
    //               suffixIcon: (name == "password" ||
    //                       (passwordComfirmed == null || !passwordComfirmed!))
    //                   ? SizedBox(
    //                       width: 17,
    //                       height: 17,
    //                       child: IconButton(
    //                         icon: Icon(
    //                             showPassword ? IonIcons.eye : IonIcons.eye_off),
    //                         onPressed: () {
    //                           setState(() {
    //                             showPassword = !showPassword;
    //                           });
    //                         },
    //                         iconSize: 17,
    //                       ),
    //                     )
    //                   : null,
    //             ),
    //           ),
    //         ),
    //         if (loading) ...[const Center(child: CircularProgressIndicator())],
    //         if (myId != "") ...[
    //           ActionButton(
    //             passwordComfirmed != null && passwordComfirmed!
    //                 ? loading
    //                     ? "Saving..."
    //                     : "Save"
    //                 : loading
    //                     ? "Comfirming..."
    //                     : "Comfirm",
    //             onPressed: () {
    //               if (loading) return;
    //               if (passwordComfirmed != null && passwordComfirmed!) {
    //                 saveDetail(type.toLowerCase(), value);
    //               } else {
    //                 comfirmPassword();
    //               }
    //               FocusScope.of(context).unfocus();
    //             },
    //             height: 50,
    //             color: loading ? tint : Colors.blue,
    //             textColor: loading ? null : Colors.white,
    //           ),
    //         ],
    //       ],
    //     ));
  }
}
