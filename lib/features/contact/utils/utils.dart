import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../game/models/match.dart';

String getMatchLink(Match match) {
  return "com.hms.gamesarena/${match.match_id}";
}

String getMatchInviteMessage(Match match, [String? name]) {
  final matchLink = getMatchLink(match);
  return "Hi${name == null ? "" : " $name"}, Lets play ${match.game} game together on Games Arena! Join me by clicking the link below.\n$matchLink\nSee you there!";
}

String getContactInviteMessage([String? name]) {
  String playStoreLink =
      "https://play.google.com/store/apps/details?id=com.hms.gamesarena";
  return "Hi${name == null ? "" : " $name"}, Let's play games together on Games Arena! It's a cool, simple and amazing app we can use to play board, card, puzzle and quiz games. Get it at $playStoreLink";
}

String getInviteMessage({String? name, Match? match}) {
  return match != null
      ? getMatchInviteMessage(match, name)
      : getContactInviteMessage(name);
}

Uri getWhatsAppUri(String phoneNumber, [String? name]) {
  final encodedMessage = Uri.encodeComponent(getInviteMessage(name: name));
  return Uri.parse("whatsapp://send?phone=$phoneNumber&text=$encodedMessage");
}

Uri getSMSUri(String phoneNumber, [String? name]) {
  final encodedMessage = Uri.encodeComponent(getInviteMessage(name: name));
  return Uri.parse("sms:$phoneNumber?body=$encodedMessage");
}

Future<List<String>> getAvailablePlatforms(String? phone) async {
  List<String> platforms = [];
  final number = phone ?? "0804";
  if (await canLaunchUrl(getWhatsAppUri(number))) {
    platforms.add("WhatsApp");
  }

  if (await canLaunchUrl(getSMSUri(number))) {
    platforms.add("SMS");
  }
  return platforms;
}

void shareTextInvite({String? name, Match? match}) async {
  await Share.share(
      subject: "Let's Play Games", getInviteMessage(name: name, match: match));
}

void shareContactInvite(String platform, String phoneNumber,
    [String? name]) async {
  if (platform == "WhatsApp") {
    launchUrl(getWhatsAppUri(phoneNumber, name));
  } else if (platform == "SMS") {
    launchUrl(getSMSUri(phoneNumber, name));
  }
}
