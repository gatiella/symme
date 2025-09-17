import 'package:flutter/material.dart';
import 'dart:async';
import '../models/message.dart';
import '../services/firebase_message_service.dart';
import '../services/storage_service.dart';
import '../widgets/chat_bubble.dart';
import '../utils/helpers.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserSecureId;

  const ChatScreen({Key? key, required this.otherUserSecureId})
    : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _otherUserId;
  String? _currentUserId; // Added current user ID state
  bool _isOtherUserOnline = false;
  int _disappearingTimer = 0;
  StreamSubscription<List<Message>>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
    _loadDisappearingTimer();
    _loadCurrentUser(); // Load current user ID
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = await StorageService.getUserId();
      if (mounted) {
        setState(() {
          _currentUserId = userId;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _initializeChat() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get other user's info from secure ID by trying to send a test message
      // This will validate the secure ID exists and get the user ID
      // For now, we'll use the secure ID as a placeholder and let the service handle it
      setState(() {
        _otherUserId =
            widget.otherUserSecureId; // Temporary - will be resolved in service
        _isLoading = false;
      });

      // Listen to messages
      _listenToMessages();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to load chat: ${e.toString()}');
      }
    }
  }

  void _listenToMessages() {
    if (_otherUserId == null) return;

    _messagesSubscription = FirebaseMessageService.getMessages(_otherUserId!)
        .listen(
          (messages) {
            if (mounted) {
              setState(() {
                _messages = messages;
              });
              _scrollToBottom();
            }
          },
          onError: (error) {
            print('Error listening to messages: $error');
            if (mounted) {
              Helpers.showSnackBar(
                context,
                'Error loading messages: ${error.toString()}',
              );
            }
          },
        );
  }

  Future<void> _loadDisappearingTimer() async {
    try {
      final timer = await StorageService.getDisappearingMessageTimer();
      if (mounted) {
        setState(() {
          _disappearingTimer = timer;
        });
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

    setState(() {
      _isSending = true;
    });

    try {
      final success = await FirebaseMessageService.sendMessage(
        receiverSecureId: widget.otherUserSecureId,
        content: text,
        type: MessageType.text,
        expiresInSeconds: _disappearingTimer > 0 ? _disappearingTimer : null,
      );

      if (success) {
        _messageController.clear();
        _scrollToBottom();
      } else {
        if (mounted) {
          Helpers.showSnackBar(context, 'Failed to send message');
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error sending message: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showDisappearingMessagesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disappearing Messages'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set timer for new messages:'),
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
                onChanged: (value) {
                  setState(() {
                    _disappearingTimer = value ?? 0;
                  });
                  Navigator.pop(context);
                  _saveDisappearingTimer();
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

      if (mounted) {
        Helpers.showSnackBar(context, 'Disappearing messages: $timerText');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error saving timer: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUserSecureId,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            if (_isOtherUserOnline)
              const Text(
                'Online',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'disappearing':
                  _showDisappearingMessagesDialog();
                  break;
                case 'clear_chat':
                  _showClearChatDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'disappearing',
                child: ListTile(
                  leading: Icon(
                    Icons.timer,
                    color: _disappearingTimer > 0 ? Colors.blue : null,
                  ),
                  title: const Text('Disappearing Messages'),
                  subtitle: Text(
                    _disappearingTimer > 0
                        ? _getTimerText(_disappearingTimer)
                        : 'Off',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_chat',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Clear Chat'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_disappearingTimer > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.blue.withOpacity(0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          'Messages disappear after ${_getTimerText(_disappearingTimer)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: _buildMessagesList()),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _buildMessageInput(),
                ),
              ],
            ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'This chat is end-to-end encrypted',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Send your first message to start the conversation',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        // Fixed: Use the actual current user ID from state
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

    final currentMessage = _messages[index];
    final previousMessage = _messages[index - 1];

    final timeDifference = currentMessage.timestamp.difference(
      previousMessage.timestamp,
    );
    return timeDifference.inMinutes > 30;
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: null,
                      maxLength: 4096,
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            maxLength,
                            required isFocused,
                          }) {
                            return null; // Hide counter
                          },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () => _showAttachmentOptions(),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send),
              onPressed: _isSending ? null : _sendMessage,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Attachment Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () => _handleAttachment('camera'),
                ),
                _buildAttachmentOption(
                  icon: Icons.photo,
                  label: 'Gallery',
                  onTap: () => _handleAttachment('gallery'),
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'File',
                  onTap: () => _handleAttachment('file'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _handleAttachment(String type) {
    Navigator.pop(context);

    // For now, just show a placeholder message
    if (mounted) {
      Helpers.showSnackBar(context, '$type attachment coming soon!');
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'This will delete all messages in this chat. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearChat();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearChat() async {
    if (_otherUserId == null) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Cannot clear chat: missing user ID');
      }
      return;
    }

    try {
      final success = await FirebaseMessageService.clearChat(_otherUserId!);
      if (mounted) {
        if (success) {
          Helpers.showSnackBar(context, 'Chat cleared successfully');
          setState(() {
            _messages.clear();
          });
        } else {
          Helpers.showSnackBar(context, 'Failed to clear chat');
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to clear chat: ${e.toString()}');
      }
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
