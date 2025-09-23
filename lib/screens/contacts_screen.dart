// Enhanced contacts_screen.dart with duplicate prevention and navigation to contacts list
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/contact.dart';
import '../services/firebase_auth_service.dart';
import '../services/storage_service.dart';
import '../services/call_manager.dart';
import '../services/presence_service.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';
import '../utils/colors.dart';
import '../models/call.dart';
import 'qr_code_screen.dart';
import 'contacts_list_screen.dart'; // Import the new contacts list screen

class ContactsScreen extends StatefulWidget {
  final VoidCallback onContactAdded;
  final Function(String) onStartChat;
  final String? searchQuery;

  const ContactsScreen({
    super.key,
    required this.onContactAdded,
    required this.onStartChat,
    this.searchQuery,
  });

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _secureIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  String? _userSecureId;

  // Get theme-aware colors based on brightness
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

  Color _getBackgroundSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.backgroundSecondary
        : Colors.grey.shade100;
  }

  Color _getDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.divider
        : Colors.grey.shade300;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(ContactsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _filterContacts();
    }
  }

  @override
  void dispose() {
    _secureIdController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final contacts = await StorageService.getContacts();
      final userSecureId = await StorageService.getUserSecureId();

      setState(() {
        _contacts = contacts;
        _userSecureId = userSecureId;
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
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) {
      _filteredContacts = List.from(_contacts);
    } else {
      final query = widget.searchQuery!.toLowerCase();
      _filteredContacts = _contacts.where((contact) {
        final name = contact.name.toLowerCase();
        final publicId = contact.publicId.toLowerCase();
        return name.contains(query) || publicId.contains(query);
      }).toList();
    }

    if (mounted) {
      setState(() {});
    }
  }

  // Enhanced duplicate checking method
  bool _isDuplicateContact(String secureId) {
    if (_userSecureId != null && secureId == _userSecureId) {
      return true; // User's own ID
    }

    return _contacts.any((contact) =>
    contact.publicId.toUpperCase() == secureId.toUpperCase());
  }

  void _navigateToContactsList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactsListScreen(
          onStartChat: widget.onStartChat,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _getBackgroundColor(context),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      body: Column(
        children: [
          // Your Secure ID Card (only show when not searching)
          if (_userSecureId != null &&
              (widget.searchQuery == null || widget.searchQuery!.isEmpty))
            _buildSecureIdCard(),

          // Add Contact Section (only show when not searching)
          if (widget.searchQuery == null || widget.searchQuery!.isEmpty)
            _buildAddContactSection(),

          // Contacts Summary Card (only show when not searching)
          if (widget.searchQuery == null || widget.searchQuery!.isEmpty)
            _buildContactsSummaryCard(),

          // Search header when searching
          if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty)
            _buildSearchHeader(),

          const SizedBox(height: 16),

          // Contacts List (limited view when not searching)
          Expanded(child: _buildContactsContent()),
        ],
      ),
    );
  }

  Widget _buildContactsSummaryCard() {
    if (_contacts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        color: _getSurfaceColor(context),
        elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: AppColors.primaryCyan),
                  const SizedBox(width: 8),
                  Text(
                    'Your Contacts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getTextPrimaryColor(context),
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _navigateToContactsList,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryCyan,
                    ),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem(
                    icon: Icons.person,
                    label: 'Total',
                    value: '${_contacts.length}',
                  ),
                  const SizedBox(width: 24),
                  FutureBuilder<int>(
                    future: _getOnlineContactsCount(),
                    builder: (context, snapshot) {
                      return _buildStatItem(
                        icon: Icons.circle,
                        label: 'Online',
                        value: '${snapshot.data ?? 0}',
                        iconColor: AppColors.successGreen,
                      );
                    },
                  ),
                ],
              ),
              if (_contacts.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Recent Contacts',
                  style: TextStyle(
                    color: _getTextSecondaryColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _contacts.take(5).length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => widget.onStartChat(contact.publicId),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Helpers.getColorFromId(contact.publicId),
                                child: Text(
                                  Helpers.getInitials(contact.name),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                contact.name.length > 8
                                    ? '${contact.name.substring(0, 8)}...'
                                    : contact.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getTextPrimaryColor(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor ?? _getTextSecondaryColor(context),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getTextPrimaryColor(context),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: _getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<int> _getOnlineContactsCount() async {
    int onlineCount = 0;
    for (final contact in _contacts) {
      try {
        final isOnline = await PresenceService.isUserOnlineBySecureId(contact.publicId);
        if (isOnline) onlineCount++;
      } catch (e) {
        // Ignore errors and continue counting
      }
    }
    return onlineCount;
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryCyan.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryCyan.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.primaryCyan, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _filteredContacts.isEmpty
                  ? 'No contacts found for "${widget.searchQuery}"'
                  : '${_filteredContacts.length} contact${_filteredContacts.length == 1 ? '' : 's'} found for "${widget.searchQuery}"',
              style: TextStyle(
                color: AppColors.primaryCyan,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsContent() {
    if (_filteredContacts.isEmpty) {
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        return _buildNoSearchResults();
      } else if (_contacts.isEmpty) {
        return _buildEmptyState();
      }
    }

    // Show limited contacts in main view, full list in dedicated screen
    final displayContacts = widget.searchQuery != null && widget.searchQuery!.isNotEmpty
        ? _filteredContacts
        : _filteredContacts.take(3).toList();

    return _buildContactsList(displayContacts, showViewAll: widget.searchQuery == null || widget.searchQuery!.isEmpty);
  }

  Widget _buildNoSearchResults() {
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
            'Try searching for a different name or Secure ID.',
            style: TextStyle(
              color: _getTextSecondaryColor(context),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSecureIdCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        color: _getSurfaceColor(context),
        elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security, color: AppColors.primaryCyan),
                  const SizedBox(width: 8),
                  Text(
                    'Your Secure ID',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getTextPrimaryColor(context),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getBackgroundSecondaryColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getDividerColor(context)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _userSecureId!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getTextPrimaryColor(context),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.copy, color: AppColors.primaryCyan),
                        onPressed: _copySecureId,
                        tooltip: 'Copy ID',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.qr_code, color: AppColors.primaryCyan),
                        onPressed: _showQRCode,
                        tooltip: 'Show QR Code',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share this ID with others to connect securely',
                style: TextStyle(
                  color: _getTextSecondaryColor(context),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddContactSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: _getSurfaceColor(context),
        elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Contact',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getTextPrimaryColor(context),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showAddContactDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add by ID'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryCyan,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _scanQRCode,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan QR'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryCyan,
                        side: BorderSide(color: AppColors.primaryCyan),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
            AppStrings.noContactsYet,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.useQrOrInvite,
            style: TextStyle(
              color: _getTextSecondaryColor(context),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(List<Contact> contacts, {bool showViewAll = false}) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: _getSurfaceColor(context),
                elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildEnhancedContactItem(contact),
              );
            },
          ),
        ),
        if (showViewAll && _contacts.length > 3)
          Container(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: _navigateToContactsList,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryCyan,
                side: BorderSide(color: AppColors.primaryCyan),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('View All ${_contacts.length} Contacts'),
            ),
          ),
      ],
    );
  }

  Widget _buildEnhancedContactItem(Contact contact) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Helpers.getColorFromId(contact.publicId),
            child: Text(
              Helpers.getInitials(contact.name),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Contact info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: TextStyle(
                    color: _getTextPrimaryColor(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact.publicId,
                  style: TextStyle(
                    color: _getTextSecondaryColor(context),
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                _buildPresenceStatus(contact.publicId),
              ],
            ),
          ),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.message, color: AppColors.primaryCyan),
                  onPressed: () => widget.onStartChat(contact.publicId),
                  tooltip: 'Message',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.call, color: AppColors.successGreen),
                  onPressed: () => _showCallOptions(contact),
                  tooltip: 'Call',
                ),
              ),
            ],
          ),
        ],
      ),
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
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isOnline
                    ? AppColors.successGreen
                    : _getTextSecondaryColor(context),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 10,
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

  void _copySecureId() {
    if (_userSecureId != null) {
      Clipboard.setData(ClipboardData(text: _userSecureId!));
      Helpers.showSnackBar(context, 'Secure ID copied to clipboard');
    }
  }

  void _showQRCode() {
    if (_userSecureId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QrCodeScreen(publicId: _userSecureId!),
        ),
      );
    }
  }

  void _showAddContactDialog() {
    _secureIdController.clear();
    _nameController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Contact',
          style: TextStyle(
            color: _getTextPrimaryColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _secureIdController,
              style: TextStyle(color: _getTextPrimaryColor(context)),
              decoration: InputDecoration(
                labelText: 'Secure ID',
                hintText: 'Enter 12-character Secure ID',
                prefixIcon: Icon(Icons.security, color: AppColors.primaryCyan),
                labelStyle: TextStyle(color: _getTextSecondaryColor(context)),
                hintStyle: TextStyle(color: _getTextSecondaryColor(context)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _getDividerColor(context)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryCyan),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 12,
              onChanged: (value) {
                // Real-time duplicate checking
                setState(() {});
              },
            ),
            // Show duplicate warning
            if (_secureIdController.text.isNotEmpty && _isDuplicateContact(_secureIdController.text))
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.errorRed, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _secureIdController.text == _userSecureId
                            ? 'This is your own Secure ID'
                            : 'Contact already exists',
                        style: TextStyle(
                          color: AppColors.errorRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              style: TextStyle(color: _getTextPrimaryColor(context)),
              decoration: InputDecoration(
                labelText: 'Contact Name (Optional)',
                hintText: 'Enter a name for this contact',
                prefixIcon: Icon(Icons.person, color: AppColors.primaryCyan),
                labelStyle: TextStyle(color: _getTextSecondaryColor(context)),
                hintStyle: TextStyle(color: _getTextSecondaryColor(context)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _getDividerColor(context)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryCyan),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
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
            onPressed: _isDuplicateContact(_secureIdController.text)
                ? null
                : _addContact,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isDuplicateContact(_secureIdController.text)
                  ? Colors.grey
                  : AppColors.primaryCyan,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanQRCode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QrCodeScreen(startInScanMode: true),
      ),
    );

    if (result != null) {
      _addContact(qrData: result);
    }
  }

  Future<void> _addContact({String? qrData}) async {
    final secureId = qrData ?? _secureIdController.text.trim().toUpperCase();
    final name = _nameController.text.trim();

    if (secureId.isEmpty) {
      Helpers.showSnackBar(context, 'Please enter a Secure ID');
      return;
    }

    if (secureId.length != 12) {
      Helpers.showSnackBar(context, 'Invalid Secure ID: Must be 12 characters');
      return;
    }

    // Enhanced duplicate checking with specific messages
    if (_isDuplicateContact(secureId)) {
      if (secureId == _userSecureId) {
        Helpers.showSnackBar(context, 'Cannot add your own Secure ID as a contact');
      } else {
        Helpers.showSnackBar(context, 'Contact already exists in your list');
      }
      return;
    }

    try {
      // Show loading indicator
      if (qrData == null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: _getSurfaceColor(context),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primaryCyan),
                const SizedBox(width: 20),
                Text(
                  'Verifying contact...',
                  style: TextStyle(color: _getTextPrimaryColor(context)),
                ),
              ],
            ),
          ),
        );
      }

      final userData = await FirebaseAuthService.getUserBySecureId(secureId);

      // Hide loading indicator
      if (qrData == null && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (userData == null) {
        Helpers.showSnackBar(context, 'Secure ID not found or user inactive');
        return;
      }

      final newContact = Contact(
        publicId: secureId,
        name: name.isNotEmpty ? name : 'User ${secureId.substring(0, 4)}',
        addedAt: DateTime.now(),
      );

      _contacts.add(newContact);
      await StorageService.saveContacts(_contacts);

      if (qrData == null) {
        Navigator.pop(context);
      }

      setState(() {});
      _filterContacts();
      widget.onContactAdded();

      Helpers.showSnackBar(context, 'Contact "${newContact.name}" added successfully!');
    } catch (e) {
      // Hide loading indicator if still showing
      if (qrData == null && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      Helpers.showSnackBar(context, 'Failed to add contact: ${e.toString()}');
    }
  }

  void _showCallOptions(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Helpers.getColorFromId(contact.publicId),
              child: Text(
                Helpers.getInitials(contact.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                contact.name,
                style: TextStyle(
                  color: _getTextPrimaryColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCallOptionTile(
              icon: Icons.call,
              title: 'Voice Call',
              subtitle: 'Audio only',
              onTap: () {
                Navigator.pop(context);
                _initiateCall(contact, CallType.audio);
              },
            ),
            const SizedBox(height: 8),
            _buildCallOptionTile(
              icon: Icons.videocam,
              title: 'Video Call',
              subtitle: 'Audio and video',
              onTap: () {
                Navigator.pop(context);
                _initiateCall(contact, CallType.video);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _getTextSecondaryColor(context),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildCallOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getBackgroundSecondaryColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryCyan, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _getTextPrimaryColor(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _getTextSecondaryColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initiateCall(Contact contact, CallType callType) async {
    // Show loading dialog
    _showCallingDialog(contact.name, callType);

    try {
      // Use the enhanced CallManager
      final result = await CallManager.instance.startCall(
        receiverSecureId: contact.publicId,
        callType: callType,
      );

      // Hide loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!result.success) {
        _showErrorDialog(result.error ?? 'Failed to start call');
      }
    } catch (e) {
      // Hide loading dialog if still showing
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
}