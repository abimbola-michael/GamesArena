import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gamesarena/features/games/pages.dart';
import 'package:gamesarena/features/onboarding/pages/auth_page.dart';
import 'package:gamesarena/features/onboarding/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/theme/colors.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../core/firebase/auth_methods.dart';
import '../../../shared/extensions/special_context_extensions.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/views/loading_overlay.dart';
import '../../../shared/widgets/app_container.dart';
import '../../../shared/widgets/app_text_button.dart';
import '../../../shared/widgets/button.dart';
import '../../user/models/user.dart';
import '../../user/services.dart';
import '../widgets/social.dart';

class WelcomeScreen extends StatefulWidget {
  static const route = "/welcome";

  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool loading = false;
  final authMethods = AuthMethods();

  void siginInWithGoogle() async {
    showLoading(message: "Google Signin in...");

    authMethods.signInWithGoogle().then((cred) async {
      if (cred == null || cred.user == null) {
        showErrorToast("Google Signin Failed");
        return;
      }
      final user = cred.user!;
      final userId = user.uid;
      final userData = await getUser(userId);
      final needsUsername = userData == null || userData.username.isEmpty;

      if (userData == null) {
        final phoneNumer = user.phoneNumber ?? "";
        final phone = phoneNumer.isNotEmpty
            ? phoneNumer.startsWith("+")
                ? phoneNumer.substring(1)
                : phoneNumer
            : "";
        final newUser = User(
          email: user.email ?? "",
          user_id: userId,
          username: "",
          phone: phone,
          time: timeNow,
          last_seen: timeNow,
          token: "",
          profile_photo: user.photoURL,
        );
        await createUser(newUser.toMap());
      }
      if (!mounted) return;
      if (needsUsername) {
        context.pushAndPop(const AuthPage(mode: AuthMode.username));
      } else {
        context.pushAndPop(const HomePage());
      }
    }).onError((error, stackTrace) {
      showErrorSnackbar(error.toString().onlyErrorMessage,
          onPressed: siginInWithGoogle);
    }).whenComplete(() => context.hideDialog);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        loading: loading,
        child: AppContainer(
          color: black,
          //image: const AssetImage("assets/images/png/mask.png"),
          //  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Stack(
            children: [
              // Positioned(
              //   top: statusBarHeight + 20,
              //   right: 20,
              //   child: const AppButton(
              //     fontSize: 12,
              //     title: "Skip",
              //     color: darkBlack,
              //   ),
              // ),
              Positioned(
                top: 150,
                left: 40,
                right: 40,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 45,
                      child: Text(
                        "Welcome",
                        style: context.headlineLarge?.copyWith(color: white),
                      ),
                    ),
                    SizedBox(
                      height: 25,
                      child: Text.rich(
                        TextSpan(
                          text: "to ",
                          style: context.headlineMedium?.copyWith(color: white),
                          children: [
                            TextSpan(
                              text: "Watch Ball",
                              style: context.headlineMedium
                                  ?.copyWith(color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      "Together we watch",
                      style: context.bodyMedium?.copyWith(color: white),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 30,
                left: 30,
                right: 30,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: white.withOpacity(0.5),
                            thickness: 1,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Text(
                          "sign in with",
                          style: TextStyle(
                            color: white,
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Divider(
                            color: white.withOpacity(0.5),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    if (!isWindows)
                      Row(
                        children: [
                          // Social(title: "FACEBOOK", icon: IonIcons.logo_facebook),
                          // SizedBox(width: 20),
                          Social(
                            title: "GOOGLE",
                            icon: IonIcons.logo_google,
                            onPressed: siginInWithGoogle,
                          ),
                        ],
                      ),
                    const SizedBox(
                      height: 20,
                    ),
                    Button(
                      height: 50,
                      color: lightestWhite,
                      borderColor: white,
                      borderRadius: BorderRadius.circular(25),
                      child: const Text(
                        "Start with email",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: white,
                        ),
                      ),
                      onPressed: () {
                        context
                            .pushAndPop(const AuthPage(mode: AuthMode.signUp));
                      },
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                          style: TextStyle(
                            color: white,
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        AppTextButton(
                          text: "Login",
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            // decoration: TextDecoration.underline,
                            // decorationColor: primaryColor,
                          ),
                          onPressed: () {
                            //context.pushNamedTo(MainScreen.route);
                            context.pushAndPop(
                                const AuthPage(mode: AuthMode.login));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
