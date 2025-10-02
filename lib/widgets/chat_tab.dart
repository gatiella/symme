import 'package:flutter/material.dart';
import 'package:symme/services/presence_service.dart';
import '../services/firebase_message_service.dart';
import '../utils/helpers.dart';

class ChatTab extends StatefulWidget {
  final Function(String) onStartChat;
  final String? searchQuery;

  const ChatTab({super.key, required this.onStartChat, this.searchQuery});

  @override
  _ChatTabState createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  List<Map<String, dynamic>> _chatRooms = [];
  List<Map<String, dynamic>> _filteredChatRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  @override
  void didUpdateWidget(ChatTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _filterChats();
    }
  }

  void _loadChatRooms() {
    FirebaseMessageService.getChatRooms().listen(
      (chatRooms) {
        if (mounted) {
          setState(() {
            _chatRooms = chatRooms;
            _isLoading = false;
          });
          _filterChats();
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
          Helpers.showSnackBar(context, 'Failed to load chats: $error');
        }
      },
    );
  }

  void _filterChats() {
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) {
      _filteredChatRooms = List.from(_chatRooms);
    } else {
      final query = widget.searchQuery!.toLowerCase();
      _filteredChatRooms = _chatRooms.where((chatRoom) {
        final displayName = (chatRoom['displayName'] as String? ?? '')
            .toLowerCase();
        final lastMessage = (chatRoom['lastMessage'] as String? ?? '')
            .toLowerCase();
        final otherUserSecureId =
            (chatRoom['otherUserSecureId'] as String? ?? '').toLowerCase();

        return displayName.contains(query) ||
            lastMessage.contains(query) ||
            otherUserSecureId.contains(query);
      }).toList();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _buildContent(theme),
      floatingActionButton:
          widget.searchQuery == null || widget.searchQuery!.isEmpty
          ? FloatingActionButton(
              onPressed: _showStartChatDialog,
              backgroundColor: theme.colorScheme.primary,
              tooltip: 'Start New Chat',
              child: const Icon(Icons.add_comment, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_filteredChatRooms.isEmpty) {
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        return _buildNoSearchResults(theme);
      } else if (_chatRooms.isEmpty) {
        return _buildEmptyState(theme);
      }
    }

    return Column(
      children: [
        if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty)
          _buildSearchHeader(theme),
        Expanded(child: _buildChatList(theme)),
      ],
    );
  }

  Widget _buildSearchHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _filteredChatRooms.isEmpty
                  ? 'No results for "${widget.searchQuery}"'
                  : '${_filteredChatRooms.length} result${_filteredChatRooms.length == 1 ? '' : 's'} for "${widget.searchQuery}"',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for a different name,\nmessage, or secure ID.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _showStartChatDialog,
            icon: const Icon(Icons.add_comment),
            label: const Text('Start New Chat'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No Chats Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to start a new conversation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _filteredChatRooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        return _buildChatRoomItem(_filteredChatRooms[index], theme);
      },
    );
  }

Widget _buildChatRoomItem(Map<String, dynamic> chatRoom, ThemeData theme) {
  final otherUserSecureId = chatRoom['otherUserSecureId'] as String? ?? '';
  
  // Use FutureBuilder to check online status
  return FutureBuilder<bool>(
    future: PresenceService.isUserOnlineBySecureId(otherUserSecureId),
    builder: (context, snapshot) {
      final isOnline = snapshot.data ?? false;
      
      // Extract other chat room data
      final displayName = chatRoom['displayName'] as String? ?? otherUserSecureId;
      final lastMessage = chatRoom['lastMessage'] as String? ?? 'No messages yet';
      final lastMessageTime = chatRoom['lastMessageTime'] as int?;
      final unreadCount = chatRoom['unreadCount'] as int? ?? 0;

      String timeString = '';
      if (lastMessageTime != null) {
        final messageDate = DateTime.fromMillisecondsSinceEpoch(lastMessageTime);
        final now = DateTime.now();
        final difference = now.difference(messageDate);

        if (difference.inDays > 0) {
          timeString = '${difference.inDays}d ago';
        } else if (difference.inHours > 0) {
          timeString = '${difference.inHours}h ago';
        } else if (difference.inMinutes > 0) {
          timeString = '${difference.inMinutes}m ago';
        } else {
          timeString = 'Now';
        }
      }

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: theme.colorScheme.surface,
        elevation: unreadCount > 0 ? 4 : 2,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                child: Text(
                  displayName.isNotEmpty
                      ? displayName.substring(0, 2).toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              // Online status indicator with loading state
              if (snapshot.connectionState == ConnectionState.waiting)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: const SizedBox(
                      width: 8,
                      height: 8,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                )
              else if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  _highlightSearchTerm(displayName, widget.searchQuery),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: unreadCount > 0
                        ? FontWeight.bold
                        : FontWeight.w600,
                    fontSize: 16,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                _highlightSearchTerm(lastMessage, widget.searchQuery),
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: unreadCount > 0
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (timeString.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      timeString,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    // Add online status text for better accessibility
                    if (snapshot.connectionState != ConnectionState.waiting) ...[
                      const SizedBox(width: 8),
                      Text(
                        isOnline ? '• Online' : '• Offline',
                        style: TextStyle(
                          color: isOnline 
                              ? Colors.green.shade600 
                              : theme.colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          onTap: () {
            if (otherUserSecureId.isNotEmpty) {
              widget.onStartChat(otherUserSecureId);
            }
          },
          onLongPress: () => _showChatOptions(chatRoom),
        ),
      );
    },
  );
}

  String _highlightSearchTerm(String text, String? searchQuery) {
    // For now, just return the text as is
    // In a more advanced implementation, you could return RichText with highlighted terms
    return text;
  }

  void _showStartChatDialog() {
    final TextEditingController controller = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.chat_bubble, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              'Start New Chat',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the secure ID of the person you want to chat with:',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: 'e.g., ABC123XYZ789',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
                prefixIcon: Icon(
                  Icons.person_add,
                  color: theme.colorScheme.primary,
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 12,
            ),
            const SizedBox(height: 8),
            Text(
              'Secure IDs are 12 characters long and contain only letters and numbers.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final secureId = controller.text.trim().toUpperCase();
              if (_isValidSecureId(secureId)) {
                Navigator.pop(context);
                widget.onStartChat(secureId);
              } else {
                Helpers.showSnackBar(
                  context,
                  'Please enter a valid 12-character secure ID',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  bool _isValidSecureId(String id) {
    return RegExp(r'^[A-Z0-9]{12}$').hasMatch(id);
  }

  void _showChatOptions(Map<String, dynamic> chatRoom) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Chat Info',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                _showChatInfo(chatRoom);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.notifications_off_outlined,
                color: theme.colorScheme.tertiary,
              ),
              title: Text(
                'Mute Notifications',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                Helpers.showSnackBar(context, 'Mute feature coming soon!');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Clear Chat',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                _showClearChatDialog(chatRoom);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showChatInfo(Map<String, dynamic> chatRoom) {
    final theme = Theme.of(context);
    final otherUserSecureId = chatRoom['otherUserSecureId'] as String? ?? '';
    final displayName = chatRoom['displayName'] as String? ?? otherUserSecureId;
    final isOnline = chatRoom['isOnline'] as bool? ?? false;
    final lastSeen = chatRoom['lastSeen'] as int?;

    String lastSeenText = 'Unknown';
    if (isOnline) {
      lastSeenText = 'Online now';
    } else if (lastSeen != null) {
      final lastSeenDate = DateTime.fromMillisecondsSinceEpoch(lastSeen);
      final now = DateTime.now();
      final difference = now.difference(lastSeenDate);

      if (difference.inDays > 0) {
        lastSeenText =
            'Last seen ${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        lastSeenText =
            'Last seen ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        lastSeenText =
            'Last seen ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        lastSeenText = 'Last seen just now';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Chat Information',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                child: Text(
                  displayName.isNotEmpty
                      ? displayName.substring(0, 2).toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Secure ID:', displayName, theme),
            const SizedBox(height: 8),
            _buildInfoRow('Status:', lastSeenText, theme),
            const SizedBox(height: 8),
            _buildInfoRow('Encryption:', 'End-to-end encrypted', theme),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  void _showClearChatDialog(Map<String, dynamic> chatRoom) {
    final theme = Theme.of(context);
    final displayName = chatRoom['displayName'] as String? ?? 'Unknown';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: theme.colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Clear Chat',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to clear all messages with $displayName? This action cannot be undone.',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _clearChat(chatRoom);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearChat(Map<String, dynamic> chatRoom) async {
    try {
      final otherUserId = chatRoom['otherUserId'] as String?;
      if (otherUserId != null) {
        final success = await FirebaseMessageService.clearChat(otherUserId);
        if (success) {
          Helpers.showSnackBar(context, 'Chat cleared successfully');
          _loadChatRooms();
        } else {
          Helpers.showSnackBar(context, 'Failed to clear chat');
        }
      }
    } catch (e) {
      Helpers.showSnackBar(context, 'Error clearing chat: $e');
    }
  }
}
