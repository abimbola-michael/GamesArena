// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../theme/colors.dart';
import '../utils/utils.dart';
import 'app_back_button.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;

  final Widget? trailing;
  final Widget? middle;
  final Widget? icon;

  final Widget? leading;
  final VoidCallback? onBackPressed;
  final bool hideBackButton;
  final Color? color;
  final TextStyle? style;
  const AppAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    this.onBackPressed,
    this.hideBackButton = false,
    this.leading,
    this.middle,
    this.icon,
    this.color,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60 + statusBarHeight,
      padding: EdgeInsets.only(top: statusBarHeight),
      child: SizedBox(
        height: 60,
        child: Stack(
          children: [
            if (middle != null)
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(left: 40, right: 90),
                  child: middle!,
                ),
              )
            else if (title != null)
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 70),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AutoSizeText(
                        title!,
                        style: style ??
                            context.headlineSmall
                                ?.copyWith(color: color, fontSize: 18),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        Text(
                          subtitle!,
                          style: context.bodySmall?.copyWith(color: color),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            if (!hideBackButton)
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    leading ??
                        AppBackButton(
                          onPressed: onBackPressed,
                          color: color,
                        ),
                    // IconButton(
                    //   onPressed: onBackPressed,
                    //   icon: Icon(EvaIcons.arrow_back_outline, color: tint),
                    // ),
                    if (icon != null) ...[const SizedBox(width: 4), icon!]
                  ],
                ),
              ),
            if (trailing != null)
              Align(
                alignment: Alignment.centerRight,
                child: trailing,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(60 + statusBarHeight);
}
