import 'package:flutter/material.dart';
import '../widgets/identity_card.dart';
import '../services/storage_service.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  final String userPublicId;
  final VoidCallback onClearData;
  final VoidCallback onRegenerateId;

  const SettingsScreen({
    super.key,
    required this.userPublicId,
    required this.onClearData,
    required this.onRegenerateId,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _disappearingTimer = 604800; // 7 days default
  bool _autoDeleteExpired = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final timer = await StorageService.getDisappearingMessageTimer();
    final autoDelete = await StorageService.getAutoDeleteExpired();

    setState(() {
      _disappearingTimer = timer;
      _autoDeleteExpired = autoDelete;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        IdentityCard(publicId: widget.userPublicId),
        _buildSection(context, 'Privacy & Security', [
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('End-to-End Encryption'),
            subtitle: const Text('All messages are encrypted'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Disappearing Messages'),
            subtitle: Text(_getDisappearingTimerText()),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showDisappearingMessagesDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.auto_delete),
            title: const Text('Auto-delete Expired'),
            subtitle: const Text('Automatically clean up expired messages'),
            trailing: Switch(
              value: _autoDeleteExpired,
              onChanged: (value) async {
                setState(() {
                  _autoDeleteExpired = value;
                });
                await StorageService.setAutoDeleteExpired(value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked Contacts'),
            subtitle: const Text('Manage blocked users'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showBlockedContactsDialog(context),
          ),
        ]),
        _buildSection(context, 'Identity', [
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Regenerate Secure ID'),
            subtitle: const Text('Generate a new Secure ID'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showRegenerateIdDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('Encryption Keys'),
            subtitle: const Text('Rotate encryption keys'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showKeyRotationDialog(context),
          ),
        ]),
        _buildSection(context, 'Application', [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: Text('Version ${AppConstants.appVersion}'),
            onTap: () => _showAboutDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help using SecureChat'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showHelpDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Clear Messages'),
            subtitle: const Text('Delete all messages (keep contacts)'),
            onTap: () => _showClearMessagesDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all messages and contacts'),
            onTap: () => _showClearDataDialog(context),
          ),
        ]),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(children: children),
        ),
      ],
    );
  }

  String _getDisappearingTimerText() {
    if (_disappearingTimer == 0) return 'Off';
    if (_disappearingTimer < 3600) return '${_disappearingTimer ~/ 60} minutes';
    if (_disappearingTimer < 86400)
      return '${_disappearingTimer ~/ 3600} hours';
    return '${_disappearingTimer ~/ 86400} days';
  }

  void _showDisappearingMessagesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disappearing Messages'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose default timer for disappearing messages:'),
            const SizedBox(height: 16),
            ...[
              {'label': 'Off', 'value': 0},
              {'label': '1 Hour', 'value': 3600},
              {'label': '24 Hours', 'value': 86400},
              {'label': '7 Days', 'value': 604800},
              {'label': '30 Days', 'value': 2592000},
            ].map(
              (option) => RadioListTile<int>(
                title: Text(option['label'] as String),
                value: option['value'] as int,
                groupValue: _disappearingTimer,
                onChanged: (value) async {
                  setState(() {
                    _disappearingTimer = value ?? 0;
                  });
                  await StorageService.setDisappearingMessageTimer(
                    _disappearingTimer,
                  );
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBlockedContactsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blocked Contacts'),
        content: const Text('No blocked contacts yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRegenerateIdDialog(BuildContext context) {
    Helpers.showConfirmDialog(
      context: context,
      title: 'Regenerate Secure ID',
      content:
          'This will generate a new Secure ID for you. Your existing contacts will need to add your new ID to continue chatting. This action cannot be undone.',
      onConfirm: widget.onRegenerateId,
      confirmText: 'Regenerate',
      cancelText: 'Cancel',
    );
  }

  void _showKeyRotationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encryption Keys'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your encryption keys are used to secure your messages.'),
            SizedBox(height: 8),
            Text(
              'Key rotation is automatic and happens when you regenerate your Secure ID.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: const Icon(Icons.security, size: 48),
      children: const [
        Text(
          'A secure communication app that protects your privacy with end-to-end encryption.',
        ),
        SizedBox(height: 16),
        Text('Features:'),
        Text('• End-to-end encryption'),
        Text('• No phone numbers required'),
        Text('• Secure contact system'),
        Text('• Message expiration'),
        Text('• Firebase real-time messaging'),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to use SecureChat:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('1. Share your Secure ID with others'),
            Text('2. Add contacts using their Secure ID'),
            Text('3. Start chatting securely!'),
            SizedBox(height: 16),
            Text(
              'Your messages are encrypted and automatically expire after 7 days by default.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showClearMessagesDialog(BuildContext context) {
    Helpers.showConfirmDialog(
      context: context,
      title: 'Clear All Messages',
      content:
          'This will delete all your messages but keep your contacts and settings. This action cannot be undone.',
      onConfirm: () async {
        try {
          await StorageService.clearAllMessages();
          Helpers.showSnackBar(context, 'All messages cleared');
        } catch (e) {
          Helpers.showSnackBar(context, 'Failed to clear messages');
        }
      },
      confirmText: 'Clear Messages',
      cancelText: 'Cancel',
    );
  }

  void _showClearDataDialog(BuildContext context) {
    Helpers.showConfirmDialog(
      context: context,
      title: 'Clear All Data',
      content:
          'This will permanently delete all your messages, contacts, and settings. This action cannot be undone.',
      onConfirm: () {
        widget.onClearData();
        Helpers.showSnackBar(context, 'All data cleared');
      },
      confirmText: 'Delete All',
      cancelText: 'Cancel',
    );
  }
}
