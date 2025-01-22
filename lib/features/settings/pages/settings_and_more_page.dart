import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/features/onboarding/pages/auth_page.dart';
import 'package:gamesarena/features/onboarding/services.dart';
import 'package:gamesarena/features/profile/pages/edit_profile_page.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/extensions/special_context_extensions.dart';
import 'package:gamesarena/shared/utils/utils.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../core/firebase/auth_methods.dart';
import '../../../shared/widgets/app_appbar.dart';
import '../../app_info/pages/app_info_page.dart';
import '../../contact/pages/findorinvite_player_page.dart';
import '../../home/pages/home_page.dart';
import '../components/settings_category_item.dart';
import '../components/settings_item.dart';

class SettingsAndMorePage extends StatefulWidget {
  static const route = "/settings-and-more";
  const SettingsAndMorePage({super.key});

  @override
  State<SettingsAndMorePage> createState() => _SettingsAndMorePageState();
}

class _SettingsAndMorePageState extends State<SettingsAndMorePage> {
  final am = AuthMethods();
  String appMail = "abimbolamichael100@gmail.com";

  void gotoEditProfilePage(String type) async {
    final value = type == "email" ? "" : "";
    final newValue =
        await context.pushTo(EditProfilePage(type: type, value: value));
    if (newValue == null) return;
  }

  void changePhoneNumber() {
    gotoEditProfilePage("phone");
  }

  void changeEmail() {
    gotoEditProfilePage("email");
  }

  void changePassword() {
    gotoEditProfilePage("password");
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

  void deleteAccount() async {
    final comfirm = await context.showComfirmationDialog(
        title: "Delete Account",
        message:
            "Are you sure you want to delete account?\nThis is an irreversible process\nYou would no longer be able to login and play online games with this account\nYou cannot create a new account using the same email address");
    if (comfirm != true) return;
    try {
      await deleteUser();
      //await am.deleteAccount();
      am.logOut();
      Hive.box<String>("details").delete("dailyLimit");
      Hive.box<String>("details").delete("dailyLimitDate");

      if (!mounted) return;
      gotoStartPage();
    } catch (e) {
      showErrorToast("Unable to delete account");
    }
  }

  void gotoStartPage() {
    // context.pushReplacement(const AuthPage());

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: ((context) => const HomePage())),
        (route) => false);
  }

  //void addAccount() {}
  void gotoTermsAndPrivacy() {
    context.pushTo(const AppInfoPage(type: "Terms and Privacy Policies"));
  }

  void gotoTermsAndConditions() {
    context.pushTo(const AppInfoPage(type: "Terms and Conditions"));
  }

  void gotoPrivacyPolicies() {
    context.pushTo(const AppInfoPage(type: "Privacy Policies"));
  }

  void gotoAbout() {
    context.pushTo(const AppInfoPage(type: "About Us"));
  }

  void gotoContactUs() {
    String subjectTemp = "Contact: ";
    String bodyTemp = "My name is .....\nI am contacting for ...";

    launchUrl(Uri.parse("mailto:$appMail?subject=$subjectTemp&body=$bodyTemp"));
  }

  void gotoHelpCenter() {
    String subjectTemp = "Help: ";
    String bodyTemp = "My name is .....\nI need help with ...";

    launchUrl(Uri.parse("mailto:$appMail?subject=$subjectTemp&body=$bodyTemp"));
  }

  void gotoInviteContact() {
    context.pushTo(const FindOrInvitePlayersPage(isInvite: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(
        title: "Settings and More",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (myId != "")
              SettingsCategoryItem(title: "Account", children: [
                if (am.isPasswordAuthentication) ...[
                  SettingsItem(
                    title: "Change Email",
                    icon: OctIcons.mail,
                    onPressed: changeEmail,
                  ),
                  SettingsItem(
                    title: "Change Password",
                    icon: OctIcons.lock,
                    onPressed: changePassword,
                  ),
                ],
                SettingsItem(
                  title: "Change Phone Number",
                  icon: EvaIcons.phone_outline,
                  onPressed: changePhoneNumber,
                ),
                SettingsItem(
                  title: "Logout",
                  icon: Icons.exit_to_app_outlined,
                  onPressed: logout,
                ),
                SettingsItem(
                  title: "Delete Account",
                  icon: OctIcons.trash,
                  color: Colors.red,
                  onPressed: deleteAccount,
                ),
              ]),
            SettingsCategoryItem(title: "More", children: [
              SettingsItem(
                title: "About Us",
                icon: OctIcons.info,
                onPressed: gotoAbout,
              ),
              SettingsItem(
                title: "Terms and Conditions",
                icon: OctIcons.info,
                onPressed: gotoTermsAndConditions,
              ),
              SettingsItem(
                title: "Privacy Polices",
                icon: OctIcons.info,
                onPressed: gotoPrivacyPolicies,
              ),
              SettingsItem(
                title: "Help",
                icon: OctIcons.mail,
                onPressed: gotoHelpCenter,
              ),
              SettingsItem(
                title: "Contact Us",
                icon: OctIcons.mail,
                onPressed: gotoContactUs,
              ),
              if (isAndroidAndIos)
                SettingsItem(
                  title: "Invite a Contact",
                  icon: OctIcons.person_add,
                  onPressed: gotoInviteContact,
                ),
            ]),
            // SettingsCategoryItem(title: "Follow Us", children: [
            //   Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       IconButton(
            //         onPressed: () {},
            //         icon: const Icon(IonIcons.logo_instagram),
            //       ),
            //       IconButton(
            //         onPressed: () {},
            //         icon: const Icon(IonIcons.logo_twitter),
            //       ),
            //       IconButton(
            //         onPressed: () {},
            //         icon: const Icon(IonIcons.logo_facebook),
            //       ),
            //       IconButton(
            //         onPressed: () {},
            //         icon: const Icon(IonIcons.logo_tiktok),
            //       ),
            //     ],
            //   )
            // ])
          ],
        ),
      ),
    );
  }
}
