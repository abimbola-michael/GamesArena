import 'package:flutter/material.dart';
import 'package:gamesarena/shared/widgets/app_appbar.dart';

class AddAppMessagePage extends StatefulWidget {
  const AddAppMessagePage({super.key});

  @override
  State<AddAppMessagePage> createState() => _AddAppMessagePageState();
}

class _AddAppMessagePageState extends State<AddAppMessagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: "App Infos"),
      //body: ,
    );
  }
}
