import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gamesarena/core/firebase/firebase_methods.dart';
import 'package:gamesarena/theme/colors.dart';

import '../../../shared/widgets/action_button.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late TextEditingController emailController;
  FirebaseMethods fm = FirebaseMethods();
  String email = "";

  @override
  void initState() {
    emailController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: TextFormField(
              controller: emailController,
              validator: (string) {
                return fm.checkValidity(string?.trim() ?? "", "email", 0, 0,
                    exists: false);
              },
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: lightTint)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  hintText: "Email"),
              onChanged: ((value) {
                email = value.trim();
              }),
            ),
          ),
          ActionButton(
            "Send Password Reset Email",
            onPressed: () {
              fm.sendPasswordResetEmail(email).then((value) {
                Fluttertoast.showToast(
                    msg: "Email sent, Check your inbox to reset your password");
                Navigator.of(context).pop();
              }).onError((error, stackTrace) {
                Fluttertoast.showToast(
                    msg: "Something went wrong. Unable to send email");
              });
            },
            height: 60,
          )
        ],
      ),
    );
  }
}
