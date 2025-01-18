import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/features/games/pages.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import '../../../shared/views/loading_overlay.dart';
import '../../../shared/widgets/app_text_button.dart';
import '../../../shared/widgets/button.dart';
import '../../../theme/colors.dart';
import '../mocks/onboarding_infos.dart';
import '../widgets/onboarding_info_item.dart';
import '../widgets/page_indicator.dart';
import 'welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  static const route = "/onboarding";

  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentPage = 0;
  final _controller = PageController();
  Timer? timer;
  bool loading = true;
  StreamSubscription? authSub;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkIfLoggedIn();
  }

  @override
  void dispose() {
    _controller.dispose();
    timer?.cancel();
    authSub?.cancel();
    super.dispose();
  }

  void checkIfLoggedIn() {
    try {
      authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null && user.emailVerified) {
          gotoMainScreen();
        } else {
          setState(() {
            loading = false;
          });
          startTimer();
        }
      });
    } catch (e) {}
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer(const Duration(seconds: 5), () {
      goNext(false);
    });
  }

  void gotoMainScreen() {
    context.pushReplacement(const HomePage());
  }

  void gotoWelcomeScreen() {
    context.pushReplacement(const WelcomeScreen());
  }

  void goNext(bool isClick) {
    if (currentPage == onboardingInfos.length - 1) {
      if (isClick) {
        gotoWelcomeScreen();
        return;
      }
    }
    if (currentPage == onboardingInfos.length - 1) {
      currentPage = 0;
    } else {
      currentPage++;
    }

    _controller.jumpToPage(currentPage);
    // _controller.animateToPage(currentPage,
    //     duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    setState(() {});
  }

  void goPrev() {}

  @override
  Widget build(BuildContext context) {
    // print("snapshot $snapshot");
    // if (snapshot.connectionState == ConnectionState.waiting) {
    //   return const LoadingOverlay();
    // }
    // if (snapshot.hasError) {
    //   return ErrorOverlay(
    //     message: snapshot.error.toString(),
    //   );
    // }

    return Scaffold(
      body: LoadingOverlay(
        loading: loading,
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) {
                  startTimer();
                },
                children: List.generate(onboardingInfos.length, (index) {
                  final onboardingInfo = onboardingInfos[index];
                  return OnboardingInfoItem(onboardingInfo: onboardingInfo);
                }),
              ),
            ),
            PageIndicator(page: currentPage, pageCount: 3),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 10, right: 20, bottom: 20, top: 20),
              child: Row(
                mainAxisAlignment: currentPage != onboardingInfos.length - 1
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                children: [
                  if (currentPage != onboardingInfos.length - 1)
                    AppTextButton(
                      text: "Skip",
                      style: context.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500, color: lightTint),
                      onPressed: gotoWelcomeScreen,
                    ),
                  Button(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 60),
                    onPressed: () => goNext(true),
                    child: Text(
                      currentPage == onboardingInfos.length - 1
                          ? "Lets Get Started"
                          : "Next",
                      style: context.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600, color: white),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
    ;
  }
}
