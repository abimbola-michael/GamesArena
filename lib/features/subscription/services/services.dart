import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/firebase/firestore_methods.dart';
import '../../../shared/utils/utils.dart';
import '../../user/services.dart';
import '../constants/constants.dart';
import '../enums/enums.dart';
import '../models/available_watch.dart';

FirestoreMethods fm = FirestoreMethods();

Future<SubscriptionPlan?> getSubscriptionPlan() async {
  final user = await getUser(myId, useCache: false);

  final index = user == null ||
          user.sub == null ||
          (user.subExpiryTime != null &&
              timeNow.datetime.isAfter(user.subExpiryTime!.datetime))
      ? -1
      : SubscriptionPlan.values
          .indexWhere((element) => element.name == user.sub!);
  return index == -1 ? null : SubscriptionPlan.values[index];
}

Future<AvailableDuration> getAvailableDuration() async {
  final user = await getUser(myId, useCache: false);
  if (user == null) {
    return AvailableDuration(duration: 0, isSubscription: false);
  }

  if (user.sub != null && user.subExpiryTime != null) {
    if (DateTime.now().isBefore(user.subExpiryTime!.datetime)) {
      return AvailableDuration(
          duration:
              DateTime.now().difference(user.subExpiryTime!.datetime).inSeconds,
          isSubscription: true);
    } else {
      await resetSubscription();
      return AvailableDuration(duration: 0, isSubscription: false);
    }
  }
  // else if (user.dailyLimitDate == null ||
  //     user.dailyLimit == null ||
  //     DateTime.now().difference(user.dailyLimitDate!.datetime).inDays > 0) {
  //   await updateDailyLimit(MAX_DAILY_LIMIT);
  //   return AvailableDuration(duration: MAX_DAILY_LIMIT, isSubscription: false);
  // }

  // final storedDailyLimit =
  //     int.parse(Hive.box<String>("details").get("dailyLimit") ?? "0");
  // final storedDailyLimitDate =
  //     Hive.box<String>("details").get("dailyLimitDate")?.datetime ??
  //         DateTime.now();
  int dailyLimit = 0;

  // if (storedDailyLimitDate.isAfter(user.dailyLimitDate!.datetime) &&
  //     storedDailyLimit > user.dailyLimit!) {
  //   dailyLimit = storedDailyLimit;
  //   updateDailyLimit(storedDailyLimit);
  // } else {
  //   dailyLimit = user.dailyLimit!;
  // }

  return AvailableDuration(duration: dailyLimit, isSubscription: false);
}

Future resetSubscription() async {
  return fm.updateValue([
    "users",
    myId
  ], value: {
    "sub": null,
    "subExpiryTime": null,
    "dailyLimit": MAX_DAILY_LIMIT,
    "dailyLimitDate": timeNow
  });
}

Future updateDailyLimit(int limit) async {
  return fm.updateValue(["users", myId],
      value: {"dailyLimit": limit, "dailyLimitDate": timeNow});
}
