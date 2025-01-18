import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/utils/utils.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../theme/colors.dart';

class AppSearchBar extends StatefulWidget implements PreferredSizeWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onPressed;
  final VoidCallback? onCloseSearch;
  final VoidCallback? onPressedSearch;

  const AppSearchBar(
      {super.key,
      required this.hint,
      this.controller,
      this.onPressed,
      this.onCloseSearch,
      this.onPressedSearch,
      this.onChanged});

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();

  @override
  Size get preferredSize => Size.fromHeight(60 + statusBarHeight);
}

class _AppSearchBarState extends State<AppSearchBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60 + statusBarHeight,
      //left: 15, right: 15,
      padding: EdgeInsets.only(top: statusBarHeight),
      //margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),

      child: Container(
        decoration: BoxDecoration(
          //borderRadius: BorderRadius.circular(10),
          color: lightestTint,
        ),
        child: widget.controller != null || widget.onChanged != null
            ? Row(
                children: [
                  if (widget.onCloseSearch != null)
                    IconButton(
                      onPressed: widget.onCloseSearch,
                      icon: const Icon(EvaIcons.arrow_back_outline),
                      color: tint,
                    ),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      onTap: widget.onPressed,
                      controller: widget.controller,
                      onChanged: (value) {
                        setState(() {});
                        widget.onChanged?.call(value);
                      },
                      style: context.bodyMedium?.copyWith(color: tint),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: widget.hint,
                        hintStyle:
                            context.bodyMedium?.copyWith(color: lighterTint),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (widget.controller != null &&
                      widget.controller!.text.isNotEmpty) ...[
                    IconButton(
                      onPressed: () => widget.controller?.clear(),
                      icon: const Icon(EvaIcons.close_outline),
                      color: tint,
                    ),
                    if (widget.onPressedSearch != null)
                      IconButton(
                        onPressed: widget.onPressedSearch,
                        icon: const Icon(EvaIcons.checkmark),
                        color: tint,
                      ),
                  ],
                ],
              )
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onPressed,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    widget.hint,
                    style: context.bodyMedium?.copyWith(color: lighterTint),
                  ),
                ),
              ),
      ),
    );
  }

  // @override
  // Size get preferredSize => Size.fromHeight(60 + statusBarHeight);
}
