import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/utils/country_code_utils.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/app_appbar.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../theme/colors.dart';
import '../../game/models/match.dart';
import '../../game/models/player.dart';
import '../../user/models/user.dart';
import '../enums.dart';
import '../models/phone_contact.dart';
import '../providers/contacts_provider.dart';
import '../providers/search_contacts_provider.dart';
import '../utils/utils.dart';
import '../views/contacts_listview.dart';

class FindOrInvitePlayersPage extends ConsumerStatefulWidget {
  final bool isInvite;
  final Match? match;
  const FindOrInvitePlayersPage({super.key, this.isInvite = false, this.match});

  @override
  ConsumerState<FindOrInvitePlayersPage> createState() =>
      _FindOrInvitePlayersPageState();
}

class _FindOrInvitePlayersPageState
    extends ConsumerState<FindOrInvitePlayersPage> {
  bool isSearch = false;

  List<Player> newlyAddedPlayers = [];

  bool loading = false;
  bool isInvite = false;
  Match? match;
  final searchController = TextEditingController();
  List<String> availablePlatforms = [];

  @override
  void initState() {
    super.initState();
    isInvite = widget.isInvite;
    match = widget.match;
    readContacts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void readContacts() async {
    if (!isAndroidAndIos) return;
    loading = true;
    setState(() {});

    String? dialCode = await getCurrentCountryDialingCode();
    //final usersBox = Hive.box<String>("users");
    final phoneContactsBox = Hive.box<String>("contacts");
    //phoneContactsBox.clear();

    List<PhoneContact> phoneContacts =
        phoneContactsBox.values.map((e) => PhoneContact.fromJson(e)).toList();

    phoneContacts
        .sort((a, b) => (a.name ?? a.phone).compareTo((b.name ?? b.phone)));

    ref.read(contactsProvider.notifier).setPhoneContacts(phoneContacts);

    // Request contact permission
    if (!(await FlutterContacts.requestPermission())) return;

    List<Contact> contacts =
        await FlutterContacts.getContacts(withProperties: true);

    for (int i = 0; i < contacts.length; i++) {
      final contact = contacts[i];
      for (var phone in contact.phones) {
        final phoneNumber = phone.number.toValidNumber(dialCode);
        if (phoneNumber == null || contact.displayName.isEmpty) continue;
        final prevContactJson = phoneContactsBox.get(phoneNumber);
        final time = timeNow;
        //ContactStatus contactStatus = ContactStatus.unadded;

        if (prevContactJson != null) {
          final prevContact = PhoneContact.fromJson(prevContactJson);

          if (contact.displayName != prevContact.name) {
            prevContact.name = contact.displayName;
            prevContact.modifiedAt = time;
            // modified = true;
            await phoneContactsBox.put(phoneNumber, prevContact.toJson());
          }
        } else {
          final phoneContact = PhoneContact(
              phone: phoneNumber,
              name: contact.displayName,
              createdAt: time,
              modifiedAt: time,
              contactStatus: ContactStatus.unadded);
          await phoneContactsBox.put(phoneNumber, phoneContact.toJson());
        }
      }
    }
    phoneContacts =
        phoneContactsBox.values.map((e) => PhoneContact.fromJson(e)).toList();
    phoneContacts
        .sort((a, b) => (a.name ?? a.phone).compareTo((b.name ?? b.phone)));

    ref.read(contactsProvider.notifier).setPhoneContacts(phoneContacts);
    availablePlatforms =
        await getAvailablePlatforms(phoneContacts.firstOrNull?.phone);

    loading = false;
    setState(() {});
  }

  void copyLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
  }

  void pasteLink() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      String code = data.text!;
    }
  }

  void startSearch() {
    isSearch = true;
    setState(() {});
  }

  void updateSearch(String value) {
    ref
        .read(searchContactsProvider.notifier)
        .updateSearch(value.trim().toLowerCase());
  }

  void stopSearch() {
    searchController.clear();
    isSearch = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isSearch,
      onPopInvoked: (pop) {
        if (pop) return;
        if (isSearch) {
          stopSearch();
        }
        if (!isInvite) {
          context.pop(newlyAddedPlayers);
        }
      },
      child: Scaffold(
        appBar: (isSearch
            ? AppSearchBar(
                hint: "Search Contacts",
                controller: searchController,
                onChanged: updateSearch,
                onCloseSearch: stopSearch,
              )
            : AppAppBar(
                title: isInvite ? "Invite Contacts" : "Find Players",
                subtitle: isInvite ? null : "Select Contacts",
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator()),
                    IconButton(
                      onPressed: startSearch,
                      icon: const Icon(EvaIcons.search),
                    ),
                    IconButton(
                      onPressed: () => shareTextInvite(match: match),
                      icon: const Icon(EvaIcons.share_outline),
                    ),
                  ],
                ),
              )) as PreferredSizeWidget?,
        body: isInvite
            ? ContactsListView(
                isInvite: true, availablePlatforms: availablePlatforms)
            : DefaultTabController(
                length: ContactStatus.values.length,
                child: Column(
                  children: [
                    TabBar(
                      padding: EdgeInsets.zero,
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      dividerColor: transparent,
                      tabs: List.generate(
                        ContactStatus.values.length,
                        (index) {
                          final tab =
                              ContactStatus.values[index].name.capitalize;
                          return Tab(text: tab);
                        },
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: List.generate(
                          ContactStatus.values.length,
                          (index) {
                            final contactStatus = ContactStatus.values[index];
                            return ContactsListView(
                                contactStatus: contactStatus,
                                availablePlatforms: availablePlatforms,
                                newlyAddedPlayers: newlyAddedPlayers);
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
