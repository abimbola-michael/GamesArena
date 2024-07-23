// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../theme/colors.dart';
import 'app_icon_button.dart';
import 'app_svg_button.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  const AppBackButton({
    super.key,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      color: color,
      icon: EvaIcons.arrow_back_outline,
      onPressed: onPressed ?? () => context.pop(),
      bgColor: Colors.transparent,
      hideBackground: true,
      borderColor: color ?? lightestBlack,
    );
  }
}
