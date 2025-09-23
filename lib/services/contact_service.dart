import '../models/contact.dart';
import '../services/storage_service.dart';

class ContactService {
  static Future<List<Contact>> getAllContacts() async {
    return await StorageService.getContacts();
  }

  static Future<void> addContact(String publicId, {String? customName}) async {
    final contacts = await getAllContacts();

    // Check if contact already exists
    if (contacts.any((c) => c.publicId == publicId)) {
      throw Exception('Contact already exists');
    }

    final newContact = Contact(
      publicId: publicId,
      name: customName ?? 'User ${publicId.substring(0, 4)}',
      addedAt: DateTime.now(),
    );

    contacts.add(newContact);
    await StorageService.saveContacts(contacts);
  }

  static Future<void> removeContact(String publicId) async {
    final contacts = await getAllContacts();
    contacts.removeWhere((c) => c.publicId == publicId);
    await StorageService.saveContacts(contacts);
  }

  static Future<void> updateContact(Contact updatedContact) async {
    final contacts = await getAllContacts();
    final index = contacts.indexWhere(
      (c) => c.publicId == updatedContact.publicId,
    );

    if (index != -1) {
      contacts[index] = updatedContact;
      await StorageService.saveContacts(contacts);
    }
  }

  static Future<Contact?> getContactById(String publicId) async {
    final contacts = await getAllContacts();
    try {
      return contacts.firstWhere((c) => c.publicId == publicId);
    } catch (e) {
      return null;
    }
  }

  static bool isValidSecureId(String id) {
    return RegExp(r'^[A-Z0-9]{12}$').hasMatch(id);
  }
}
