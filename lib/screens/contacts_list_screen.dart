// contacts_list_screen.dart - Separate page for all contacts
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/contact.dart';
import '../services/storage_service.dart';
import '../services/presence_service.dart';
import '../utils/helpers.dart';
import '../utils/colors.dart';
import '../services/call_manager.dart';
import '../models/call.dart';

class ContactsListScreen extends StatefulWidget {
  final Function(String) onStartChat;

  const ContactsListScreen({
    super.key,
    required this.onStartChat,
  });

  @override
  _ContactsListScreenState createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Theme-aware color methods
  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.backgroundPrimary
        : Colors.grey.shade50;
  }

  Color _getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.surfaceCard
        : Colors.white;
  }

  Color _getTextPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.textPrimary
        : Colors.grey.shade900;
  }

  Color _getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondary
        : Colors.grey.shade600;
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await StorageService.getContacts();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
      _filterContacts();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Helpers.showSnackBar(context, 'Failed to load contacts: ${e.toString()}');
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredContacts = List.from(_contacts);
    } else {
      _filteredContacts = _contacts.where((contact) {
        final name = contact.name.toLowerCase();
        final publicId = contact.publicId.toLowerCase();
        return name.contains(query) || publicId.contains(query);
      }).toList();
    }
    setState(() {});
  }

  Future<void> _deleteContact(Contact contact) async {
    final confirmed = await _showDeleteConfirmation(contact.name);
    if (!confirmed) return;

    try {
      _contacts.removeWhere((c) => c.publicId == contact.publicId);
      await StorageService.saveContacts(_contacts);
      _filterContacts();
      Helpers.showSnackBar(context, 'Contact deleted successfully');
    } catch (e) {
      Helpers.showSnackBar(context, 'Failed to delete contact: ${e.toString()}');
    }
  }

  Future<bool> _showDeleteConfirmation(String contactName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: AppColors.errorRed, size: 24),
            const SizedBox(width: 12),
            Text(
              'Delete Contact',
              style: TextStyle(
                color: _getTextPrimaryColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$contactName"? This action cannot be undone.',
          style: TextStyle(
            color: _getTextSecondaryColor(context),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: _getTextSecondaryColor(context),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _editContact(Contact contact) {
    final nameController = TextEditingController(text: contact.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Contact',
          style: TextStyle(
            color: _getTextPrimaryColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: _getTextPrimaryColor(context)),
          decoration: InputDecoration(
            labelText: 'Contact Name',
            hintText: 'Enter a name for this contact',
            prefixIcon: Icon(Icons.person, color: AppColors.primaryCyan),
            labelStyle: TextStyle(color: _getTextSecondaryColor(context)),
            hintStyle: TextStyle(color: _getTextSecondaryColor(context)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryCyan),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _getTextSecondaryColor(context),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != contact.name) {
                final updatedContact = contact.copyWith(name: newName);
                final index = _contacts.indexWhere((c) => c.publicId == contact.publicId);
                if (index != -1) {
                  _contacts[index] = updatedContact;
                  await StorageService.saveContacts(_contacts);
                  _filterContacts();
                  Helpers.showSnackBar(context, 'Contact updated successfully');
                }
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateCall(Contact contact, CallType callType) async {
    _showCallingDialog(contact.name, callType);

    try {
      final result = await CallManager.instance.startCall(
        receiverSecureId: contact.publicId,
        callType: callType,
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!result.success) {
        _showErrorDialog(result.error ?? 'Failed to start call');
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showErrorDialog('Failed to start call: ${e.toString()}');
    }
  }

  void _showCallingDialog(String contactName, CallType callType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primaryCyan),
            const SizedBox(height: 20),
            Text(
              'Calling $contactName...',
              style: TextStyle(
                color: _getTextPrimaryColor(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              callType == CallType.video ? 'Video Call' : 'Voice Call',
              style: TextStyle(
                color: _getTextSecondaryColor(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              CallManager.instance.endCall();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.errorRed, size: 24),
            const SizedBox(width: 12),
            Text(
              'Call Failed',
              style: TextStyle(
                color: _getTextPrimaryColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: _getTextSecondaryColor(context),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryCyan),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('All Contacts'),
        backgroundColor: _getSurfaceColor(context),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: _getTextPrimaryColor(context)),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: TextStyle(color: _getTextSecondaryColor(context)),
                prefixIcon: Icon(Icons.search, color: AppColors.primaryCyan),
                filled: true,
                fillColor: _getBackgroundColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : _contacts.isEmpty
          ? _buildEmptyState()
          : _filteredContacts.isEmpty
          ? _buildNoResults()
          : _buildContactsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: _getTextSecondaryColor(context).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Contacts Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add contacts to see them here',
            style: TextStyle(
              color: _getTextSecondaryColor(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: _getTextSecondaryColor(context).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Contacts Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for a different name or ID.',
            style: TextStyle(
              color: _getTextSecondaryColor(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: _getSurfaceColor(context),
          elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Helpers.getColorFromId(contact.publicId),
                  child: Text(
                    Helpers.getInitials(contact.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Contact Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: TextStyle(
                          color: _getTextPrimaryColor(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.publicId,
                        style: TextStyle(
                          color: _getTextSecondaryColor(context),
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPresenceStatus(contact.publicId),
                    ],
                  ),
                ),

                // Action Menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: _getTextSecondaryColor(context),
                  ),
                  color: _getSurfaceColor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'message':
                        widget.onStartChat(contact.publicId);
                        break;
                      case 'voice_call':
                        _initiateCall(contact, CallType.audio);
                        break;
                      case 'video_call':
                        _initiateCall(contact, CallType.video);
                        break;
                      case 'edit':
                        _editContact(contact);
                        break;
                      case 'copy_id':
                        Clipboard.setData(ClipboardData(text: contact.publicId));
                        Helpers.showSnackBar(context, 'ID copied to clipboard');
                        break;
                      case 'delete':
                        _deleteContact(contact);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'message',
                      child: Row(
                        children: [
                          Icon(Icons.message, color: AppColors.primaryCyan),
                          const SizedBox(width: 12),
                          Text(
                            'Message',
                            style: TextStyle(color: _getTextPrimaryColor(context)),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'voice_call',
                      child: Row(
                        children: [
                          Icon(Icons.call, color: AppColors.successGreen),
                          const SizedBox(width: 12),
                          Text(
                            'Voice Call',
                            style: TextStyle(color: _getTextPrimaryColor(context)),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'video_call',
                      child: Row(
                        children: [
                          Icon(Icons.videocam, color: AppColors.successGreen),
                          const SizedBox(width: 12),
                          Text(
                            'Video Call',
                            style: TextStyle(color: _getTextPrimaryColor(context)),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: _getTextSecondaryColor(context)),
                          const SizedBox(width: 12),
                          Text(
                            'Edit Name',
                            style: TextStyle(color: _getTextPrimaryColor(context)),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'copy_id',
                      child: Row(
                        children: [
                          Icon(Icons.copy, color: _getTextSecondaryColor(context)),
                          const SizedBox(width: 12),
                          Text(
                            'Copy ID',
                            style: TextStyle(color: _getTextPrimaryColor(context)),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.errorRed),
                          const SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppColors.errorRed),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresenceStatus(String secureId) {
    return FutureBuilder<bool>(
      future: PresenceService.isUserOnlineBySecureId(secureId),
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? false;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOnline
                    ? AppColors.successGreen
                    : _getTextSecondaryColor(context),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 12,
                color: isOnline
                    ? AppColors.successGreen
                    : _getTextSecondaryColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}