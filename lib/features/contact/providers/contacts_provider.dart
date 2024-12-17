import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/phone_contact.dart';

class PhoneContactsNotifier extends StateNotifier<List<PhoneContact>> {
  PhoneContactsNotifier(super.state);

  void clearPhoneContacts(List<PhoneContact> contacts) {
    state = [];
  }

  void updatePhoneContacts(PhoneContact contact) {
    state = state.map((e) => e.phone == contact.phone ? contact : e).toList();
  }

  void setPhoneContacts(List<PhoneContact> contacts) {
    state = contacts;
  }

  void addPhoneContact(PhoneContact contacts) {
    state = [...state, contacts];
  }

  void removePhoneContact(PhoneContact contact) {
    state = state
        .where((prevPhoneContact) => prevPhoneContact.phone != contact.phone)
        .toList();
  }
}

final contactsProvider =
    StateNotifierProvider<PhoneContactsNotifier, List<PhoneContact>>(
  (ref) {
    return PhoneContactsNotifier([]);
  },
);
