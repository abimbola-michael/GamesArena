import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../widgets/app_container.dart';
//import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool loading;
  final bool hideChild;
  const LoadingOverlay(
      {super.key,
      required this.child,
      required this.loading,
      this.hideChild = false});

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      color: loading ? lighterBlack : transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!hideChild || !loading) Positioned.fill(child: child),
          if (loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
