import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gamesarena/main.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/theme/colors.dart';

import '../dialogs/comfirmation_dialog.dart';
import '../dialogs/text_input_dialog.dart';
import '../views/error_or_success_view.dart';
import '../views/loading_view.dart';

enum DisplayType { dialog, bottomsheet, snackbar, toast }

enum DurationLength { long, short, veryLong, veryShort }

BuildContext? dialogContext;
bool loading = false;

Duration getDuration(DurationLength durationLength) {
  int seconds = 2;
  switch (durationLength) {
    case DurationLength.long:
      seconds = 4;
      break;
    case DurationLength.short:
      seconds = 2;
      break;
    case DurationLength.veryLong:
      seconds = 6;
      break;
    case DurationLength.veryShort:
      seconds = 1;
      break;
  }
  return Duration(seconds: seconds);
}

Future? showLoading(
    {bool transparent = true,
    Color? backgroundColor,
    String? message,
    Duration? duration,
    DisplayType displayType = DisplayType.dialog,
    DurationLength durationLength = DurationLength.short}) {
  return navigatorKey.currentContext?.showLoading(
      transparent: transparent,
      backgroundColor: backgroundColor,
      message: message,
      duration: duration,
      displayType: displayType,
      durationLength: durationLength);
}

Future? showMessage(String message,
    {String? action,
    Color? backgroundColor,
    Duration? duration,
    DisplayType displayType = DisplayType.dialog,
    VoidCallback? onPressed,
    bool isError = false,
    DurationLength durationLength = DurationLength.short}) {
  return navigatorKey.currentContext?.showMessage(
    message,
    action: action,
    backgroundColor: backgroundColor,
    duration: duration,
    displayType: displayType,
    onPressed: onPressed,
    isError: isError,
    durationLength: durationLength,
  );
}

Future? showToast(
  String message, {
  DurationLength durationLength = DurationLength.long,
  isError = false,
}) {
  return navigatorKey.currentContext
      ?.showToast(message, durationLength: durationLength, isError: isError);
}

Future? showErrorToast(String message,
    {DurationLength durationLength = DurationLength.long}) {
  return navigatorKey.currentContext
      ?.showErrorToast(message, durationLength: durationLength);
}

Future? showSuccessToast(String message,
    {DurationLength durationLength = DurationLength.long}) {
  return navigatorKey.currentContext
      ?.showSuccessToast(message, durationLength: durationLength);
}

Future? showSnackbar(String message,
    {DurationLength durationLength = DurationLength.long,
    String? action,
    VoidCallback? onPressed}) {
  return navigatorKey.currentContext?.showSnackbar(message,
      durationLength: durationLength, action: action, onPressed: onPressed);
}

Future? showErrorSnackbar(String message,
    {DurationLength durationLength = DurationLength.long,
    String? action,
    VoidCallback? onPressed}) {
  return navigatorKey.currentContext?.showErrorSnackbar(message,
      durationLength: durationLength, action: action, onPressed: onPressed);
}

Future? showSuccessSnackbar(String message,
    {DurationLength durationLength = DurationLength.long,
    String? action,
    VoidCallback? onPressed}) {
  return navigatorKey.currentContext?.showSuccessSnackbar(message,
      durationLength: durationLength, action: action, onPressed: onPressed);
}

Future? hideDialog() {
  return navigatorKey.currentContext?.hideDialog();
}

extension SpecialContextExtensions on BuildContext {
  Future showComfirmationDialog({
    required String title,
    String? message,
    List<String>? actions,
  }) {
    return showDialog(
        context: this,
        builder: (context) {
          return ComfirmationDialog(
              title: title, message: message, actions: actions);
        });
  }

  Future showTextInputDialog({
    required String title,
    String? message,
    String? hintText,
    List<String>? actions,
  }) {
    return showDialog(
        context: this,
        builder: (context) {
          return TextInputDialog(
              title: title,
              message: message,
              hintText: hintText,
              actions: actions);
        });
  }

  Future showLoading(
      {bool transparent = true,
      Color? backgroundColor,
      String? message,
      Duration? duration,
      DisplayType displayType = DisplayType.dialog,
      DurationLength durationLength = DurationLength.short}) async {
    if (!mounted) return;

    loading = true;

    if (duration != null &&
        (displayType == DisplayType.dialog ||
            displayType == DisplayType.bottomsheet)) {
      await Future.delayed(duration);
    }
    if (duration == null &&
        (displayType == DisplayType.toast ||
            displayType == DisplayType.snackbar)) {
      duration = getDuration(durationLength);
    }
    await hideDialog();

    dynamic result;
    if (displayType == DisplayType.dialog) {
      result = await showDialog(
        context: this,
        builder: (context) {
          dialogContext = context;
          return LoadingView(transparent: transparent, message: message);
        },
      );
    } else if (displayType == DisplayType.bottomsheet) {
      result = await showModalBottomSheet(
        backgroundColor: bgColor,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        context: this,
        builder: (context) {
          dialogContext = context;
          return LoadingView(transparent: transparent, message: message);
        },
      );
    } else if (displayType == DisplayType.snackbar) {
      result = ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(
          duration: duration!,
          content: Row(
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
              ),
              const SizedBox(
                width: 8,
              ),
              if (message != null)
                Text(
                  message,
                  style: bodySmall?.copyWith(color: white),
                ),
            ],
          ),
          backgroundColor: backgroundColor ?? primaryColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(this).removeCurrentSnackBar();
      result = ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(
          duration: duration!,
          backgroundColor: bgColor,
          content: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  color: backgroundColor ?? primaryColor,
                  borderRadius: BorderRadius.circular(30)),
              child: Row(
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  if (message != null)
                    Text(
                      message,
                      style: bodySmall?.copyWith(color: white),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    loading = false;
    dialogContext = null;

    return result;
  }

  Future showMessage(String message,
      {String? action,
      Color? backgroundColor,
      Duration? duration,
      DisplayType displayType = DisplayType.dialog,
      VoidCallback? onPressed,
      bool isError = false,
      DurationLength durationLength = DurationLength.short}) async {
    if (!mounted) return;

    if (duration != null &&
        (displayType == DisplayType.dialog ||
            displayType == DisplayType.bottomsheet)) {
      await Future.delayed(duration);
    }

    if (duration == null &&
        (displayType == DisplayType.toast ||
            displayType == DisplayType.snackbar)) {
      duration = getDuration(durationLength);
    }
    if (loading && duration == null) {
      duration = const Duration(seconds: 3);
    }
    await hideDialog();

    dynamic result;
    if (displayType == DisplayType.dialog) {
      result = await showDialog(
        context: this,
        builder: (context) {
          dialogContext = context;
          return ErrorOrSuccessView(
            message: message,
            action: action,
            onPressed: onPressed,
            isError: isError,
          );
        },
      );
    } else if (displayType == DisplayType.bottomsheet) {
      result = await showModalBottomSheet(
        backgroundColor: bgColor,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        context: this,
        builder: (context) {
          dialogContext = context;
          return ErrorOrSuccessView(
            message: message,
            action: action,
            onPressed: onPressed,
            isError: isError,
          );
        },
      );
    } else if (displayType == DisplayType.snackbar) {
      result = ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(
          duration: duration!,
          content: Text(
            message,
            style: bodySmall?.copyWith(color: white),
          ),
          backgroundColor:
              backgroundColor ?? (isError ? Colors.red : primaryColor),
          action: action == null || onPressed == null
              ? null
              : SnackBarAction(label: action, onPressed: onPressed),
        ),
      );
    } else if (displayType == DisplayType.toast) {
      ScaffoldMessenger.of(this).removeCurrentSnackBar();

      result = ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(
          duration: duration!,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            alignment: Alignment.center,
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  color:
                      backgroundColor ?? (isError ? Colors.red : primaryColor),
                  borderRadius: BorderRadius.circular(30)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      message,
                      style: bodySmall?.copyWith(color: white),
                    ),
                  ),
                  if (action != null && onPressed != null) ...[
                    const SizedBox(
                      width: 4,
                    ),
                    const VerticalDivider(
                      indent: 5,
                      endIndent: 5,
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    TextButton(
                      onPressed: onPressed,
                      child: Text(
                        action,
                        style: bodySmall?.copyWith(
                            color: white, fontWeight: FontWeight.w500),
                      ),
                    )
                  ]
                ],
              ),
            ),
          ),
        ),
      );
    }

    dialogContext = null;
    if (result == true) {
      onPressed?.call();
    }
    return result;
  }

  Future showToast(
    String message, {
    DurationLength durationLength = DurationLength.short,
    isError = false,
  }) {
    return showMessage(message,
        displayType: DisplayType.toast,
        durationLength: durationLength,
        backgroundColor: black,
        isError: isError);
  }

  Future showErrorToast(String message,
      {DurationLength durationLength = DurationLength.short}) {
    return showMessage(message,
        displayType: DisplayType.toast,
        durationLength: durationLength,
        isError: true);
  }

  Future showSuccessToast(String message,
      {DurationLength durationLength = DurationLength.short}) {
    return showMessage(message,
        displayType: DisplayType.toast,
        durationLength: durationLength,
        isError: false);
  }

  Future showSnackbar(String message,
      {DurationLength durationLength = DurationLength.long,
      String? action,
      VoidCallback? onPressed}) {
    return showMessage(message,
        displayType: DisplayType.snackbar,
        durationLength: durationLength,
        backgroundColor: black,
        action: action,
        onPressed: onPressed);
  }

  Future showErrorSnackbar(String message,
      {DurationLength durationLength = DurationLength.long,
      String? action,
      VoidCallback? onPressed}) {
    return showMessage(message,
        displayType: DisplayType.snackbar,
        durationLength: durationLength,
        isError: true,
        action: action,
        onPressed: onPressed);
  }

  Future showSuccessSnackbar(String message,
      {DurationLength durationLength = DurationLength.long,
      String? action,
      VoidCallback? onPressed}) {
    return showMessage(message,
        displayType: DisplayType.snackbar,
        durationLength: durationLength,
        isError: false,
        action: action,
        onPressed: onPressed);
  }

  Future hideDialog() async {
    if (dialogContext != null && dialogContext!.mounted) {
      dialogContext!.pop();
      dialogContext = null;
    }
  }
}
