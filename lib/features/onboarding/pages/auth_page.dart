import 'dart:io';

import 'package:country_code_picker_plus/country_code_picker_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gamesarena/core/firebase/auth_methods.dart';
import 'package:gamesarena/features/onboarding/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/extensions/special_context_extensions.dart';
import 'package:gamesarena/shared/widgets/app_button.dart';
import 'package:gamesarena/shared/widgets/app_text_field.dart';
import 'package:gamesarena/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/firebase/firebase_notification.dart';
import '../../../shared/utils/country_code_utils.dart';
import '../../../shared/utils/utils.dart';
import '../../app_info/pages/app_info_page.dart';
import '../../user/models/user.dart';
import '../../user/services.dart';

enum AuthMode { login, signUp, forgotPassword, username }

class AuthPage extends StatefulWidget {
  final AuthMode mode;
  const AuthPage({super.key, this.mode = AuthMode.login});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
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

  String countryDialCode = "";
  String countryCode = "";
  @override
  void initState() {
    super.initState();
    mode = widget.mode;
    usernameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    getCountryCode();
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
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

  void getCountryCode() async {
    final code = await getCurrentCountryCode();
    countryCode = code ?? "";
    setState(() {});
  }

  void googleSignIn() async {
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
      if (needsUsername) {
        setState(() {
          mode = AuthMode.username;
        });
      } else {
        gotoHomePage();
      }
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
    final username =
        usernameController.text.toLowerCase().replaceAll(" ", "").trim();
    final phoneNumber = phoneController.text.trim();
    final phone =
        phoneNumber.startsWith("0") ? phoneNumber.substring(1) : phoneNumber;
    final password = passwordController.text.trim();

    usernameExist = await usernameExists(username);

    if (usernameExist) {
      // Fluttertoast.showToast(
      //     msg: "Username already exist", toastLength: Toast.LENGTH_LONG);
      // ignore: use_build_context_synchronously
      showErrorToast("Username already exist");
      if (!mounted) return;
      context.hideDialog();
      return;
    }

    authMethods.createAccount(email, password).then((value) async {
      await authMethods.sendEmailVerification();
      if (!mounted) return;
      showToast(
        "A verification link has been sent to your mail. Click to comfirm",
      );
      // Fluttertoast.showToast(
      //     msg:
      //         "A verification link has been sent to your mail. Click to comfirm");
      final user = User(
        email: email,
        user_id: "",
        username: username,
        phone: "$countryDialCode$phone",
        time: timeNow,
        last_seen: timeNow,
        token: "",
      );

      await createUser(user.toMap());
      authMethods.logOut();
      mode = AuthMode.login;
      clearControllers();
      setState(() {});
    }).onError((error, stackTrace) {
      showErrorSnackbar(error.toString().onlyErrorMessage,
          onPressed: createAccount);
    }).whenComplete(() => context.hideDialog);
  }

  Future login() async {
    //duration: const Duration(seconds: 5)
    showLoading(message: "Logging in...");
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    authMethods.login(email, password).then((value) async {
      final verified = await authMethods.isEmailVerified();
      if (!verified) {
        showErrorToast("Email not verified");
        if (!mounted) return;
        await showSuccessSnackbar(
          "A verification link has been sent to your mail. Click to comfirm\nIf not found Resend",
          action: "Resend",
          onPressed: () => authMethods.sendEmailVerification(),
        );
        authMethods.logOut();
        return;
      }

      final user = await getUser(getCurrentUserId());
      if (user == null) {
        showErrorToast("User not found");
        authMethods.logOut();
        return;
      }
      if (user.username.isEmpty) {
        setState(() {
          mode = AuthMode.username;
        });
      } else {
        showSuccessToast("Login Successfully");
        FirebaseNotification().updateFirebaseToken();

        gotoHomePage();
      }
    }).onError((error, stackTrace) {
      showErrorSnackbar(error.toString().onlyErrorMessage, onPressed: login);
    }).whenComplete(() => context.hideDialog);
  }

  void resetPassword() {
    final email = emailController.text.trim();

    authMethods.sendPasswordResetEmail(email).then((value) {
      clearControllers();
      mode = AuthMode.login;
      showToast(
          "A password reset email has been sent to you.\nCheck your mail");
      setState(() {});
    }).onError((error, stackTrace) {
      showErrorSnackbar(error.toString().onlyErrorMessage,
          onPressed: resetPassword);
    }).whenComplete(() => context.pop());
  }

  Future createUsername() async {
    final username =
        usernameController.text.toLowerCase().replaceAll(" ", "").trim();
    usernameExist = await usernameExists(username);

    if (usernameExist) {
      showErrorToast("Username already exist");
      if (!mounted) return;
      context.pop();
      return;
    }
    await createUser({"username": username});
    gotoHomePage();
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
      case AuthMode.username:
        createUsername();
        break;
    }
  }

  String getActionTitle() {
    String title = "";
    switch (mode) {
      case AuthMode.login:
        title = "Login";
        break;
      case AuthMode.signUp:
        title = "Sign Up";
        break;
      case AuthMode.forgotPassword:
        title = "Send Password Reset Email";
        break;
      case AuthMode.username:
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
    context.pop();
    //context.pushTo(const HomePage());
    // Navigator.of(context).pushAndRemoveUntil(
    //     MaterialPageRoute(builder: ((context) => const HomePage())),
    //     (route) => false);
  }

  void gotoTermsAndConditions() {
    context.pushTo(const AppInfoPage(
      type: "Terms and Conditions and Privacy Policy",
    ));
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
      },
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _onKey,
        child: Scaffold(
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
                      Text(
                        "Games Arena",
                        style: GoogleFonts.merienda(
                            fontSize: 30, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      if (mode != AuthMode.username)
                        AppTextField(
                          controller: emailController,
                          hintText: "Email",
                        ),
                      if (mode == AuthMode.login || mode == AuthMode.signUp)
                        AppTextField(
                          controller: passwordController,
                          hintText: "Password",
                        ),
                      if (mode == AuthMode.signUp || mode == AuthMode.username)
                        AppTextField(
                          controller: usernameController,
                          hintText: "Username",
                        ),
                      if (mode == AuthMode.signUp)
                        AppTextField(
                          controller: phoneController,
                          hintText: "Phone",
                          validator: (value) {
                            if (value!.startsWith("+")) {
                              return "Select Country dial code and just input the rest of your number";
                            }
                            return null;
                          },
                          prefix: SizedBox(
                            width: 50,
                            child: CountryCodePicker(
                              textStyle:
                                  context.bodyMedium?.copyWith(color: tint),
                              padding: const EdgeInsets.only(left: 10),
                              mode: CountryCodePickerMode.bottomSheet,
                              initialSelection:
                                  countryCode.isNotEmpty ? countryCode : "US",
                              showFlag: false,
                              showDropDownButton: false,
                              dialogBackgroundColor: tint,
                              onChanged: (country) {
                                setState(() {
                                  countryDialCode = country.dialCode;
                                });
                              },
                            ),
                          ),
                        ),
                      if (mode == AuthMode.signUp)
                        Row(
                          children: [
                            Checkbox(
                              activeColor: Colors.blue,
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
                                onPressed: gotoTermsAndConditions,
                                child: const Text(
                                  "Accept Terms, Conditions and Privacy Policy",
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(
                        height: 20,
                      ),
                      AppButton(
                        height: 40,
                        title: getActionTitle(),
                        onPressed: executeAction,
                      ),
                      if (canGoogleSignIn &&
                          (mode == AuthMode.login || mode == AuthMode.signUp))
                        AppButton(
                          height: 40,
                          title: "Login With Gmail",
                          bgColor: const Color(0xffDB4437),
                          margin: const EdgeInsets.only(top: 6),
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
                  mode == AuthMode.signUp)
              ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: mode == AuthMode.login
                          ? "Don't have an account? "
                          : "Already have an account? ",
                      style: TextStyle(color: tint),
                      children: [
                        TextSpan(
                          text: mode == AuthMode.login ? "Sign Up" : "Login",
                          style: const TextStyle(color: primaryColor),
                          recognizer: TapGestureRecognizer()
                            ..onTap = toggleLoginAndSignUp,
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
