import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gamesarena/blocs/firebase_methods.dart';
import 'package:gamesarena/components/components.dart';
import 'package:gamesarena/extensions/extensions.dart';
import 'package:gamesarena/pages/app_info_page.dart';
import 'package:gamesarena/pages/pages.dart';
import 'package:gamesarena/styles/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/models/user.dart' as myUser;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../blocs/firebase_service.dart';
import '../utils/utils.dart';

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
  FirebaseService fs = FirebaseService();
  String timeNow = DateTime.now().millisecondsSinceEpoch.toString();
  bool usernameExist = false, emailExist = false;
  GlobalKey<FormState> formStateKey = GlobalKey<FormState>();
  bool showPassword = false;
  bool acceptTerms = false;
  bool enterUsername = false;
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
    if (kIsWeb) ServicesBinding.instance.keyboard.addHandler(_onKey);
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

  Future createAccount(bool isGmailLogin) async {
    if (email.isNotEmpty) {
      emailExist = await fm.checkIfEmailExists(email);
    }
    if (username.isNotEmpty) {
      usernameExist = await fm.checkIfUsernameExists(username);
    }
    if (emailExist || usernameExist) {
      setState(() {
        loading = false;
      });
      return;
    }
    fm.createAccount(email, password).then((value) async {
      if (!isGmailLogin) {
        try {
          await fm.sendEmailVerification();
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
        await fs.createUser(user);
      }
    }).onError((error, stackTrace) {
      Fluttertoast.showToast(
          msg: error.toString().contains("]")
              ? "${error.toString().split("]").second}"
              : error.toString());
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
    setState(() {
      emailExist = false;
      usernameExist = false;
    });
    if (formStateKey.currentState?.validate() ?? false) {
      setState(() {
        loading = true;
      });
      if (enterUsername) {
        createAccount(true).then((value) {
          gotoHomePage();
        });
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
              //   final key = await fs.getPrivateKey();
              //   if (key == null) return;
              //   String vapidKey = key.vapidKey;
              //   token = await FirebaseMessaging.instance
              //       .getToken(vapidKey: vapidKey);
              // } else {
              //   token = await FirebaseMessaging.instance
              //       .getToken();
              // }
              // if (token != null) {
              //   fs.updateToken(token);
              // }
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
          emailExist = await fm.checkIfEmailExists(email);
          usernameExist = await fm.checkIfUsernameExists(username);
          if (emailExist || usernameExist) {
            final existMessage = (emailExist && usernameExist)
                ? "Username and Email"
                : emailExist
                    ? "Email"
                    : "Username";
            Fluttertoast.showToast(
                msg: "$existMessage already exist",
                toastLength: Toast.LENGTH_LONG);
            setState(() {
              loading = false;
            });
            return;
          }
          await createAccount(false);
          clearControllers();
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
          //       await fs.createUser(user);
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
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !loading,
      onPopInvoked: (pop) async {},
      child: SafeArea(
        child: Scaffold(
          extendBody: true,
          body: Stack(
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
                                fontSize: 30, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        if (!enterUsername) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: context.screenWidth.percentValue(5),
                                vertical: 10),
                            child: TextFormField(
                              controller: emailController,
                              validator: (string) {
                                return fm.checkValidity(
                                    string?.trim() ?? "", "email", 0, 0,
                                    exists: emailExist);
                              },
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
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
                        if (!login && !forgotPassword && !enterUsername) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: context.screenWidth.percentValue(5),
                                vertical: 10),
                            child: TextFormField(
                              controller: usernameController,
                              validator: (string) {
                                return fm.checkValidity(
                                    string?.trim() ?? "", "username", 6, 20,
                                    exists: usernameExist);
                              },
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
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
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      context.screenWidth.percentValue(5),
                                  vertical: 10),
                              child: TextFormField(
                                controller: phoneController,
                                validator: (string) {
                                  return fm.checkValidity(
                                      string?.trim() ?? "", "phone", 6, 20);
                                },
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
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
                            padding: EdgeInsets.symmetric(
                                horizontal: context.screenWidth.percentValue(5),
                                vertical: 10),
                            child: TextFormField(
                              controller: passwordController,
                              validator: (string) {
                                return fm.checkValidity(
                                    string?.trim() ?? "", "password", 6, 30);
                              },
                              obscureText: !showPassword,
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color:
                                            darkMode ? lightWhite : lightBlack),
                                  ),
                                  hintText: "Password",
                                  suffix: GestureDetector(
                                    child: Text(
                                      showPassword ? "Hide" : "Show",
                                      style:
                                          const TextStyle(color: Colors.blue),
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
                        if (!login && !forgotPassword && !enterUsername) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                    style: TextStyle(color: Colors.blue),
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
                            disabledColor:
                                darkMode ? lightestWhite : lightestBlack,
                            height: 50),
                        // if (login) ...[
                        //   ActionButton("Login with Gmail", outline: true,
                        //       //color: Color(0xffDB4437),
                        //       onPressed: () {
                        //     fm.signInWithGoogle().then((cred) async {
                        //       if (cred.user == null) {
                        //         Fluttertoast.showToast(msg: "Login Failed");
                        //         return;
                        //       }
                        //       final user = cred.user!;
                        //       final userId = user.uid;
                        //       final userData = await fs.getUser(userId);
                        //       email = user.email ?? "";
                        //       username = user.displayName?.trim() ??
                        //           "".replaceAll(" ", "").toLowerCase();
                        //       phone = user.phoneNumber?.trim() ?? "";
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
                        //   }),
                        // ],
                        if (login) ...[
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                forgotPassword = true;
                                login = false;
                              });
                            },
                            child: Text(
                              "Forgot Password",
                              style: TextStyle(color: appColor),
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
                          //       final userData = await fs.getUser(userId);
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
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                                style: TextStyle(color: appColor),
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
