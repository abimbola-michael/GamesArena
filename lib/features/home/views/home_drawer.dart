import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/onboarding/pages/auth_page.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/theme/colors.dart';

import '../../../main.dart';
import '../../../shared/utils/constants.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/action_button.dart';
import '../../about/pages/about_game_page.dart';
import '../../app_info/pages/app_info_page.dart';
import '../../onboarding/pages/login_page.dart';
import '../../profile/pages/profile_page.dart';

class HomeDrawer extends ConsumerStatefulWidget {
  final String name;
  const HomeDrawer({super.key, required this.name});

  @override
  ConsumerState<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends ConsumerState<HomeDrawer> {
  void gotoLoginPage() {
    //context.pushTo(const LoginPage(login: true));
    context.pushTo(const AuthPage());
  }

  void gotoAppInfoPage(String type) {
    context.pushTo(AppInfoPage(type: type));
  }

  void gotoAppGamePage(int index) {
    context.pushTo(AboutGamePage(
      game: allGames[index],
    ));
  }

  void gotoProfilePage() {
    context.pushTo(ProfilePage(id: myId, type: "user"));
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              children: [
                DrawerHeader(
                    child: myId.isEmpty
                        ? ActionButton(
                            "Login",
                            onPressed: () {
                              gotoLoginPage();
                            },
                            wrap: true,
                          )
                        : Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: lightestTint,
                                child: Text(
                                  widget.name.firstChar ?? "",
                                  style: const TextStyle(
                                      fontSize: 30, color: Colors.blue),
                                ),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              Text(
                                widget.name,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          )),
                if (myId != "") ...[
                  ListTile(
                    title: const Text(
                      "Profile",
                      style: TextStyle(fontSize: 16),
                    ),
                    onTap: () {
                      gotoProfilePage();
                    },
                  ),
                  //const Divider(),
                ],
                ...List.generate(
                  allGames.length,
                  (index) {
                    return ListTile(
                      title: Text(
                        "About ${allGames[index]}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      onTap: () {
                        gotoAppGamePage(index);
                      },
                    );
                  },
                ),
                ListTile(
                  title: const Text(
                    "Terms and Conditions and Privacy Policy",
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () {
                    gotoAppInfoPage("Terms and Conditions and Privacy Policy");
                  },
                ),
                ListTile(
                  title: const Text(
                    "About Us",
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () {
                    gotoAppInfoPage("About Us");
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Light Theme",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  width: 8,
                ),
                Switch.adaptive(
                    activeColor: Colors.blue,
                    value: themeValue == 0,
                    onChanged: updateTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
