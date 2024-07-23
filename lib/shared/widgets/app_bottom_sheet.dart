import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../../theme/colors.dart';
import 'app_container.dart';

class AppBottomSheet extends StatelessWidget {
  final Widget child;
  const AppBottomSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        decoration: const BoxDecoration(
          color: white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppContainer(
              height: 4,
              width: 36,
              borderRadius: BorderRadius.circular(2),
              color: const Color(0xFfF2F2F2),
            ),
            const SizedBox(
              height: 10,
            ),
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: IconActionButton(
            //     onPressed: () {
            //       context.pop();
            //     },
            //     icon: "multiply",
            //     bgColor: closeOverlayColor,
            //     size: 15,
            //     radius: 15,
            //   ),
            // ),
            // const SizedBox(
            //   height: 10,
            // ),
            Flexible(
              flex: 1,
              child: SizedBox(
                width: double.infinity,
                child: child,
              ),
            ),
            // Flexible(
            //   flex: 1,
            //   child: SizedBox(
            //     width: double.infinity,
            //     child: SingleChildScrollView(
            //       child: child,
            //     ),
            //   ),
            // ),
            // const SizedBox(
            //   height: 30,
            // ),
          ],
        ));
  }
}
