import 'package:gamesarena/features/game/services.dart';
import 'package:gamesarena/shared/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gamesarena/shared/widgets/app_appbar.dart';
import 'package:gamesarena/shared/widgets/app_text_field.dart';
import '../../../shared/extensions/special_context_extensions.dart';
import '../../../shared/views/loading_overlay.dart';
import '../../../shared/widgets/app_button.dart';
import '../../user/services.dart';
import '../../user/widgets/user_item.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../theme/colors.dart';
import '../../../shared/utils/utils.dart';
import '../services.dart';

class NewGroupPage extends StatefulWidget {
  final List<User> users;
  const NewGroupPage({super.key, required this.users});

  @override
  State<NewGroupPage> createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {
  TextEditingController controller = TextEditingController();
  String gameId = "";
  bool creating = false;
  GlobalKey<FormState> formFieldStateKey = GlobalKey();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void createGroup() async {
    if (!(formFieldStateKey.currentState?.validate() ?? false)) return;
    final groupname = controller.text;

    if (creating) return;
    if (groupname.isEmpty) {
      showToast("Group name is required");
      return;
    }
    showLoading(message: "Creating group...");
    setState(() {
      creating = true;
    });
    try {
      await createGameGroup(
          groupname, widget.users.map((e) => e.user_id).toList());
      await hideDialog();

      if (!mounted) return;

      context.pop(true);
    } catch (e) {
      setState(() {
        creating = false;
      });
      hideDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: "New Group", subtitle: "Enter Group name"),
      body: LoadingOverlay(
        // loading: creating,
        loading: false,
        child: Form(
          key: formFieldStateKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppTextField(controller: controller, hintText: "Groupname"),
                const SizedBox(height: 8),
                Text(
                  "${widget.users.length} Players",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4),
                      shrinkWrap: true,
                      //padding: const EdgeInsets.all(16),
                      itemCount: widget.users.length,
                      itemBuilder: (context, index) {
                        final user = widget.users[index];
                        return UserItem(
                          user: user,
                          type: "",
                          onPressed: () {},
                        );
                      }),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppButton(
        title: "Create",
        onPressed: createGroup,
      ),
    );
  }
}
