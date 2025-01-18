import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/theme/colors.dart';

class LoadingView extends StatelessWidget {
  final bool transparent;
  final String? message;
  const LoadingView({super.key, this.message, this.transparent = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: transparent ? Colors.black.withOpacity(0.3) : context.bgColor,
      alignment: Alignment.center,
      child: SizedBox(
        width: 350,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(
                height: 2,
              ),
              Text(
                message!,
                style: context.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
