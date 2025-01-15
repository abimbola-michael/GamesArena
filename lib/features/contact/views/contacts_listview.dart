// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/contact/services/services.dart';
import 'package:gamesarena/features/game/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/utils/country_code_utils.dart';
import '../../../shared/views/empty_listview.dart';
import '../../contact/models/phone_contact.dart';
import '../../game/models/player.dart';
import '../../user/models/user.dart';
import '../components/contact_item.dart';
import '../enums.dart';
import '../providers/contacts_provider.dart';
import '../providers/search_contacts_provider.dart';
import '../utils/utils.dart';

class ContactsListView extends ConsumerWidget {
  final bool isInvite;
  final ContactStatus? contactStatus;
  final List<String> availablePlatforms;
  final List<Player>? newlyAddedPlayers;
  const ContactsListView(
      {super.key,
      this.contactStatus,
      required this.availablePlatforms,
      this.isInvite = false,
      this.newlyAddedPlayers});

  void addContact(PhoneContact contact, WidgetRef ref) async {
    final users = await getUsersWithNumber(contact.phone);
    final phoneContactsBox = Hive.box<String>("contacts");
    if (users.isNotEmpty) {
      final usersBox = Hive.box<String>("users");
      final playersBox = Hive.box<String>("players");

      contact.contactStatus = ContactStatus.added;
      contact.userIds = [];
      for (final user in users) {
        contact.userIds!.add(user.user_id);
        usersBox.put(user.user_id, user.toJson());

        final player = await addPlayer(user.user_id);
        playersBox.put(player.id, player.toJson());
        if (newlyAddedPlayers != null) {
          newlyAddedPlayers!.add(player);
        }
      }
    } else {
      contact.contactStatus = ContactStatus.requested;
      await sendPlayerRequest(contact.phone);
    }
    phoneContactsBox.put(contact.phone, contact.toJson());
    ref.read(contactsProvider.notifier).updatePhoneContacts(contact);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersBox = Hive.box<String>("users");

    final contacts = ref
        .watch(contactsProvider)
        .where((contact) =>
            (isInvite && contact.contactStatus != ContactStatus.added) ||
            (contactStatus != null && contact.contactStatus == contactStatus))
        .toList();

    final searchString = ref.watch(searchContactsProvider);

    final phoneContacts = searchString.isEmpty
        ? contacts
        : contacts.where((contact) {
            return contact.name!.toLowerCase().contains(searchString) ||
                contact.phone.toLowerCase().contains(searchString);
          }).toList();
    if (phoneContacts.isEmpty) {
      return const EmptyListView(message: "No Contact");
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      itemCount: phoneContacts.length,
      itemBuilder: (context, index) {
        final phoneContact = phoneContacts[index];

        List<User> users = [];
        if (phoneContact.userIds != null && phoneContact.userIds!.isNotEmpty) {
          for (final userId in phoneContact.userIds!) {
            final userJson = usersBox.get(userId);
            if (userJson != null) {
              final user = User.fromJson(userJson);
              user.phoneName = phoneContact.name;
              users.add(user);
            }
          }
        } else {
          final user = User(
            user_id: "",
            username: "",
            email: "",
            phone: phoneContact.phone,
            phoneName: phoneContact.name,
            tokens: [],
            time: phoneContact.modifiedAt ?? phoneContact.createdAt,
            last_seen: "",
          );
          // user.phoneName = phoneContact.name;
          users.add(user);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(users.length, (index) {
            final user = users[index];
            return ContactItem(
              availablePlatforms: availablePlatforms,
              user: user,
              contactStatus: phoneContact.contactStatus,
              onPressed: () {
                if (phoneContact.contactStatus == ContactStatus.unadded) {
                  addContact(phoneContact, ref);
                } else if (phoneContact.contactStatus ==
                    ContactStatus.requested) {
                  shareContactInvite(
                      "SMS", phoneContact.phone, phoneContact.name);
                } else {}
              },
              onShare: (platform) =>
                  shareContactInvite(platform, phoneContact.phone),
            );
          }),
        );
      },
    );
  }
}
