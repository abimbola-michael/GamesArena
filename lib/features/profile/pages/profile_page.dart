import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:gamesarena/features/game/services.dart';
import 'package:gamesarena/features/profile/pages/edit_profile_page.dart';
import 'package:gamesarena/features/profile/services.dart';
import 'package:gamesarena/features/profile/widgets/profile_option_item.dart';
import 'package:gamesarena/features/records/utils/utils.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/widgets/app_appbar.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/auth_methods.dart';
import '../../../core/firebase/firebase_methods.dart';
import '../../../core/firebase/firestore_methods.dart';
import '../../../core/firebase/storage_methods.dart';
import '../../../shared/dialogs/comfirmation_dialog.dart';
import '../../../shared/extensions/special_context_extensions.dart';
import '../../../shared/services.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../theme/colors.dart';
import '../../../shared/utils/utils.dart';
import '../../game/widgets/profile_photo.dart';
import '../../group/services.dart';
import '../../onboarding/pages/auth_page.dart';
import '../../onboarding/services.dart';
import '../../settings/pages/settings_and_more_page.dart';
import '../../user/models/user_game.dart';
import '../../user/services.dart';
import 'user_games_selection_page.dart';

class ProfilePage extends StatefulWidget {
  final String id;
  final String? profilePhoto;
  final String? name;
  final List<String>? games;

  // final List<UserGame>? games;
  final bool isGroup;
  final bool canEditGroup;
  const ProfilePage(
      {super.key,
      required this.id,
      this.name,
      this.profilePhoto,
      this.games,
      this.isGroup = false,
      this.canEditGroup = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<String> games = [];
  String name = "", email = "", phone = "", profilePhoto = "";
  String id = "";
  AuthMethods am = AuthMethods();
  StorageMethods sm = StorageMethods();
  late List<String> options = widget.isGroup
      ? ["Groupname"]
      : ["Username", "Email", "Phone", "Password"];
  BuildContext? bottomSheetContext;

  GlobalKey<ScaffoldState> scaffoldStateKey = GlobalKey<ScaffoldState>();
  String? filePath;
  XFile? imageFile;
  bool uploading = false;
  bool removing = false;

  @override
  void initState() {
    super.initState();
    id = widget.id;

    if (widget.profilePhoto != null) {
      profilePhoto = widget.profilePhoto!;
    }
    if (widget.name != null) {
      name = widget.name!;
    }
    if (widget.games != null) {
      games = widget.games!;
    }
    if (!widget.isGroup) {
      readUser();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        filePath = file.path;
      });
    }
  }

  void removePhoto() async {
    setState(() {
      removing = true;
    });
    await removeProfilePhoto();
    setState(() {
      removing = false;
      profilePhoto = "";
      filePath = null;
    });
  }

  void uploadPhoto() {
    if (filePath == null) return;
    setState(() {
      uploading = true;
    });
    sm.uploadFile(["users", myId, "profile_photo"], filePath!, "photo",
        onComplete: (url, thumbnail) async {
      await updateProfilePhoto(url);
      setState(() {
        profilePhoto = url;
        uploading = false;
        filePath = null;
      });
    });
  }

  void gotoEditProfilePage(String type, String value) async {
    final newValue = await context.pushTo(EditProfilePage(
        type: type, value: value, groupId: widget.isGroup ? widget.id : null));
    if (newValue != null) {
      if (type == "username" || type == "groupname") {
        name = newValue;
      } else if (type == "email") {
        email = newValue;
      } else if (type == "phone") {
        phone = newValue;
      }
      setState(() {});
    }
  }

  Future logout() async {
    final comfirm = await context.showComfirmationDialog(
        title: "Logout", message: "Are you sure you want to logout?");
    if (comfirm == null) return;

    try {
      showLoading(message: "Logging out...");
      await logoutUser();
      await am.logOut();
      gotoStartPage();
    } catch (e) {
      print("logoutError = $e");
      showErrorToast("Unable to logout ");
    }
  }

  void gotoStartPage() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: ((context) => const AuthPage())),
        (route) => false);
  }

  void readUser() async {
    final user = await getUser(id);
    if (user != null) {
      name = user.username;
      email = user.email;
      phone = user.phone;
      profilePhoto = user.profile_photo ?? "";
      games = user.games ?? [];
    }
    print("user = $user");
    setState(() {});
  }

  // void readGroup() async {
  //   final group = await getGroup(id);
  //   if (group != null) {
  //     name = group.groupname;
  //     //profilePhoto = group.pr
  //   }
  //   setState(() {});
  // }

  void gotoSettingPage() {
    context.pushTo(const SettingsAndMorePage());
  }

  void gotoUserGamesSeletionPage() async {
    final newGames = await context.pushTo(UserGamesSelectionPage(
        gameId: widget.isGroup ? widget.id : null, games: games));
    if (newGames != null) {
      games = newGames;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    print("games = ${games}");
    return Scaffold(
      key: scaffoldStateKey,
      // extendBodyBehindAppBar: true,
      appBar: AppAppBar(
          title: widget.isGroup ? "Group Profile" : "Profile",
          trailing: widget.id == myId
              ? IconButton(
                  onPressed: gotoSettingPage,
                  icon: const Icon(EvaIcons.settings_2_outline))
              : null),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            filePath != null
                ? CircleAvatar(
                    radius: 100,
                    backgroundImage: FileImage(File(filePath!)),
                  )
                : ProfilePhoto(
                    profilePhoto: profilePhoto,
                    name: name,
                    size: 100,
                  ),

            const SizedBox(height: 10),
            // if (widget.id == myId || widget.isGroup)  ...[
            //   Row(
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       if (profilePhoto.isNotEmpty) ...[
            //         if (removing)
            //           const CircularProgressIndicator()
            //         else
            //           AppButton(
            //             title: "Remove Photo",
            //             wrapped: true,
            //             bgColor: lightestTint,
            //             color: tint,
            //             onPressed: removePhoto,
            //           ),
            //         const SizedBox(width: 10),
            //       ],
            //       AppButton(
            //         title: "Add Photo",
            //         wrapped: true,
            //         onPressed: pickPhoto,
            //       ),
            //       if (filePath != null) ...[
            //         const SizedBox(width: 10),
            //         if (uploading)
            //           const CircularProgressIndicator()
            //         else
            //           AppButton(
            //             title: "Upload Photo",
            //             wrapped: true,
            //             bgColor: lightestTint,
            //             color: tint,
            //             onPressed: uploadPhoto,
            //           ),
            //         const SizedBox(width: 10),
            //       ],
            //     ],
            //   ),
            //   const SizedBox(
            //     height: 16,
            //   ),
            // ],
            ProfileOptionItem(
              title: widget.isGroup ? "Groupname" : "Username",
              value: name,
              editable: widget.id == myId || widget.canEditGroup,
              onEdit: () => gotoEditProfilePage(
                  widget.isGroup ? "groupname" : "username", name),
            ),

            ProfileOptionItem(
              title: "Games",
              value: getGamesString(games),
              editable: widget.id == myId || widget.canEditGroup,
              onEdit: gotoUserGamesSeletionPage,
            ),
          ],
        ),
      ),
      bottomNavigationBar: id != myId
          ? null
          : AppButton(
              title: "Logout",
              onPressed: logout,
              bgColor: Colors.red,
              color: Colors.white,
            ),
    );
  }
}
