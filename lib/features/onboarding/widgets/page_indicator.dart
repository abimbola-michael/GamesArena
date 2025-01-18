import 'package:flutter/material.dart';

import '../../../shared/widgets/app_container.dart';
import '../../../theme/colors.dart';

class PageIndicator extends StatelessWidget {
  final int page;
  final int pageCount;
  final Color? color;
  final Color? unselectedColor;
  const PageIndicator(
      {super.key,
      required this.page,
      required this.pageCount,
      this.color,
      this.unselectedColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(pageCount, (index) {
        return AppContainer(
          color: page == index
              ? (color ?? primaryColor)
              : (unselectedColor ?? (color ?? lighterTint)),
          height: 8,
          width: page == index ? 30 : 10,
          borderRadius: BorderRadius.circular(4),
          margin: const EdgeInsets.symmetric(horizontal: 4),
        );
      }),
    );
  }
}
