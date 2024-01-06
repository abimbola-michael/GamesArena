// import 'package:flutter/foundation.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:gamesarena/blocs/firebase_methods.dart';
// import 'package:gamesarena/components/components.dart';
// import 'package:gamesarena/extensions/extensions.dart';
// import 'package:gamesarena/pages/app_info_page.dart';
// import 'package:gamesarena/pages/pages.dart';
// import 'package:gamesarena/pages/reset_password_page.dart';
// import 'package:gamesarena/styles/colors.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:gamesarena/models/user.dart' as myUser;
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// import '../blocs/firebase_service.dart';

// class LoginPage extends StatefulWidget {
//   final bool login;
//   const LoginPage({super.key, required this.login});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   bool login = false;
//   bool loading = false;
//   String username = "", phone = "", email = "", password = "";
//   FirebaseMethods fm = FirebaseMethods();
//   FirebaseService fs = FirebaseService();
//   String timeNow = DateTime.now().millisecondsSinceEpoch.toString();
//   bool usernameExist = false, emailExist = false;
//   GlobalKey<FormState> formStateKey = GlobalKey<FormState>();
//   bool showPassword = false;
//   bool acceptTerms = false;
//   bool enterUsername = false;
//   late TextEditingController usernameController,
//       emailController,
//       passwordController,
//       phoneController;

//   @override
//   void initState() {
//     super.initState();
//     login = widget.login;
//     usernameController = TextEditingController();
//     emailController = TextEditingController();
//     phoneController = TextEditingController();
//     passwordController = TextEditingController();
//   }

//   @override
//   void dispose() {
//     usernameController.dispose();
//     emailController.dispose();
//     phoneController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }

//   Future createAccount(bool isGmailLogin) async {
//     if (email.isNotEmpty) {
//       emailExist = await fm.checkIfEmailExists(email);
//     }
//     if (username.isNotEmpty) {
//       usernameExist = await fm.checkIfUsernameExists(username);
//     }
//     if (emailExist || usernameExist) {
//       setState(() {
//         loading = false;
//       });
//       return;
//     }
//     fm.createAccount(email, password).then((value) async {
//       if (!isGmailLogin) {
//         try {
//           await fm.sendEmailVerification();
//         } on Exception catch (e) {}
//       }
//       final currentuser = FirebaseAuth.instance.currentUser;
//       await fm.setValue(["usernames", username], value: {"username": username});
//       if (currentuser != null) {
//         final user = myUser.User(
//           email: email,
//           user_id: currentuser.uid,
//           username: username,
//           phone: phone,
//           time: timeNow,
//           last_seen: timeNow,
//         );
//         await currentuser.updateDisplayName(username);
//         await fs.createUser(user);
//       }
//     }).onError((error, stackTrace) {
//       Fluttertoast.showToast(msg: "${error.toString().split("]").second}");
//       setState(() {
//         loading = false;
//       });
//     });
//   }

//   void gotoHomePage() {
//     Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: ((context) => const HomePage())),
//         (route) => false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         return !loading;
//       },
//       child: SafeArea(
//         child: Scaffold(
//           extendBody: true,
//           body: Stack(
//             fit: StackFit.expand,
//             alignment: Alignment.center,
//             children: [
//               Center(
//                 child: SingleChildScrollView(
//                   child: Form(
//                     key: formStateKey,
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Text(
//                             "Games Arena",
//                             style: GoogleFonts.merienda(
//                                 fontSize: 35, fontWeight: FontWeight.bold),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                         const SizedBox(
//                           height: 20,
//                         ),
//                         if (!enterUsername) ...[
//                           Padding(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 20.0, vertical: 10),
//                             child: TextFormField(
//                               controller: emailController,
//                               validator: (string) {
//                                 return fm.checkValidity(
//                                     string?.trim() ?? "", "email", 0, 0,
//                                     exists: emailExist);
//                               },
//                               keyboardType: TextInputType.emailAddress,
//                               decoration: InputDecoration(
//                                   border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(10),
//                                       borderSide:
//                                           BorderSide(color: tintColorLight)),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide:
//                                         const BorderSide(color: Colors.blue),
//                                   ),
//                                   hintText: "Email"),
//                               onChanged: ((value) {
//                                 email = value.trim();
//                               }),
//                             ),
//                           ),
//                         ],
//                         if (!login || enterUsername) ...[
//                           Padding(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 20.0, vertical: 10),
//                             child: TextFormField(
//                               controller: usernameController,
//                               validator: (string) {
//                                 return fm.checkValidity(
//                                     string?.trim() ?? "", "username", 4, 25,
//                                     exists: usernameExist);
//                               },
//                               keyboardType: TextInputType.text,
//                               decoration: InputDecoration(
//                                   border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(10),
//                                       borderSide:
//                                           BorderSide(color: tintColorLight)),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide:
//                                         const BorderSide(color: Colors.blue),
//                                   ),
//                                   hintText: "Username"),
//                               onChanged: ((value) {
//                                 username = value.trim();
//                               }),
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 20.0, vertical: 10),
//                             child: TextFormField(
//                               controller: phoneController,
//                               validator: (string) {
//                                 return fm.checkValidity(
//                                     string?.trim() ?? "", "phone", 6, 20);
//                               },
//                               keyboardType: TextInputType.number,
//                               decoration: InputDecoration(
//                                   border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(10),
//                                       borderSide:
//                                           BorderSide(color: tintColorLight)),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide:
//                                         const BorderSide(color: Colors.blue),
//                                   ),
//                                   hintText: "Phone"),
//                               onChanged: ((value) {
//                                 phone = value.trim();
//                               }),
//                             ),
//                           ),
//                         ],
//                         if (!enterUsername) ...[
//                           Padding(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 20.0, vertical: 10),
//                             child: TextFormField(
//                               controller: passwordController,
//                               validator: (string) {
//                                 return fm.checkValidity(
//                                     string?.trim() ?? "", "password", 6, 30);
//                               },
//                               obscureText: !showPassword,
//                               decoration: InputDecoration(
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide:
//                                         BorderSide(color: tintColorLight),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide:
//                                         const BorderSide(color: Colors.blue),
//                                   ),
//                                   hintText: "Password",
//                                   suffix: GestureDetector(
//                                     child: Text(
//                                       showPassword ? "Hide" : "Show",
//                                       style:
//                                           const TextStyle(color: Colors.blue),
//                                     ),
//                                     onTap: () {
//                                       setState(() {
//                                         showPassword = !showPassword;
//                                       });
//                                     },
//                                   )),
//                               onChanged: ((value) {
//                                 password = value.trim();
//                               }),
//                             ),
//                           ),
//                         ],
//                         if (!login) ...[
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Checkbox(
//                                   activeColor: Colors.blue,
//                                   value: acceptTerms,
//                                   onChanged: (value) {
//                                     setState(() {
//                                       if (value != null) {
//                                         acceptTerms = value;
//                                       }
//                                     });
//                                   }),
//                               // const SizedBox(
//                               //   width: 4,
//                               // ),
//                               TextButton(
//                                   onPressed: () {
//                                     Navigator.of(context).push(
//                                         MaterialPageRoute(
//                                             builder: (context) =>
//                                                 const AppInfoPage(
//                                                   type:
//                                                       "Terms and Conditions and Privacy Policy",
//                                                 )));
//                                   },
//                                   child: const Text(
//                                     "Accept Terms, Conditions and Privacy Policy",
//                                     style: TextStyle(color: Colors.blue),
//                                   ))
//                             ],
//                           )
//                         ],
//                         if (login) ...[
//                           TextButton(
//                               onPressed: () {
//                                 Navigator.of(context).push(MaterialPageRoute(
//                                     builder: (context) =>
//                                         const ResetPasswordPage()));
//                               },
//                               child: const Text(
//                                 "Forgot Password",
//                                 style: TextStyle(color: Colors.blue),
//                               ))
//                         ],
//                         ActionButton(
//                             disabled: !(login || acceptTerms),
//                             disabledColor: tintColorLightest,
//                             login ? "Login" : "Sign Up", onPressed: () async {
//                           if (formStateKey.currentState?.validate() ?? false) {
//                             setState(() {
//                               loading = true;
//                             });

//                             if (login) {
//                               if (enterUsername) {
//                                 createAccount(true).then((value) {
//                                   gotoHomePage();
//                                 });
//                                 return;
//                               }
//                               fm.signIn(email, password).then((value) async {
//                                 clearControllers();

//                                 final emailVerified =
//                                     await fm.isEmailVerified();
//                                 if (!emailVerified) {
//                                   loading = false;
//                                   Fluttertoast.showToast(
//                                       msg:
//                                           "Email Not Verified. \n Check your mail");
//                                   fm.logOut().then((value) {
//                                     //Navigator.pop(context);
//                                     setState(() {
//                                       login = true;
//                                       username = "";
//                                       email = "";
//                                       password = "";
//                                       phone = "";
//                                     });
//                                   });
//                                 } else {
//                                   gotoHomePage();
//                                 }
//                               }).onError((error, stackTrace) {
//                                 clearControllers();
//                                 Fluttertoast.showToast(
//                                     msg:
//                                         "${error.toString().split("]").second}");
//                                 setState(() {
//                                   loading = false;
//                                 });
//                               });
//                             } else {
//                               emailExist = await fm.checkIfEmailExists(email);
//                               usernameExist =
//                                   await fm.checkIfUsernameExists(username);
//                               if (emailExist || usernameExist) {
//                                 setState(() {
//                                   loading = false;
//                                 });
//                                 return;
//                               }
//                               createAccount(false).then((value) {
//                                 clearControllers();
//                                 Fluttertoast.showToast(
//                                     msg:
//                                         "A comfirmation email has been sent to you. \n Check your mail");
//                                 fm.logOut().then((value) {
//                                   setState(() {
//                                     loading = false;
//                                     login = true;
//                                     username = "";
//                                     email = "";
//                                     password = "";
//                                     phone = "";
//                                   });
//                                   //Navigator.pop(context);
//                                 }).onError((error, stackTrace) {
//                                   Fluttertoast.showToast(
//                                       msg:
//                                           "${error.toString().split("]").second}");
//                                   setState(() {
//                                     loading = false;
//                                   });
//                                 });
//                               });
//                               // fm.createAccount(email, password).then((value) {
//                               //   fm.sendEmailVerification().then((value) async {
//                               //     final currentuser =
//                               //         FirebaseAuth.instance.currentUser;
//                               //     await fm.setValue(["usernames", username],
//                               //         value: {"username": username});
//                               //     if (currentuser != null) {
//                               //       final user = myUser.User(
//                               //         email: email,
//                               //         user_id: currentuser.uid,
//                               //         username: username,
//                               //         phone: phone,
//                               //         time: timeNow,
//                               //         last_seen: timeNow,
//                               //       );
//                               //       await fs.createUser(user);
//                               //       clearControllers();
//                               //       Fluttertoast.showToast(
//                               //           msg:
//                               //               "A comfirmation email has been sent to you. \n Check your mail");
//                               //     }
//                               //     fm.logOut().then((value) {
//                               //       setState(() {
//                               //         loading = false;
//                               //         login = true;
//                               //         username = "";
//                               //         email = "";
//                               //         password = "";
//                               //         phone = "";
//                               //       });
//                               //       //Navigator.pop(context);
//                               //     }).onError((error, stackTrace) {
//                               //       clearControllers();
//                               //       Fluttertoast.showToast(
//                               //           msg:
//                               //               "${error.toString().split("]").second}");
//                               //       setState(() {
//                               //         loading = false;
//                               //       });
//                               //     });
//                               //   });
//                               // });
//                             }
//                           }
//                           FocusScope.of(context).unfocus();
//                         }, height: 60),
//                         if (login) ...[
//                           GestureDetector(
//                             onTap: () {
//                               fm.signInWithGoogle().then((cred) async {
//                                 final user = cred.user!;
//                                 final user_id = user.uid;
//                                 final userData = await fs.getUser(user_id);
//                                 email = user.email!;
//                                 username = user.displayName!
//                                     .replaceAll(" ", "")
//                                     .toLowerCase();
//                                 phone = user.phoneNumber!;
//                                 if (userData != null) {
//                                   gotoHomePage();
//                                 } else {
//                                   setState(() {
//                                     loading = false;
//                                     enterUsername = true;
//                                   });
//                                 }
//                               }).onError((error, stackTrace) {
//                                 Fluttertoast.showToast(
//                                     msg:
//                                         "${error.toString().split("]").second}");
//                               });
//                             },
//                             child: Row(
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 SvgPicture.asset(
//                                   "assets/icons/gmail_icon.svg",
//                                   width: 20,
//                                   height: 20,
//                                 ),
//                                 const SizedBox(
//                                   width: 2,
//                                 ),
//                                 const Text(
//                                   "Login with Gmail",
//                                   style: TextStyle(color: Colors.blue),
//                                 )
//                               ],
//                             ),
//                           )
//                         ]
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               if (loading) ...[
//                 Container(
//                   height: double.infinity,
//                   width: double.infinity,
//                   color: Colors.black.withOpacity(0.5),
//                   alignment: Alignment.center,
//                   child: Column(mainAxisSize: MainAxisSize.min, children: [
//                     const CircularProgressIndicator(),
//                     Text(
//                       login ? "Logging in" : "Signing up",
//                     )
//                   ]),
//                 )
//               ],
//             ],
//           ),
//           bottomNavigationBar: loading || enterUsername
//               ? null
//               : Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: RichText(
//                       textAlign: TextAlign.center,
//                       text: TextSpan(
//                           text: login
//                               ? "Don't have an account? "
//                               : "Already have an account? ",
//                           style: TextStyle(color: tintColor),
//                           children: [
//                             TextSpan(
//                                 text: login ? "Sign Up" : "Login",
//                                 style: TextStyle(color: appColor),
//                                 recognizer: TapGestureRecognizer()
//                                   ..onTap = () {
//                                     setState(() {
//                                       login = !login;
//                                     });
//                                   }),
//                           ])),
//                 ),
//         ),
//       ),
//     );
//   }

//   void clearControllers() {
//     showPassword = false;
//     usernameController.clear();
//     emailController.clear();
//     phoneController.clear();
//     passwordController.clear();
//   }
// }
