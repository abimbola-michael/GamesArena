import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/onboarding/pages/auth_page.dart';
import 'package:gamesarena/features/settings/pages/settings_and_more_page.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/theme/colors.dart';

import '../../../main.dart';
import '../../../shared/utils/constants.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../shared/widgets/app_button.dart';
import '../../about/pages/about_game_page.dart';
import '../../app_info/pages/app_info_page.dart';
import '../../game/widgets/profile_photo.dart';
import '../../profile/pages/profile_page.dart';
import '../../subscription/pages/subscription_page.dart';
import '../../user/services.dart';
import '../widgets/drawer_tile.dart';

class HomeDrawer extends ConsumerStatefulWidget {
  final String name;
  const HomeDrawer({super.key, required this.name});

  @override
  ConsumerState<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends ConsumerState<HomeDrawer> {
  String name = "";
  String profilePhoto = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readUser();
  }

  void readUser() async {
    if (myId.isEmpty) return;
    final user = await getUser(myId);
    name = user?.username ?? "";
    profilePhoto = user?.profile_photo ?? "";
    setState(() {});
  }

  void gotoLoginPage() {
    //context.pop();
    context.pushTo(const AuthPage());
  }

  void gotoAppInfoPage(String type) {
    //context.pop();
    context.pushTo(AppInfoPage(type: type));
  }

  void gotoAppGamePage(int index) {
    //context.pop();
    context.pushTo(AboutGamePage(game: allGames[index]));
  }

  void gotoProfilePage() {
    //context.pop();
    context.pushTo(ProfilePage(id: myId));
  }

  void gotoSettingPage() {
    //context.pop();
    context.pushTo(const SettingsAndMorePage());
  }

  void gotoSubscriptionPage() {
    //context.pop();
    context.pushTo(const SubscriptionPage());
  }

  void updateTheme(bool value) {
    themeValue = value ? 0 : 1;
    sharedPref.setInt("theme", themeValue);
    setState(() {});
    ref.read(themeNotifierProvider.notifier).toggleTheme(themeValue);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: [
                  DrawerHeader(
                      child: myId.isEmpty
                          ? Center(
                              child: AppButton(
                                title: "Login",
                                onPressed: gotoLoginPage,
                                wrapped: true,
                              ),
                            )
                          : GestureDetector(
                              onTap: gotoProfilePage,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ProfilePhoto(
                                      profilePhoto: profilePhoto,
                                      name: name,
                                      size: 80),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )),
                  if (myId != "")
                    DrawerTile(title: "Profile", onPressed: gotoProfilePage),
                  DrawerTile(title: "Settings", onPressed: gotoSettingPage),
                  // DrawerTile(
                  //     title: "Subscription", onPressed: gotoSubscriptionPage),
                  DrawerTile(
                      title: "Terms and Conditions",
                      onPressed: () => gotoAppInfoPage("Terms and Conditions")),
                  DrawerTile(
                      title: "Privacy Policies",
                      onPressed: () => gotoAppInfoPage("Privacy Policies")),
                  DrawerTile(
                      title: "About Us",
                      onPressed: () => gotoAppInfoPage("About Us")),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                    child: DrawerTile(title: "Light Theme", onPressed: () {})),
                const SizedBox(
                  width: 8,
                ),
                Switch.adaptive(
                    activeColor: Colors.blue,
                    value: themeValue == 0,
                    onChanged: updateTheme),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
