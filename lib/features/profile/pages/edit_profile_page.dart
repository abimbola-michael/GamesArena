import 'package:flutter/material.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/utils/country_codes.dart';
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
import '../../onboarding/services.dart';

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
  TextEditingController? passwordController;

  GlobalKey<FormState> formFieldStateKey = GlobalKey<FormState>();
  bool? passwordComfirmed;
  bool alreadyExist = false;
  bool loading = false;
  AuthMethods am = AuthMethods();
  FirestoreMethods fm = FirestoreMethods();

  String type = "", name = "", value = "";
  String countryCode = "";
  String newValue = "";
  bool showPassword = false;

  @override
  void initState() {
    super.initState();
    type = widget.type;
    value = widget.value;
    newValue = value;
    name = type.toLowerCase();
    textController = TextEditingController(text: value);

    passwordComfirmed = widget.groupId != null;
    if (widget.groupId == null && am.isPasswordAuthentication) {
      passwordController = TextEditingController();
    }
    if (widget.groupId == null) {
      readUser();
    }
    //controller.text = passwordComfirmed == null ? "" : value;
  }

  @override
  void dispose() {
    textController.dispose();
    passwordController?.dispose();
    super.dispose();
  }

  void readUser() async {
    if (value.isNotEmpty) return;
    final user = await getUser(myId);
    if (user == null) return;
    if (type == "phone") {
      value = user.phone;
      final codeMap = countryCodes.firstWhereNullable((map) =>
          map["dial_code"] != null && value.startsWith(map["dial_code"]!));
      if (codeMap == null) return;
      countryCode = codeMap["alpha_2_code"] ?? codeMap["alpha_3_code"] ?? "";
      if (countryCode.isEmpty) return;
      final dialCode = codeMap["dial_code"];
      if (dialCode == null) return;
      textController.text = value.substring(dialCode.length);
    } else if (type == "username") {
      value = user.username;
      textController.text = value;
    } else if (type == "email") {
      value = user.email;
      textController.text = value;
    }
    setState(() {});
  }

  Future comfirmPassword() async {
    if (!(formFieldStateKey.currentState?.validate() ?? false) &&
        am.isPasswordAuthentication) return;

    setState(() {
      showPassword = false;
      loading = true;
    });

    final password = passwordController?.text.trim() ?? "";
    try {
      passwordComfirmed = await am.comfirmPassword(password);
      if (passwordComfirmed == false) {
        passwordController?.clear();
        showErrorToast("Incorrect Password. Retry");
      }
    } catch (e) {
      // print("e = $e");
      showErrorToast("${e.toString().split("]").second}");
      passwordController?.clear();

      passwordComfirmed = false;
    } finally {
      loading = false;
      setState(() {});
    }
  }

  void saveDetail(String type) async {
    if (!(formFieldStateKey.currentState?.validate() ?? false)) return;

    if (widget.groupId == null &&
        (passwordComfirmed == null || !passwordComfirmed!)) {
      await comfirmPassword();
      if (!passwordComfirmed! || !mounted) return;
    }

    // final text = textController.text;
    final text = newValue;

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
    final time = timeNow;

    if (type == "email") {
      await am.updateEmail(text);
    } else if (type == "password") {
      await am.updatePassword(text);
    } else if (type == "username") {
      await fm.setValue(["usernames", text], value: {"username": text});
      await fm.removeValue(["usernames", value]);
    }
    if (type == "groupname" && widget.groupId != null) {
      await updateGameGroupName(widget.groupId!, text, time);
    }
    if (type.toLowerCase() != "password" && type != "groupname") {
      await updateUserDetails(type, text);
    }
    loading = false;
    passwordComfirmed = null;
    setState(() {});
    if (type == "email" || type == "password") {
      logout();
    } else {
      if (!mounted) return;
      Navigator.of(context).pop({"value": text, "time": time});
    }
  }

  Future logout() async {
    final comfirm = await context.showComfirmationDialog(
        title: "Logout", message: "Are you sure you want to logout?");
    if (comfirm != true) return;

    try {
      showLoading(message: "Logging out...");

      await logoutUser();
      am.logOut();
      gotoStartPage();
    } catch (e) {
      showErrorToast("Unable to logout");
    }
  }

  void gotoStartPage() {
    context.pushReplacement(const AuthPage());

    // Navigator.of(context).pushAndRemoveUntil(
    //   MaterialPageRoute(builder: ((context) => const AuthPage())),
    //   (Route<dynamic> route) => false, // Remove all routes
    // );
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
              AppTextField(
                initialCountryCode: countryCode,
                controller: textController,
                titleText: "New ${type.capitalize}",
                hintText: "Enter New ${type.capitalize}",
                onChanged: (text) {
                  newValue = text;
                },
              ),
              if (widget.groupId == null && am.isPasswordAuthentication) ...[
                const SizedBox(height: 10),
                AppTextField(
                    controller: passwordController,
                    titleText: "Password",
                    hintText: "Enter Password"),
              ],
              const SizedBox(height: 10),
              AppButton(
                loading: loading,
                title: loading ? "Saving..." : "Save",

                onPressed: () {
                  if (loading) return;
                  saveDetail(type.toLowerCase());

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
  }
}
