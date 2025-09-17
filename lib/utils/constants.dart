class AppConstants {
  // App Info
  static const String appName = 'SecureChat';
  static const String appVersion = '1.0.0';

  // Security
  static const int secureIdLength = 12;
  static const int inviteLinkExpiryHours = 24;
  static const int secretKeyLength = 32;

  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Chat
  static const int maxMessageLength = 4096;
  static const int defaultMessageExpiry = 604800; // 7 days in seconds

  // Privacy Circles
  static const int maxCircleMembers = 50;
  static const int circleInviteExpiryDays = 7;
}

class AppStrings {
  static const String noContactsYet = 'No contacts yet';
  static const String noChatsYet = 'No conversations yet';
  static const String addContactsToChat = 'Add contacts to start chatting';
  static const String useQrOrInvite = 'Use QR codes or invite links to connect';
  static const String endToEndEncrypted = 'End-to-end encrypted';
  static const String secureIdLabel = 'Your Secure ID';
  static const String tapToShare = 'Tap to share';
  static const String enterSecureId = 'Enter Secure ID';
  static const String scanQrCode = 'Scan QR Code';
  static const String createInviteLink = 'Create Invite Link';
  static const String contactAdded =
      'Contact added! You can now communicate securely.';
}
