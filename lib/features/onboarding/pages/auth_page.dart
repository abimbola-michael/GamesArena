import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamesarena/core/firebase/auth_methods.dart';
import 'package:gamesarena/core/firebase/extensions/firebase_extensions.dart';
import 'package:gamesarena/features/onboarding/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/extensions/special_context_extensions.dart';
import 'package:gamesarena/shared/widgets/app_button.dart';
import 'package:gamesarena/shared/widgets/app_text_field.dart';
import 'package:gamesarena/theme/colors.dart';

import '../../../main.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/app_appbar.dart';
import '../../app_info/pages/app_info_page.dart';
import '../../contact/services/services.dart';
import '../../home/pages/home_page.dart';
import '../../user/models/user.dart';
import '../../user/services.dart';

enum AuthMode {
  login,
  signUp,
  forgotPassword,
  username,
  usernameAndPhoneNumber,
  phone,
  verifyEmail
}

class AuthPage extends StatefulWidget {
  final AuthMode mode;
  const AuthPage({super.key, this.mode = AuthMode.login});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with WidgetsBindingObserver {
  AuthMode mode = AuthMode.login;
  AuthMethods authMethods = AuthMethods();
  GlobalKey<FormState> formStateKey = GlobalKey<FormState>();
  bool usernameExist = false;
  bool acceptTerms = false;
  bool canGoogleSignIn = kIsWeb || !Platform.isWindows;

  late TextEditingController usernameController,
      emailController,
      passwordController,
      phoneController;
  String fullNumber = "";
  String selectedCountryCode = "";

  bool sentEmail = false;
  Timer? timer;
  int? emailExpiryTime;
  int emailExpiryDuration = 2 * 60;

  User? user;
  auth.User? authUser;
  bool savedUsernameOrPhone = false;
  bool verifiedEmail = false;

  @override
  void initState() {
    super.initState();
    mode = widget.mode;
    usernameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    WidgetsBinding.instance.addObserver(this);

    // if (mode == AuthMode.verifyEmail) {
    //   checkEmailVerification();
    // }
  }

  @override
  void dispose() {
    timer?.cancel();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // if (mode == AuthMode.verifyEmail) {
      //   checkEmailVerification();
      // }
    }
  }

  void clearControllers() {
    usernameController.clear();
    emailController.clear();
    phoneController.clear();
    passwordController.clear();
  }

  bool _onKey(KeyEvent event) {
    final key = event.logicalKey;
    if (event is KeyDownEvent) {
      if (key == LogicalKeyboardKey.enter) {
        executeAction();
      }
    }
    return false;
  }

  // void gotoNext(User? user, [auth.User? authUser]) async {
  //   hideDialog();
  //   clearControllers();
  //   //user ??= await getUser(myId, useCache: false);
  //   if (user == null) {
  //     if (!mounted) return;
  //     context.pop();
  //     return;
  //   }

  //   // if (!(authUser?.emailVerified ??
  //   //     auth.FirebaseAuth.instance.currentUser?.emailVerified ??
  //   //     true)) {
  //   //   mode = AuthMode.verifyEmail;
  //   //   startEmailVerifcationTimer();
  //   //   setState(() {});
  //   // } else
  //   if (user.username.isEmpty && user.phone.isEmpty) {
  //     mode = AuthMode.usernameAndPhoneNumber;
  //     setState(() {});
  //   } else if (user.username.isEmpty) {
  //     mode = AuthMode.username;
  //     setState(() {});
  //   } else if (user.phone.isEmpty) {
  //     mode = AuthMode.phone;
  //     setState(() {});
  //   } else {
  //     gotoHomePage();
  //   }
  // }

  void updateAccountExist(
      auth.AuthCredential? credential, String? email) async {
    if (credential == null) return;

    await Future.delayed(const Duration(seconds: 1));
    showErrorToast("Email already exist with ${credential.providerId} sign in");

    await Future.delayed(const Duration(seconds: 1));
    showErrorToast("Resign in to link accounts");

    if (credential.providerId == "password") {
      emailController.text = email ?? "";
    }
    mode = AuthMode.login;
    setState(() {});
  }

  Future createAccount() async {
    if (!acceptTerms) {
      showErrorToast("Read and Accept Terms and Conditions First");
      return;
    }
    showLoading(message: "Creating Account...");

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    authMethods.createAccount(email, password).then((userCred) async {
      if (userCred?.user == null) {
        showErrorToast("Account creation failed");

        return;
      }

      authMethods.sendEmailVerification();
      if (isAndroidAndIos || kIsWeb) {
        analytics.logEvent(
          name: 'new_account',
          parameters: {
            'id': userCred!.user!.uid,
            "datetime": DateTime.now().datetime,
          },
        );
      }
      showSuccessToast("Account created Successfully");
      authUser = userCred!.user;

      context.pop();

      // await createUser(userCred.user!);
      // if (!mounted) return;
      // mode = AuthMode.verifyEmail;
      // setState(() {});
    }).onError((error, stackTrace) {
      showErrorSnackbar(error.toString().onlyErrorMessage,
          onPressed: createAccount);
    }).whenComplete(hideDialog);
  }

  Future login() async {
    showLoading(message: "Logging in...");
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    authMethods.login(email, password).then((userCred) async {
      if (userCred?.user == null) {
        showErrorToast("Logging in failed");

        return;
      }
      showSuccessToast("Login Successfully");
      if (isAndroidAndIos || kIsWeb) {
        analytics.logLogin(loginMethod: 'password');
      }

      if (!mounted) return;
      authUser = userCred!.user;
      context.pop();
      // user = await getUser(userCred.user!.uid, useCache: false);
      // if (user == null) {
      //   await createUser(userCred.user!);
      // }
      // goNext();
    }).onError((error, stackTrace) {
      showErrorSnackbar(error.toString().onlyErrorMessage, onPressed: login);
    }).whenComplete(hideDialog);
  }

  void googleSignIn() async {
    showLoading(message: "Signing in...");

    authMethods
        .signInWithGoogle(onAccountExist: updateAccountExist)
        .then((authUser) async {
      if (authUser == null) {
        showErrorToast("Google Sign in failed");
        return;
      }
      showSuccessToast("Sign in Successfully");
      if (isAndroidAndIos || kIsWeb) {
        analytics.logLogin(loginMethod: 'google');
      }
      if (!mounted) return;
      this.authUser = authUser;
      context.pop();
      // user = await getUser(authUser.uid, useCache: false);
      // if (user == null) {
      //   await createUser(authUser);
      // }
      // goNext();
    }).onError((error, stackTrace) {
      showErrorSnackbar(error.toString().onlyErrorMessage,
          onPressed: googleSignIn);
    }).whenComplete(hideDialog);
  }

  void resetPassword() {
    final email = emailController.text.trim();
    showLoading(message: "Sending Password Reset Email...");

    authMethods.sendPasswordResetEmail(email).then((value) {
      // hideDialog();
      clearControllers();
      mode = AuthMode.login;
      showToast(
          "A password reset email has been sent to you.\nCheck your mail");
      setState(() {});
    }).onError((error, stackTrace) {
      showErrorSnackbar(error.toString().onlyErrorMessage,
          onPressed: resetPassword);
    }).whenComplete(hideDialog);
  }

  void startEmailVerifcationTimer() {
    emailExpiryTime = emailExpiryDuration;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (emailExpiryTime != null) {
        emailExpiryTime = emailExpiryTime! - 1;
        if (emailExpiryTime == 0) {
          emailExpiryTime = null;
          timer.cancel();
          this.timer = null;
        }
        setState(() {});
      }
    });
  }

  void checkEmailVerification([bool isClick = false]) async {
    if (await authMethods.isEmailVerified()) {
      timer?.cancel();
      timer = null;
      emailExpiryTime = null;
      //hideDialog();

      showSuccessToast("Email Verified successfully");
      verifiedEmail = true;
      if (!mounted) return;
      context.pop(true);

      // goNext();
    } else {
      if (isClick) {
        showErrorToast("Email not yet verified. Check mail for link or resend");
      }
    }
  }

  void resendVerificationEmail() {
    showLoading(message: "Sending verification email...");

    authMethods.sendEmailVerification().then((value) {
      showToast("A verification email has been sent to you.\nCheck your mail");
      startEmailVerifcationTimer();
      mode = AuthMode.verifyEmail;
      setState(() {});
    }).onError((error, stackTrace) {
      showErrorSnackbar(error.toString().onlyErrorMessage,
          onPressed: resendVerificationEmail);
    }).whenComplete(hideDialog);
  }

  Future createUsernameOrPhone() async {
    // if (user == null) return;
    final username =
        usernameController.text.toLowerCase().replaceAll(" ", "").trim();
    if (username.isNotEmpty) {
      usernameExist = await usernameExists(username);

      if (usernameExist) {
        showErrorToast("Username already exist");
        return;
      }
    }

    final phone = fullNumber;

    final value = {
      if (username.isNotEmpty) "username": username,
      if (phone.isNotEmpty) ...{
        "phone": phone,
        "country_code": selectedCountryCode
      }
    };
    if (!mounted) return;
    context.pop(value);

    // context.showLoading(message: "Saving...");

    // final newValue = await updateUser(user!.user_id, value);
    // if (!mounted) return;

    // context.showSuccessToast("Details saved successfully");
    // saveUserProperty(user!.user_id, newValue, prevUser: user!);
    // gotoHomePage();
  }

  String getTitle() {
    switch (mode) {
      case AuthMode.login:
        return "Login";
      case AuthMode.signUp:
        return "Sign Up";
      case AuthMode.forgotPassword:
        return "Reset Password";
      case AuthMode.verifyEmail:
        return "Verify Email";
      default:
        return "Complete profile";
    }
  }

  void executeAction() {
    if (!(formStateKey.currentState?.validate() ?? false)) {
      return;
    }
    switch (mode) {
      case AuthMode.login:
        login();
        break;
      case AuthMode.signUp:
        createAccount();
        break;
      case AuthMode.forgotPassword:
        resetPassword();
        break;
      case AuthMode.verifyEmail:
        checkEmailVerification(true);
        break;
      default:
        createUsernameOrPhone();
        break;
    }
  }

  String getActionTitle() {
    String title = "Save";
    switch (mode) {
      case AuthMode.login:
        title = "Login";
        break;
      case AuthMode.signUp:
        title = "Sign Up";
        break;
      case AuthMode.verifyEmail:
        title = "Verify";
        break;
      case AuthMode.forgotPassword:
        title = "Send Password Reset Email";
        break;
      default:
        title = "Save";
        break;
    }
    return title;
  }

  void toggleLoginAndSignUp() {
    formStateKey.currentState?.reset();
    // clearControllers();
    if (mode == AuthMode.login) {
      mode = AuthMode.signUp;
    } else {
      mode = AuthMode.login;
    }

    setState(() {});
  }

  Future createUser(auth.User authUser) async {
    if (!mounted) return;
    context.showLoading(message: "Creating user...");

    user = await createUserFromAuthUser(authUser);
    if (!mounted) return;
    context.pop();
    context.showSuccessToast("User created successfully");
    saveUserProperty(authUser.uid, user!.toMap().removeNull());
  }

  void goNext() async {
    if (this.user == null) {
      return;
    }
    final user = this.user!;

    if (user.answeredRequests != true && user.phone.isNotEmpty) {
      acceptPlayersRequests(user.phone);
    }
    if (!mounted) return;

    if (user.username.isEmpty && user.phone.isEmpty) {
      mode = AuthMode.usernameAndPhoneNumber;
      setState(() {});
    } else if (user.username.isEmpty) {
      mode = AuthMode.username;
      setState(() {});
    } else if (user.phone.isEmpty) {
      mode = AuthMode.phone;
      setState(() {});
    } else {
      if (user.time_deleted != null) {
        showToast("Account Deleted");
        await logout();
      }
      gotoHomePage();
    }
  }

  void gotoHomePage() {
    if (!mounted) return;
    firebaseNotification.updateFirebaseToken();
    context.pop();
    context.pushReplacement(const HomePage());

    // Navigator.of(context).pushAndRemoveUntil(
    //   MaterialPageRoute(builder: ((context) => const HomePage())),
    //   (Route<dynamic> route) => false, // Remove all routes
    // );
  }

  Future logout() async {
    try {
      if (user != null) await logoutUser();
      authMethods.logOut();
    } catch (e) {}
  }

  void gotoTermsAndPrivacy() {
    context.pushTo(const AppInfoPage(type: "Terms and Privacy Policies"));
  }

  void gotoTermsAndConditions() {
    context.pushTo(const AppInfoPage(type: "Terms and Conditions"));
  }

  void gotoPrivacyPolicies() {
    context.pushTo(const AppInfoPage(type: "Privacy Policies"));
  }

  @override
  Widget build(BuildContext context) {
    // || mode == AuthMode.signUp
    return PopScope(
      canPop: mode == AuthMode.login,
      onPopInvoked: (pop) {
        if (pop) {
          return;
        }

        if ((mode == AuthMode.verifyEmail && !verifiedEmail) ||
            ((mode == AuthMode.username ||
                    mode == AuthMode.phone ||
                    mode == AuthMode.usernameAndPhoneNumber) &&
                !savedUsernameOrPhone)) {
          logout();
        }
        if (mode != AuthMode.login) {
          setState(() {
            mode = AuthMode.login;
          });
        }
      },
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _onKey,
        child: Scaffold(
          appBar: const AppAppBar(title: "Games Arena", hideBackButton: true),
          body: Center(
            child: SizedBox(
              width: 350,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formStateKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Text(
                      //   "Games Arena",
                      //   style: GoogleFonts.merienda(
                      //       fontSize: 30, fontWeight: FontWeight.bold),
                      //   textAlign: TextAlign.center,
                      // ),
                      Text(
                        getTitle(),
                        style: context.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      if (mode == AuthMode.verifyEmail)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            "A verification email should have been sent to you. Check your mail and if link expired or not found resend.",
                            style: context.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (mode == AuthMode.login ||
                          mode == AuthMode.signUp ||
                          mode == AuthMode.forgotPassword)
                        AppTextField(
                          controller: emailController,
                          hintText: "Email",
                        ),
                      if (mode == AuthMode.login || mode == AuthMode.signUp)
                        AppTextField(
                          controller: passwordController,
                          hintText: "Password",
                        ),
                      if (mode == AuthMode.usernameAndPhoneNumber ||
                          mode == AuthMode.username)
                        AppTextField(
                          controller: usernameController,
                          hintText: "Username",
                        ),
                      if (mode == AuthMode.usernameAndPhoneNumber ||
                          mode == AuthMode.phone)
                        AppTextField(
                          controller: phoneController,
                          hintText: "Phone",
                          onChangedCountryCode: (code) {
                            selectedCountryCode = code;
                          },
                          onChanged: (text) {
                            fullNumber = text;
                          },
                        ),
                      if (mode == AuthMode.signUp)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(
                              activeColor: primaryColor,
                              value: acceptTerms,
                              onChanged: (value) {
                                setState(() {
                                  if (value != null) {
                                    acceptTerms = value;
                                  }
                                });
                              },
                            ),
                            Flexible(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero),
                                onPressed: gotoTermsAndPrivacy,
                                child: const Text(
                                    "Accept Terms and Privacy Policies",
                                    style: TextStyle(color: primaryColor)),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          if (mode == AuthMode.verifyEmail) ...[
                            Expanded(
                              child: AppButton(
                                height: 40,
                                title:
                                    "Resend${emailExpiryTime == null ? "" : " in ${emailExpiryTime?.toDurationString()}"}",
                                bgColor: lightestTint,
                                color: tint,
                                onPressed: emailExpiryTime == null
                                    ? resendVerificationEmail
                                    : null,
                                margin: const EdgeInsets.only(bottom: 10),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: AppButton(
                              height: 40,
                              title: getActionTitle(),
                              onPressed: executeAction,
                              margin: const EdgeInsets.only(bottom: 10),
                            ),
                          ),
                        ],
                      ),

                      //canGoogleSignIn &&
                      if ((mode == AuthMode.login || mode == AuthMode.signUp))
                        AppButton(
                          height: 40,
                          title:
                              "${mode == AuthMode.login ? "Login" : "Sign Up"} With Gmail",
                          bgColor: const Color(0xffDB4437),
                          // margin: const EdgeInsets.only(top: 6),
                          margin: const EdgeInsets.only(bottom: 10),
                          onPressed: googleSignIn,
                        ),
                      if (mode == AuthMode.login)
                        TextButton(
                          onPressed: () {
                            formStateKey.currentState?.reset();

                            setState(() {
                              mode = AuthMode.forgotPassword;
                            });
                          },
                          child: const Text(
                            "Forgot Password",
                            style: TextStyle(color: primaryColor),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: (mode == AuthMode.login ||
                  mode == AuthMode.signUp ||
                  mode == AuthMode.forgotPassword)
              ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: mode == AuthMode.login
                              ? "Don't have an account? "
                              : mode == AuthMode.signUp
                                  ? "Already have an account? "
                                  : "",
                          style: TextStyle(color: tint),
                          children: [
                            TextSpan(
                              text:
                                  mode == AuthMode.login ? "Sign Up" : "Login",
                              style: const TextStyle(color: primaryColor),
                              recognizer: TapGestureRecognizer()
                                ..onTap = toggleLoginAndSignUp,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                              onPressed: gotoTermsAndConditions,
                              child: Text("Terms and Conditions",
                                  style: context.bodySmall
                                      ?.copyWith(color: primaryColor))),
                          Container(
                            height: 10,
                            width: 1,
                            color: lightestTint,
                          ),
                          TextButton(
                              onPressed: gotoPrivacyPolicies,
                              child: Text("Privacy Policies",
                                  style: context.bodySmall
                                      ?.copyWith(color: primaryColor))),
                        ],
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
