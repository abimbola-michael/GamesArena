import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker_plus/country_code_picker_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gamesarena/core/firebase/auth_methods.dart';
import 'package:gamesarena/core/firebase/extensions/firebase_extensions.dart';
import 'package:gamesarena/features/onboarding/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/extensions/special_context_extensions.dart';
import 'package:gamesarena/shared/widgets/app_button.dart';
import 'package:gamesarena/shared/widgets/app_text_field.dart';
import 'package:gamesarena/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/firebase/firebase_notification.dart';
import '../../../main.dart';
import '../../../shared/utils/country_code_utils.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/app_appbar.dart';
import '../../app_info/pages/app_info_page.dart';
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

  // String countryDialCode = "";
  // String countryCode = "";
  String fullNumber = "";
  bool sentEmail = false;
  Timer? timer;
  int? emailExpiryTime;
  int emailExpiryDuration = 2 * 60;

  User? user;
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

    if (mode == AuthMode.verifyEmail) {
      checkEmailVerification();
    }
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
      if (mode == AuthMode.verifyEmail) {
        checkEmailVerification();
      }
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

  Future<User> createUser(auth.User authUser) async {
    final userId = authUser.uid;
    final time = timeNow;

    final phone = authUser.phoneNumber?.toValidNumber() ?? "";

    final newUser = User(
      email: authUser.email ?? "",
      user_id: userId,
      username: "",
      phone: phone,
      time_modified: time,
      time: time,
      last_seen: time,
      tokens: [],
      profile_photo: authUser.photoURL,
    );
    await createOrUpdateUser(newUser.toMap());
    saveUserProperty(userId, newUser.toMap().removeNull(), prevUser: newUser);
    return newUser;
  }

  void gotoNext(User? user) async {
    hideDialog();
    clearControllers();
    user ??= await getUser(myId);
    if (user == null) {
      if (!mounted) return;
      context.pop();
      return;
    }

    if (!authMethods.emailVerified) {
      mode = AuthMode.verifyEmail;
      startEmailVerifcationTimer();
      setState(() {});
    } else if (user.username.isEmpty && user.phone.isEmpty) {
      mode = AuthMode.usernameAndPhoneNumber;
      setState(() {});
    } else if (user.username.isEmpty) {
      mode = AuthMode.username;
      setState(() {});
    } else if (user.phone.isEmpty) {
      mode = AuthMode.phone;
      setState(() {});
    } else {
      gotoHomePage();
    }
  }

  void googleSignIn() async {
    showLoading(message: "Signin in...");

    authMethods.signInWithGoogle().then((authUser) async {
      if (authUser == null) {
        showErrorToast("Google Sign in Failed");
        return;
      }
      final userId = authUser.uid;
      User? user = await getUser(userId);
      user ??= await createUser(authUser);
      showSuccessToast("Sign in Successfully");

      gotoNext(user);
    }).onError((error, stackTrace) {
      showErrorSnackbar(error.toString().onlyErrorMessage,
          onPressed: googleSignIn);
    }).whenComplete(() => context.hideDialog);
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
      await authMethods.sendEmailVerification();

      if (userCred?.user == null) return;

      final user = await createUser(userCred!.user!);
      showSuccessToast("Account created Successfully");

      gotoNext(user);
    }).onError((error, stackTrace) {
      showErrorSnackbar(error.toString().onlyErrorMessage,
          onPressed: createAccount);
    }).whenComplete(() => context.hideDialog);
  }

  Future login() async {
    showLoading(message: "Logging in...");
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    authMethods.login(email, password).then((userCred) async {
      User? user = await getUser(myId);
      if (user?.time_deleted != null) {
        showErrorToast("Account deleted");
        authMethods.logOut();
        return;
      }
      if (userCred?.user == null) return;
      user ??= await createUser(userCred!.user!);
      gotoNext(user);
      showSuccessToast("Login Successfully");
    }).onError((error, stackTrace) {
      showErrorSnackbar(error.toString().onlyErrorMessage, onPressed: login);
    }).whenComplete(() => context.hideDialog);
  }

  void resetPassword() {
    final email = emailController.text.trim();
    showLoading(message: "Sending Password Reset Email...");

    authMethods.sendPasswordResetEmail(email).then((value) {
      hideDialog();
      clearControllers();
      mode = AuthMode.login;
      showToast(
          "A password reset email has been sent to you.\nCheck your mail");
      setState(() {});
    }).onError((error, stackTrace) {
      showErrorSnackbar(error.toString().onlyErrorMessage,
          onPressed: resetPassword);
    }).whenComplete(() => context.hideDialog());
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
      showSuccessToast("Email Verified successfully");
      verifiedEmail = true;
      gotoNext(user);
    } else {
      if (isClick) {
        showErrorToast("Email not yet verified. Check mail for link or resend");
      }
    }
  }

  void resendVerificationEmail() {
    showLoading(message: "Sending verification email...");

    authMethods.sendEmailVerification().then((value) {
      hideDialog();
      //mode = AuthMode.login;
      showToast("A verification email has been sent to you.\nCheck your mail");
      startEmailVerifcationTimer();
      setState(() {});
    }).onError((error, stackTrace) {
      showErrorSnackbar(error.toString().onlyErrorMessage,
          onPressed: resendVerificationEmail);
    }).whenComplete(() => context.hideDialog());
  }

  Future createUsernameOrPhone() async {
    final username =
        usernameController.text.toLowerCase().replaceAll(" ", "").trim();
    if (username.isNotEmpty) {
      usernameExist = await usernameExists(username);

      if (usernameExist) {
        showErrorToast("Username already exist");
        if (!mounted) return;
        context.pop();
        return;
      }
    }

    final phone = fullNumber;

    final value = {
      if (username.isNotEmpty) ...{"username": username},
      if (phone.isNotEmpty) ...{"phone": phone}
    };
    showLoading(message: "Saving...");

    if (username.isNotEmpty || phone.isNotEmpty) {
      await createOrUpdateUser(value);
    }
    savedUsernameOrPhone = true;

    gotoHomePage();
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
    clearControllers();
    if (mode == AuthMode.login) {
      mode = AuthMode.signUp;
    } else {
      mode = AuthMode.login;
    }

    setState(() {});
  }

  void gotoHomePage() {
    firebaseNotification.updateFirebaseToken();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: ((context) => const HomePage())),
      (Route<dynamic> route) => false, // Remove all routes
    );
  }

  Future logout() async {
    try {
      await logoutUser();
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
    return PopScope(
      canPop: mode == AuthMode.login || mode == AuthMode.signUp,
      onPopInvoked: (pop) {
        if (pop) {
          return;
        }
        if (mode != AuthMode.login) {
          setState(() {
            mode = AuthMode.login;
          });
        }
        if ((mode == AuthMode.verifyEmail && !verifiedEmail) ||
            ((mode == AuthMode.username ||
                    mode == AuthMode.phone ||
                    mode == AuthMode.usernameAndPhoneNumber) &&
                !savedUsernameOrPhone)) {
          logout();
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
                          onChanged: (text) {
                            fullNumber = text;
                          },
                          // prefix: SizedBox(
                          //   width: 50,
                          //   child: CountryCodePicker(
                          //     textStyle:
                          //         context.bodyMedium?.copyWith(color: tint),
                          //     padding: const EdgeInsets.only(left: 10),
                          //     mode: CountryCodePickerMode.bottomSheet,
                          //     initialSelection:
                          //         countryCode.isNotEmpty ? countryCode : "US",
                          //     showFlag: false,
                          //     showDropDownButton: false,
                          //     dialogBackgroundColor: offtint,
                          //     onChanged: (country) {
                          //       setState(() {
                          //         countryDialCode = country.dialCode;
                          //       });
                          //     },
                          //   ),
                          // ),
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

                      if (canGoogleSignIn &&
                          (mode == AuthMode.login || mode == AuthMode.signUp))
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
