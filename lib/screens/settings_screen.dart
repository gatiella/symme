import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:symme/providers/theme_provider.dart';
import 'package:symme/screens/chat_screen.dart';
import 'package:symme/screens/qr_code_screen.dart';
import 'package:symme/utils/colors.dart';
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
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _disappearingTimer = 604800; // 7 days default
  bool _autoDeleteExpired = true;

  // Get theme-aware colors
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppGradients.appBarGradient),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 12),
          IdentityCard(publicId: widget.userPublicId),

          /// Appearance
          _buildSection(context, 'Appearance', [
            ListTile(
              leading: Icon(Icons.dark_mode, color: AppColors.primaryCyan),
              title: Text(
                "Dark Mode",
                style: TextStyle(
                  color: _getTextPrimaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                themeProvider.themeMode == ThemeMode.dark
                    ? "Enabled"
                    : "Disabled",
                style: TextStyle(color: _getTextSecondaryColor(context)),
              ),
              trailing: Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: themeProvider.toggleTheme,
                activeThumbColor: AppColors.primaryCyan,
                inactiveThumbColor: _getTextSecondaryColor(context),
              ),
            ),
          ]),

          /// Privacy & Security
          _buildSection(context, 'Privacy & Security', [
            ListTile(
              leading: Icon(Icons.security, color: AppColors.successGreen),
              title: Text(
                'End-to-End Encryption',
                style: TextStyle(
                  color: _getTextPrimaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'All messages are encrypted',
                style: TextStyle(color: _getTextSecondaryColor(context)),
              ),
              trailing: Icon(Icons.check_circle, color: AppColors.successGreen),
            ),
            ListTile(
              leading: Icon(Icons.timer, color: AppColors.primaryCyan),
              title: Text(
                'Disappearing Messages',
                style: TextStyle(
                  color: _getTextPrimaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                _getDisappearingTimerText(),
                style: TextStyle(color: _getTextSecondaryColor(context)),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: _getTextSecondaryColor(context),
                size: 16,
              ),
              onTap: () => _showDisappearingMessagesDialog(context),
            ),
            ListTile(
              leading: Icon(Icons.auto_delete, color: AppColors.warningOrange),
              title: Text(
                'Auto-delete Expired',
                style: TextStyle(
                  color: _getTextPrimaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Automatically clean up expired messages',
                style: TextStyle(color: _getTextSecondaryColor(context)),
              ),
              trailing: Switch(
                value: _autoDeleteExpired,
                onChanged: (value) async {
                  setState(() => _autoDeleteExpired = value);
                  await StorageService.setAutoDeleteExpired(value);
                },
                activeThumbColor: AppColors.primaryCyan,
                inactiveThumbColor: _getTextSecondaryColor(context),
              ),
            ),
            ListTile(
              leading: Icon(Icons.block, color: AppColors.errorRed),
              title: Text(
                'Blocked Contacts',
                style: TextStyle(
                  color: _getTextPrimaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Manage blocked users',
                style: TextStyle(color: _getTextSecondaryColor(context)),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: _getTextSecondaryColor(context),
                size: 16,
              ),
              onTap: () => _showBlockedContactsDialog(context),
            ),
          ]),

          /// Identity
          _buildSection(context, 'Identity', [
            ListTile(
              leading: Icon(Icons.qr_code, color: AppColors.primaryCyan),
              title: Text(
                'Share Secure ID',
                style: TextStyle(
                  color: _getTextPrimaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Share or scan a Secure ID',
                style: TextStyle(color: _getTextSecondaryColor(context)),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: _getTextSecondaryColor(context),
                size: 16,
              ),
              onTap: () => _navigateToQrScreen(context),
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: AppColors.warningOrange),
              title: Text(
                'Regenerate Secure ID',
                style: TextStyle(
                  color: _getTextPrimaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Generate a new Secure ID',
                style: TextStyle(color: _getTextSecondaryColor(context)),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: _getTextSecondaryColor(context),
                size: 16,
              ),
              onTap: () => _showRegenerateIdDialog(context),
            ),
            ListTile(
              leading: Icon(Icons.key, color: AppColors.successGreen),
              title: Text(
                'Encryption Keys',
                style: TextStyle(
                  color: _getTextPrimaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Rotate encryption keys',
                style: TextStyle(color: _getTextSecondaryColor(context)),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: _getTextSecondaryColor(context),
                size: 16,
              ),
              onTap: () => _showKeyRotationDialog(context),
            ),
          ]),

          /// Application
          _buildSection(context, 'Application', [
            ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.primaryCyan),
              title: Text(
                'About',
                style: TextStyle(
                  color: _getTextPrimaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Version ${AppConstants.appVersion}',
                style: TextStyle(color: _getTextSecondaryColor(context)),
              ),
              onTap: () => _showAboutDialog(context),
            ),
            ListTile(
              leading: Icon(Icons.help_outline, color: AppColors.primaryCyan),
              title: Text(
                'Help & Support',
                style: TextStyle(
                  color: _getTextPrimaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Get help using SecureChat',
                style: TextStyle(color: _getTextSecondaryColor(context)),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: _getTextSecondaryColor(context),
                size: 16,
              ),
              onTap: () => _showHelpDialog(context),
            ),
            ListTile(
              leading: Icon(
                Icons.cleaning_services,
                color: AppColors.warningOrange,
              ),
              title: Text(
                'Clear Messages',
                style: TextStyle(
                  color: _getTextPrimaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Delete all messages (keep contacts)',
                style: TextStyle(color: _getTextSecondaryColor(context)),
              ),
              onTap: () => _showClearMessagesDialog(context),
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: AppColors.errorRed),
              title: Text(
                'Clear All Data',
                style: TextStyle(
                  color: _getTextPrimaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Delete all messages and contacts',
                style: TextStyle(color: _getTextSecondaryColor(context)),
              ),
              onTap: () => _showClearDataDialog(context),
            ),
          ]),
        ],
      ),
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
            style: TextStyle(
              fontSize: 18,
              color: AppColors.primaryCyan,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _getSurfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: Theme.of(context).brightness == Brightness.light
                ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Future<void> _navigateToQrScreen(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => QrCodeScreen(publicId: widget.userPublicId),
      ),
    );

    if (result != null && result.isNotEmpty) {
      _handleScannedCode(result);
    }
  }

  void _handleScannedCode(String code) {
    Helpers.showConfirmDialog(
      context: context,
      title: 'Start a new chat?',
      content: 'Do you want to start a new chat with $code?',
      onConfirm: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(otherUserSecureId: code),
          ),
        );
      },
    );
  }

  String _getDisappearingTimerText() {
    if (_disappearingTimer == 0) return 'Off';
    if (_disappearingTimer < 3600) return '${_disappearingTimer ~/ 60} minutes';
    if (_disappearingTimer < 86400) {
      return '${_disappearingTimer ~/ 3600} hours';
    }
    return '${_disappearingTimer ~/ 86400} days';
  }

  void _showDisappearingMessagesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Disappearing Messages',
          style: TextStyle(color: _getTextPrimaryColor(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose default timer for disappearing messages:',
              style: TextStyle(color: _getTextSecondaryColor(context)),
            ),
            const SizedBox(height: 16),
            ...[
              {'label': 'Off', 'value': 0},
              {'label': '1 Hour', 'value': 3600},
              {'label': '24 Hours', 'value': 86400},
              {'label': '7 Days', 'value': 604800},
              {'label': '30 Days', 'value': 2592000},
            ].map(
              (option) => RadioListTile<int>(
                title: Text(
                  option['label'] as String,
                  style: TextStyle(color: _getTextPrimaryColor(context)),
                ),
                value: option['value'] as int,
                groupValue: _disappearingTimer,
                activeColor: AppColors.primaryCyan,
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
            child: Text(
              'Cancel',
              style: TextStyle(color: _getTextSecondaryColor(context)),
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockedContactsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Blocked Contacts',
          style: TextStyle(color: _getTextPrimaryColor(context)),
        ),
        content: Text(
          'No blocked contacts yet.',
          style: TextStyle(color: _getTextSecondaryColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppColors.primaryCyan)),
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
        backgroundColor: _getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Encryption Keys',
          style: TextStyle(color: _getTextPrimaryColor(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your encryption keys are used to secure your messages.',
              style: TextStyle(color: _getTextSecondaryColor(context)),
            ),
            const SizedBox(height: 8),
            Text(
              'Key rotation is automatic and happens when you regenerate your Secure ID.',
              style: TextStyle(color: _getTextSecondaryColor(context)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppColors.primaryCyan)),
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
      applicationIcon: Icon(
        Icons.security,
        size: 48,
        color: AppColors.primaryCyan,
      ),
      children: [
        Text(
          'A secure communication app that protects your privacy with end-to-end encryption.',
          style: TextStyle(color: _getTextSecondaryColor(context)),
        ),
        const SizedBox(height: 16),
        Text(
          'Features:',
          style: TextStyle(
            color: _getTextPrimaryColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '• End-to-end encryption',
          style: TextStyle(color: _getTextSecondaryColor(context)),
        ),
        Text(
          '• No phone numbers required',
          style: TextStyle(color: _getTextSecondaryColor(context)),
        ),
        Text(
          '• Secure contact system',
          style: TextStyle(color: _getTextSecondaryColor(context)),
        ),
        Text(
          '• Message expiration',
          style: TextStyle(color: _getTextSecondaryColor(context)),
        ),
        Text(
          '• Firebase real-time messaging',
          style: TextStyle(color: _getTextSecondaryColor(context)),
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Help & Support',
          style: TextStyle(color: _getTextPrimaryColor(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to use SecureChat:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1. Share your Secure ID with others',
              style: TextStyle(color: _getTextSecondaryColor(context)),
            ),
            Text(
              '2. Add contacts using their Secure ID',
              style: TextStyle(color: _getTextSecondaryColor(context)),
            ),
            Text(
              '3. Start chatting securely!',
              style: TextStyle(color: _getTextSecondaryColor(context)),
            ),
            const SizedBox(height: 16),
            Text(
              'Your messages are encrypted and automatically expire after 7 days by default.',
              style: TextStyle(color: _getTextSecondaryColor(context)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(color: AppColors.primaryCyan),
            ),
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
