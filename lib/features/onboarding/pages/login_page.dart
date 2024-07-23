import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gamesarena/core/firebase/firebase_methods.dart';
import 'package:gamesarena/features/onboarding/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/app_info/pages/app_info_page.dart';
import 'package:gamesarena/features/games/pages.dart';
import 'package:gamesarena/theme/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/features/user/models/user.dart' as myUser;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/services.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../shared/utils/utils.dart';
import '../../user/services.dart';

class LoginPage extends StatefulWidget {
  final bool login;
  const LoginPage({super.key, required this.login});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool login = false;
  bool forgotPassword = false;
  bool loading = false;
  String username = "", phone = "", email = "", password = "";
  FirebaseMethods fm = FirebaseMethods();
  String timeNow = DateTime.now().millisecondsSinceEpoch.toString();
  bool usernameExist = false, emailExist = false;
  GlobalKey<FormState> formStateKey = GlobalKey<FormState>();
  bool showPassword = false;
  bool acceptTerms = false;
  bool enterUsername = false;
  bool comfirmEmail = false;
  late TextEditingController usernameController,
      emailController,
      passwordController,
      phoneController;

  @override
  void initState() {
    super.initState();
    login = widget.login;
    usernameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    if (kIsWeb) {
      ServicesBinding.instance.keyboard.addHandler(_onKey);
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    if (kIsWeb) ServicesBinding.instance.keyboard.removeHandler(_onKey);
    super.dispose();
  }

  Future googleSignIn() async {
    fm.signInWithGoogle((phoneNumber) {
      //phone = phoneNumber;
    }).then((cred) async {
      if (cred == null || cred.user == null) {
        Fluttertoast.showToast(msg: "Google Signin Failed");
        return;
      }
      final user = cred.user!;
      final userId = user.uid;
      final userData = await getUser(userId);
      email = user.email ?? "";
      phone = user.phoneNumber ?? "";
      username = user.displayName ?? "";
      username = username.replaceAll(" ", "_").toLowerCase();
      bool usernameExist = await fm.checkIfUsernameExists(username);
      int trialCount = 1;

      while (usernameExist) {
        username = "${username.replaceAll(" ", "_").toLowerCase()}$trialCount";
        usernameExist = await fm.checkIfUsernameExists(username);
        trialCount++;
      }
      if (userData == null) {
        final newUser = myUser.User(
          email: email,
          user_id: userId,
          username: username,
          phone: phone,
          time: timeNow,
          last_seen: timeNow,
          token: "",
          profile_photo: user.photoURL,
        );
        await createUser(newUser.toMap());
      }
      // email = user.email ?? "";
      // username =
      //     user.displayName?.trim() ?? "".replaceAll(" ", "").toLowerCase();
      // phone = user.phoneNumber?.trim() ?? "";
      // if (userData != null) {
      //   gotoHomePage();
      // } else {
      //   setState(() {
      //     loading = false;
      //     enterUsername = true;
      //   });
      // }
      gotoHomePage();
    }).onError((error, stackTrace) {
      Fluttertoast.showToast(
          msg: error.toString().contains("]")
              ? "${error.toString().split("]").second}"
              : error.toString());
    });
  }

  Future createAccount(bool isGmailLogin) async {
    email = email.trim();
    username = username.trim();
    phone = phone.trim();
    password = password.trim();
    if (!isGmailLogin && email.isNotEmpty) {
      emailExist = await fm.checkIfEmailExists(email);
    }
    if (username.isNotEmpty) {
      username = username.toLowerCase().replaceAll(" ", "").trim();
      usernameExist = await fm.checkIfUsernameExists(username);
    }
    if (emailExist || usernameExist) {
      final existMessage = (emailExist && usernameExist)
          ? "Username and Email"
          : emailExist
              ? "Email"
              : "Username";
      Fluttertoast.showToast(
          msg: "$existMessage already exist", toastLength: Toast.LENGTH_LONG);
      setState(() {
        loading = false;
      });
      return;
    }

    fm.createAccount(email, password).then((value) async {
      if (!isGmailLogin) {
        try {
          await fm.sendEmailVerification();
          Fluttertoast.showToast(
              msg:
                  "A comfirmation link has been sent to your mail. Click to comfirm");
        } on Exception {}
      }
      final currentuser = FirebaseAuth.instance.currentUser;
      await fm.setValue(["usernames", username], value: {"username": username});
      if (currentuser != null) {
        final user = myUser.User(
          email: email,
          user_id: currentuser.uid,
          username: username,
          phone: phone,
          time: timeNow,
          last_seen: timeNow,
          token: "",
        );
        await currentuser.updateDisplayName(username);
        await createUser(user.toMap());
        clearControllers();
        setState(() {
          loading = false;
        });
        if (!isGmailLogin) {
          fm.logOut().then((value) {
            setState(() {
              loading = false;
              login = true;
              username = "";
              email = "";
              password = "";
              phone = "";
            });
            //Navigator.pop(context);
          }).onError((error, stackTrace) {
            clearControllers();

            setState(() {
              loading = false;
              Fluttertoast.showToast(
                  msg: error.toString().contains("]")
                      ? "${error.toString().split("]").second}"
                      : error.toString(),
                  toastLength: Toast.LENGTH_LONG);
            });
          });
        } else {
          gotoHomePage();
        }
      }
    }).onError((error, stackTrace) {
      Fluttertoast.showToast(
          msg: error.toString().contains("]")
              ? "${error.toString().split("]").second}"
              : error.toString());
      clearControllers();
      setState(() {
        loading = false;
      });
    });
  }

  void gotoHomePage() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: ((context) => const HomePage())),
        (route) => false);
  }

  Future loginOrSignUp() async {
    email = email.trim();
    password = password.trim();
    setState(() {
      emailExist = false;
      usernameExist = false;
    });
    if (formStateKey.currentState?.validate() ?? false) {
      setState(() {
        loading = true;
      });
      if (enterUsername) {
        createAccount(true);
      } else if (forgotPassword) {
        fm.sendPasswordResetEmail(email).then((value) {
          clearControllers();
          forgotPassword = false;
          login = true;
          Fluttertoast.showToast(
              msg:
                  "A password reset email has been sent to you. \n Check your mail",
              toastLength: Toast.LENGTH_LONG);
          setState(() {});
        }).onError((error, stackTrace) {
          clearControllers();
          setState(() {
            loading = false;
            Fluttertoast.showToast(
                msg: error.toString().contains("]")
                    ? "${error.toString().split("]").second}"
                    : error.toString());
          });
        });
      } else {
        if (login) {
          fm.login(email, password).then((value) async {
            clearControllers();
            final emailVerified = await fm.isEmailVerified();
            if (!emailVerified) {
              comfirmEmail = true;
              loading = false;
              Fluttertoast.showToast(
                  msg: "Email Not Verified. \n Check your mail",
                  toastLength: Toast.LENGTH_LONG);
              fm.logOut().then((value) {
                setState(() {
                  login = true;
                  username = "";
                  email = "";
                  password = "";
                  phone = "";
                });
              });
            } else {
              // String? token;
              // if (kIsWeb) {
              //   final key = await getPrivateKey();
              //   if (key == null) return;
              //   String vapidKey = key.vapidKey;
              //   token = await FirebaseMessaging.instance
              //       .getToken(vapidKey: vapidKey);
              // } else {
              //   token = await FirebaseMessaging.instance
              //       .getToken();
              // }
              // if (token != null) {
              //   updateToken(token);
              // }
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: ((context) => const HomePage())),
                  (route) => false);
            }
          }).onError((error, stackTrace) {
            clearControllers();
            setState(() {
              loading = false;
              Fluttertoast.showToast(
                  msg: error.toString().contains("]")
                      ? "${error.toString().split("]").second}"
                      : error.toString(),
                  toastLength: Toast.LENGTH_LONG);
            });
          });
        } else {
          await createAccount(false);

          // fm.createAccount(email, password).then((value) {
          //   fm.sendEmailVerification().then((value) async {
          //     final currentuser = FirebaseAuth.instance.currentUser;
          //     await fm.setValue(["usernames", username],
          //         value: {"username": username});
          //     if (currentuser != null) {
          //       final user = myUser.User(
          //         email: email,
          //         user_id: currentuser.uid,
          //         username: username,
          //         phone: phone,
          //         token: "",
          //         time: timeNow,
          //         last_seen: timeNow,
          //       );
          //       await createUser(user);
          //       clearControllers();
          //       Fluttertoast.showToast(
          //           msg:
          //               "A comfirmation email has been sent to you. \n Check your mail",
          //           toastLength: Toast.LENGTH_LONG);
          //     }
          //     fm.logOut().then((value) {
          //       setState(() {
          //         loading = false;
          //         login = true;
          //         username = "";
          //         email = "";
          //         password = "";
          //         phone = "";
          //       });
          //       //Navigator.pop(context);
          //     }).onError((error, stackTrace) {
          //       clearControllers();

          //       setState(() {
          //         loading = false;
          //         Fluttertoast.showToast(
          //             msg: error.toString().contains("]")
          //                              ? "${error.toString().split("]").second}"
          //                              : error.toString(),
          //             toastLength: Toast.LENGTH_LONG);
          //       });
          //     });
          //   });
          // });
        }
      }
    }
    if (!mounted) return;
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !loading && !comfirmEmail,
      onPopInvoked: (pop) async {
        if (comfirmEmail) {
          setState(() {
            comfirmEmail = false;
          });
        }
      },
      child: SafeArea(
        child: Scaffold(
          extendBody: true,
          body: Center(
            child: SizedBox(
              width: 350,
              child: comfirmEmail
                  ? Center(
                      child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                              style: const TextStyle(fontSize: 18),
                              text:
                                  "A comfirmation link has been sent to your mail. Click to comfirm. ",
                              children: [
                                TextSpan(
                                    text: "Resend",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        fm
                                            .sendEmailVerification()
                                            .then((value) {
                                          Fluttertoast.showToast(
                                              msg:
                                                  "A comfirmation link has been sent to your mail. Click to comfirm");
                                          setState(() {
                                            comfirmEmail = false;
                                          });
                                        });
                                      }),
                              ])),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: SingleChildScrollView(
                            child: Form(
                              key: formStateKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      "Games Arena",
                                      style: GoogleFonts.merienda(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  if (!enterUsername) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          // horizontal: context.screenWidth
                                          //     .percentValue(5),
                                          vertical: 10),
                                      child: TextFormField(
                                        controller: emailController,
                                        validator: (string) {
                                          return fm.checkValidity(
                                              string?.trim() ?? "",
                                              "email",
                                              0,
                                              0,
                                              exists: emailExist);
                                        },
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                    color: darkMode
                                                        ? lightWhite
                                                        : lightBlack)),
                                            hintText: "Email"),
                                        onChanged: ((value) {
                                          email = value.trim();
                                        }),
                                      ),
                                    )
                                  ],
                                  if (!login &&
                                      !forgotPassword &&
                                      !enterUsername) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          // horizontal: context.screenWidth
                                          //     .percentValue(5),
                                          vertical: 10),
                                      child: TextFormField(
                                        controller: usernameController,
                                        validator: (string) {
                                          return fm.checkValidity(
                                              string?.trim() ?? "",
                                              "username",
                                              6,
                                              20,
                                              exists: usernameExist);
                                        },
                                        keyboardType: TextInputType.text,
                                        decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                    color: darkMode
                                                        ? lightWhite
                                                        : lightBlack)),
                                            hintText: "Username"),
                                        onChanged: ((value) {
                                          username = value.trim();
                                        }),
                                      ),
                                    ),
                                    if (!enterUsername) ...[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            // horizontal: context.screenWidth
                                            //     .percentValue(5),
                                            vertical: 10),
                                        child: TextFormField(
                                          controller: phoneController,
                                          validator: (string) {
                                            return fm.checkValidity(
                                                string?.trim() ?? "",
                                                "phone",
                                                6,
                                                20);
                                          },
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                      color: darkMode
                                                          ? lightWhite
                                                          : lightBlack)),
                                              hintText: "Phone"),
                                          onChanged: ((value) {
                                            phone = value.trim();
                                          }),
                                        ),
                                      ),
                                    ]
                                  ],
                                  if (!forgotPassword && !enterUsername) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          // horizontal: context.screenWidth
                                          //     .percentValue(5),
                                          vertical: 10),
                                      child: TextFormField(
                                        controller: passwordController,
                                        validator: (string) {
                                          return fm.checkValidity(
                                              string?.trim() ?? "",
                                              "password",
                                              6,
                                              30);
                                        },
                                        obscureText: !showPassword,
                                        decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                  color: darkMode
                                                      ? lightWhite
                                                      : lightBlack),
                                            ),
                                            hintText: "Password",
                                            suffix: GestureDetector(
                                              child: Text(
                                                showPassword ? "Hide" : "Show",
                                                style: const TextStyle(
                                                    color: Colors.blue),
                                              ),
                                              onTap: () {
                                                setState(() {
                                                  showPassword = !showPassword;
                                                });
                                              },
                                            )),
                                        onChanged: ((value) {
                                          password = value.trim();
                                        }),
                                      ),
                                    ),
                                  ],
                                  if (!login &&
                                      !forgotPassword &&
                                      !enterUsername) ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            }),
                                        // const SizedBox(
                                        //   width: 4,
                                        // ),
                                        TextButton(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const AppInfoPage(
                                                            type:
                                                                "Terms and Conditions and Privacy Policy",
                                                          )));
                                            },
                                            child: const Text(
                                              "Accept Terms, Conditions and Privacy Policy",
                                              style:
                                                  TextStyle(color: Colors.blue),
                                            ))
                                      ],
                                    )
                                  ],
                                  ActionButton(
                                      login
                                          ? "Login"
                                          : forgotPassword
                                              ? "Send Password Reset Email"
                                              : "Sign Up",
                                      onPressed: loginOrSignUp,
                                      disabled: !(login ||
                                          enterUsername ||
                                          forgotPassword ||
                                          acceptTerms),
                                      disabledColor: darkMode
                                          ? lightestWhite
                                          : lightestBlack,
                                      height: 50),
                                  // if (login) ...[
                                  ActionButton("Login with Gmail",
                                      outline: true,
                                      color: const Color(0xffDB4437),
                                      onPressed: () {
                                    googleSignIn();
                                  }),
                                  //],
                                  if (login) ...[
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          forgotPassword = true;
                                          login = false;
                                        });
                                      },
                                      child: const Text(
                                        "Forgot Password",
                                        style: TextStyle(color: primaryColor),
                                      ),
                                    ),
                                  ],
                                  if (login) ...[
                                    // const SizedBox(
                                    //   height: 4,
                                    // ),

                                    // GestureDetector(
                                    //   onTap: () {
                                    //     fm.signInWithGoogle().then((cred) async {
                                    //       final user = cred.user!;
                                    //       final userId = user.uid;
                                    //       final userData = await getUser(userId);
                                    //       email = user.email!;
                                    //       username = user.displayName!
                                    //           .replaceAll(" ", "")
                                    //           .toLowerCase();
                                    //       phone = user.phoneNumber!;
                                    //       if (userData != null) {
                                    //         gotoHomePage();
                                    //       } else {
                                    //         setState(() {
                                    //           loading = false;
                                    //           enterUsername = true;
                                    //         });
                                    //       }
                                    //     }).onError((error, stackTrace) {
                                    //       Fluttertoast.showToast(
                                    //           msg: error.toString().contains("]")
                                    //               ? "${error.toString().split("]").second}"
                                    //               : error.toString());
                                    //     });
                                    //   },
                                    //   child: SvgPicture.asset(
                                    //     "assets/icons/gmail_icon_round.svg",
                                    //     width: 60,
                                    //     height: 60,
                                    //     color: Color(0xffDB4437),
                                    //   ),
                                    // child: Row(
                                    //   crossAxisAlignment: CrossAxisAlignment.center,
                                    //   mainAxisAlignment: MainAxisAlignment.center,
                                    //   children: [
                                    //     SvgPicture.asset(
                                    //       "assets/icons/gmail_icon.svg",
                                    //       width: 20,
                                    //       height: 20,
                                    //     ),
                                    //     const SizedBox(
                                    //       width: 2,
                                    //     ),
                                    //     const Text(
                                    //       "Login with Gmail",
                                    //       style: TextStyle(color: Colors.blue),
                                    //     )
                                    //   ],
                                    // ),
                                    //)
                                  ]
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (loading || enterUsername) ...[
                          Container(
                            height: double.infinity,
                            width: double.infinity,
                            color: Colors.black.withOpacity(0.5),
                            alignment: Alignment.center,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  Text(
                                    forgotPassword
                                        ? "Sending Password Reset Email"
                                        : login
                                            ? "Logging in"
                                            : "Signing up",
                                    style: const TextStyle(color: Colors.white),
                                  )
                                ]),
                          )
                        ],
                      ],
                    ),
            ),
          ),
          bottomNavigationBar: loading
              ? null
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                          text: login
                              ? "Don't have an account? "
                              : "Already have an account? ",
                          style: TextStyle(
                              color: darkMode ? lightWhite : lightBlack),
                          children: [
                            TextSpan(
                                text: login ? "Sign Up" : "Login",
                                style: const TextStyle(color: primaryColor),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    setState(() {
                                      forgotPassword = false;
                                      login = !login;
                                    });
                                  }),
                          ])),
                ),
        ),
      ),
    );
  }

  void clearControllers() {
    showPassword = false;
    usernameController.clear();
    emailController.clear();
    phoneController.clear();
    passwordController.clear();
  }

  bool _onKey(KeyEvent event) {
    final key = event.logicalKey;
    if (event is KeyDownEvent) {
      if (key == LogicalKeyboardKey.enter) {
        loginOrSignUp();
      }
    }
    return false;
  }
}
