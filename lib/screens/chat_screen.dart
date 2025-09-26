<<<<<<< HEAD
import 'dart:io';

=======
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/message.dart';
import '../services/firebase_message_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart'; // Add this import
import '../widgets/chat_bubble.dart';
import '../utils/helpers.dart';
import '../utils/colors.dart';
<<<<<<< HEAD
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
=======
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7

class ChatScreen extends StatefulWidget {
  final String otherUserSecureId;

  const ChatScreen({super.key, required this.otherUserSecureId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _otherUserId;
  String? _currentUserId;
  final bool _isOtherUserOnline = false;
  int _disappearingTimer = 0;
  StreamSubscription<List<Message>>? _messagesSubscription;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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

  Color _getInputBackgroundColor(BuildContext context) {
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
    WidgetsBinding.instance.addObserver(this);
    _setupAnimations();
    _initializeChat();
    _loadDisappearingTimer();
    _loadCurrentUser();
    _clearNotificationsForThisChat(); // Clear notifications when entering chat
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _messagesSubscription?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  // NEW: Clear notifications for this chat when user enters
<<<<<<< HEAD
void _clearNotificationsForThisChat() {
  // Clear notifications related to this specific chat
  try {
    NotificationService.clearAllNotifications();
    print('Cleared notifications for chat with ${widget.otherUserSecureId}');
  } catch (e) {
    print('Error clearing notifications: $e');
  }
}
=======
  void _clearNotificationsForThisChat() {
    // Clear notifications related to this specific chat
    // You might want to implement a more sophisticated notification ID system
    NotificationService.clearAllNotifications();
  }
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7

  // UPDATED: Handle app lifecycle changes to manage notifications
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // App is in foreground, clear notifications for this chat
      _clearNotificationsForThisChat();
      _markAllMessagesAsRead();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = await StorageService.getUserId();
      if (mounted) {
        setState(() => _currentUserId = userId);
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _initializeChat() async {
    try {
      setState(() => _isLoading = true);

      setState(() {
        _otherUserId = widget.otherUserSecureId;
        _isLoading = false;
      });

      _listenToMessages();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to load chat: $e');
      }
    }
  }

  void _listenToMessages() {
    if (_otherUserId == null) return;

    _messagesSubscription = FirebaseMessageService.getMessages(_otherUserId!)
        .listen(
          (messages) {
            if (mounted) {
              setState(() => _messages = messages);
              _scrollToBottom();
              
              // Mark messages as read when they arrive
              _markAllMessagesAsRead();
            }
          },
          onError: (error) {
            print('Error listening to messages: $error');
            if (mounted) {
              Helpers.showSnackBar(context, 'Error loading messages: $error');
            }
          },
        );
<<<<<<< HEAD
    }

  // NEW: Mark all messages as read
    Future<void> _markAllMessagesAsRead() async {
      try {
        for (final message in _messages) {
          if (!message.isRead && message.senderId != _currentUserId) {
            await FirebaseMessageService.markMessageAsRead(
              message.id,
              message.senderId,
            );
          }
        }
        print('Marked ${_messages.length} messages as read');
      } catch (e) {
        print('Error marking messages as read: $e');
      }
    }
=======
  }

  // NEW: Mark all messages as read
  Future<void> _markAllMessagesAsRead() async {
    try {
      for (final message in _messages) {
        if (!message.isRead && message.senderId != _currentUserId) {
          await FirebaseMessageService.markMessageAsRead(
            message.id,
            message.senderId,
          );
        }
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7

  Future<void> _loadDisappearingTimer() async {
    try {
      final timer = await StorageService.getDisappearingMessageTimer();
      if (mounted) {
        setState(() => _disappearingTimer = timer);
      }
    } catch (e) {
      print('Error loading disappearing timer: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients && mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      print('Sending message: "${text.length > 50 ? "${text.substring(0, 50)}..." : text}"');
      
      final success = await FirebaseMessageService.sendMessage(
        receiverSecureId: widget.otherUserSecureId,
        content: text,
        type: MessageType.text,
        expiresInSeconds: _disappearingTimer > 0 ? _disappearingTimer : null,
      );

      if (success) {
        _messageController.clear();
        _scrollToBottom();
        print('Message sent successfully');
      } else {
        Helpers.showSnackBar(context, 'Failed to send message');
        print('Message sending failed');
      }
    } catch (e) {
      Helpers.showSnackBar(context, 'Error sending message: $e');
      print('Error sending message: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showDisappearingMessagesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.timer, color: AppColors.primaryCyan, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Disappearing Messages',
              style: TextStyle(
                color: _getTextPrimaryColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set timer for new messages:',
              style: TextStyle(
                color: _getTextSecondaryColor(context),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            ...[
              {'label': 'Off', 'value': 0, 'icon': Icons.timer_off},
              {'label': '1 Hour', 'value': 3600, 'icon': Icons.timer_3},
              {'label': '24 Hours', 'value': 86400, 'icon': Icons.today},
              {
                'label': '7 Days',
                'value': 604800,
                'icon': Icons.calendar_view_week,
              },
              {
                'label': '30 Days',
                'value': 2592000,
                'icon': Icons.calendar_month,
              },
            ].map(
              (option) => Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: _disappearingTimer == option['value']
                      ? AppColors.primaryCyan.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RadioListTile<int>(
                  activeColor: AppColors.primaryCyan,
                  title: Row(
                    children: [
                      Icon(
                        option['icon'] as IconData,
                        color: _disappearingTimer == option['value']
                            ? AppColors.primaryCyan
                            : _getTextSecondaryColor(context),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        option['label'] as String,
                        style: TextStyle(
                          color: _getTextPrimaryColor(context),
                          fontWeight: _disappearingTimer == option['value']
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  value: option['value'] as int,
                  groupValue: _disappearingTimer,
                  onChanged: (value) {
                    setState(() => _disappearingTimer = value ?? 0);
                    Navigator.pop(context);
                    _saveDisappearingTimer();
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _getTextSecondaryColor(context),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDisappearingTimer() async {
    try {
      await StorageService.setDisappearingMessageTimer(_disappearingTimer);

      String timerText = 'Off';
      if (_disappearingTimer > 0) {
        if (_disappearingTimer < 86400) {
          timerText = '${(_disappearingTimer / 3600).round()} hour(s)';
        } else {
          timerText = '${(_disappearingTimer / 86400).round()} day(s)';
        }
      }

      Helpers.showSnackBar(context, 'Disappearing messages: $timerText');
    } catch (e) {
      Helpers.showSnackBar(context, 'Error saving timer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryCyan),
                  const SizedBox(height: 16),
                  Text(
                    'Loading messages...',
                    style: TextStyle(
                      color: _getTextSecondaryColor(context),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  if (_disappearingTimer > 0)
                    _buildDisappearingMessagesBanner(),
                  Expanded(child: _buildMessagesList()),
                  _buildMessageInputArea(),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: AppGradients.appBarGradient),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Helpers.getColorFromId(widget.otherUserSecureId),
            child: Text(
              Helpers.getInitials(widget.otherUserSecureId),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserSecureId,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
                if (_isOtherUserOnline)
                  const Text(
                    'Online',
                    style: TextStyle(fontSize: 12, color: Colors.greenAccent),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: PopupMenuButton<String>(
            color: _getSurfaceColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            icon: Icon(Icons.more_vert, color: AppColors.textOnPrimary),
            onSelected: (value) {
              if (value == 'disappearing') {
                _showDisappearingMessagesDialog();
              } else if (value == 'clear_chat') {
                _showClearChatDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'disappearing',
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.timer,
                      color: AppColors.primaryCyan,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Disappearing Messages',
                    style: TextStyle(
                      color: _getTextPrimaryColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    _disappearingTimer > 0
                        ? _getTimerText(_disappearingTimer)
                        : 'Off',
                    style: TextStyle(color: _getTextSecondaryColor(context)),
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'clear_chat',
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: AppColors.errorRed,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Clear Chat',
                    style: TextStyle(
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisappearingMessagesBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryCyan.withOpacity(0.1),
            AppColors.primaryCyan.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryCyan.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.timer, size: 14, color: AppColors.primaryCyan),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Messages disappear after ${_getTimerText(_disappearingTimer)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryCyan,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryCyan.withOpacity(0.2),
                      AppColors.primaryCyan.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock, size: 40, color: AppColors.primaryCyan),
              ),
              const SizedBox(height: 24),
              Text(
                'This chat is end-to-end encrypted',
                style: TextStyle(
                  fontSize: 18,
                  color: _getTextPrimaryColor(context),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Send your first message to start the conversation',
                style: TextStyle(
                  color: _getTextSecondaryColor(context),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == _currentUserId;

        return ChatBubble(
          message: message,
          isMe: isMe,
          showTimestamp: _shouldShowTimestamp(index),
        );
      },
    );
  }

  bool _shouldShowTimestamp(int index) {
    if (index == 0) return true;
    final current = _messages[index];
    final previous = _messages[index - 1];
    return current.timestamp.difference(previous.timestamp).inMinutes > 30;
  }

  Widget _buildMessageInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getSurfaceColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(child: _buildMessageInput()),
            const SizedBox(width: 12),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: _getInputBackgroundColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getDividerColor(context).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              style: TextStyle(color: _getTextPrimaryColor(context)),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: _getTextSecondaryColor(context)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
              maxLength: 4096,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    maxLength,
                    required isFocused,
                  }) => null,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Icon(
                Icons.attach_file,
                color: AppColors.primaryCyan,
                size: 20,
              ),
              onPressed: _showAttachmentOptions,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryCyan,
            AppColors.primaryCyan.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryCyan.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _isSending ? null : _sendMessage,
          child: Center(
            child: _isSending
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      backgroundColor: _getSurfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _getTextSecondaryColor(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Attachment Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(Icons.camera_alt, 'Camera', 'camera'),
                _buildAttachmentOption(
                  Icons.photo_library,
                  'Gallery',
                  'gallery',
                ),
                _buildAttachmentOption(Icons.insert_drive_file, 'File', 'file'),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, String type) {
    return InkWell(
      onTap: () => _handleAttachment(type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: AppColors.primaryCyan),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: _getTextPrimaryColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
Future<void> _handleAttachment(String type) async {
  Navigator.pop(context);
  
  try {
    switch (type) {
      case 'camera':
        await _pickImageFromCamera();
        break;
      case 'gallery':
        await _pickImageFromGallery();
        break;
      case 'file':
        await _pickFile();
        break;
    }
  } catch (e) {
    Helpers.showSnackBar(context, 'Error handling attachment: $e');
  }
}

// Add these new methods:
Future<void> _pickImageFromCamera() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 1920,
    maxHeight: 1080,
    imageQuality: 85,
  );
  
  if (image != null) {
    await _sendImageMessage(image.path);
  }
}

Future<void> _pickImageFromGallery() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1920,
    maxHeight: 1080,
    imageQuality: 85,
  );
  
  if (image != null) {
    await _sendImageMessage(image.path);
  }
}

Future<void> _pickFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    allowMultiple: false,
  );

  if (result != null && result.files.isNotEmpty) {
    final file = result.files.first;
    if (file.path != null) {
      await _sendFileMessage(file.path!, file.name);
    }
  }
}

Future<void> _sendImageMessage(String imagePath) async {
  setState(() => _isSending = true);
  
  try {
    // For now, send as text with image indicator
    // In production, you'd upload the image and send the URL
    final success = await FirebaseMessageService.sendMessage(
      receiverSecureId: widget.otherUserSecureId,
      content: 'Photo: ${imagePath.split('/').last}',
      type: MessageType.image,
      expiresInSeconds: _disappearingTimer > 0 ? _disappearingTimer : null,
    );

    if (success) {
      _scrollToBottom();
      Helpers.showSnackBar(context, 'Photo sent!');
    } else {
      Helpers.showSnackBar(context, 'Failed to send photo');
    }
  } catch (e) {
    Helpers.showSnackBar(context, 'Error sending photo: $e');
  } finally {
    if (mounted) {
      setState(() => _isSending = false);
    }
  }
}

Future<void> _sendFileMessage(String filePath, String fileName) async {
  setState(() => _isSending = true);
  
  try {
    final file = File(filePath);
    final fileSize = await file.length();
    final fileSizeKB = (fileSize / 1024).round();
    
    final success = await FirebaseMessageService.sendMessage(
      receiverSecureId: widget.otherUserSecureId,
      content: '$fileName (${fileSizeKB}KB)',
      type: MessageType.file,
      expiresInSeconds: _disappearingTimer > 0 ? _disappearingTimer : null,
    );

    if (success) {
      _scrollToBottom();
      Helpers.showSnackBar(context, 'File sent!');
    } else {
      Helpers.showSnackBar(context, 'Failed to send file');
    }
  } catch (e) {
    Helpers.showSnackBar(context, 'Error sending file: $e');
  } finally {
    if (mounted) {
      setState(() => _isSending = false);
    }
  }
}
=======

  void _handleAttachment(String type) {
    Navigator.pop(context);
    Helpers.showSnackBar(context, '$type attachment coming soon!');
  }
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_forever,
                color: AppColors.errorRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Clear Chat',
              style: TextStyle(
                color: _getTextPrimaryColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'This will delete all messages in this chat. This action cannot be undone.',
          style: TextStyle(color: _getTextSecondaryColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _getTextSecondaryColor(context),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _clearChat();
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearChat() async {
    if (_otherUserId == null) {
      Helpers.showSnackBar(context, 'Cannot clear chat: missing user ID');
      return;
    }

    try {
      final success = await FirebaseMessageService.clearChat(_otherUserId!);
      if (success) {
        Helpers.showSnackBar(context, 'Chat cleared successfully');
        setState(() => _messages.clear());
      } else {
        Helpers.showSnackBar(context, 'Failed to clear chat');
      }
    } catch (e) {
      Helpers.showSnackBar(context, 'Failed to clear chat: $e');
    }
  }

  String _getTimerText(int seconds) {
    if (seconds < 3600) {
      return '${(seconds / 60).round()} minutes';
    } else if (seconds < 86400) {
      return '${(seconds / 3600).round()} hours';
    } else {
      return '${(seconds / 86400).round()} days';
    }
  }
}