// chat_bubble.dart
import 'package:flutter/material.dart';
import 'package:symme/utils/colors.dart';
import '../models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showTimestamp;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showTimestamp = false,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe
        ? AppColors.messageSent
        : AppColors.messageReceived;
    final textColor = isMe ? AppColors.textOnPrimary : AppColors.textPrimary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (showTimestamp) _buildTimestamp(),
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primaryAccent,
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowDark.withOpacity(0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMessageContent(textColor),
                      const SizedBox(height: 4),
                      _buildFooter(textColor),
                    ],
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  /// Timestamp divider
  Widget _buildTimestamp() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatTimestamp(message.timestamp),
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  /// Footer with icons + time + delivery status
  Widget _buildFooter(Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (message.isEncrypted)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.lock,
              size: 12,
              color: textColor.withOpacity(0.7),
            ),
          ),
        if (message.expiresInSeconds != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.timer,
              size: 12,
              color: textColor.withOpacity(0.7),
            ),
          ),
        Text(
          _formatTime(message.timestamp),
          style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 11),
        ),
        if (isMe) ...[const SizedBox(width: 4), _buildDeliveryStatus()],
      ],
    );
  }

  /// Build message types
  Widget _buildMessageContent(Color textColor) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage(textColor);
      case MessageType.image:
        return _buildImageMessage(textColor);
      case MessageType.file:
        return _buildFileMessage(textColor);
      case MessageType.voice:
        return _buildVoiceMessage(textColor);
      case MessageType.system:
        return _buildSystemMessage(textColor);
    }
  }

Widget _buildTextMessage(Color textColor) {
  // Check for various error states
  final isDecryptionError = message.content.contains('[Failed to decrypt message]') ||
      message.content.contains('[Decryption error]') ||
      message.content.contains('[Missing decryption data]') ||
      message.content.contains('[Message parsing failed]');

  if (isDecryptionError) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: AppColors.errorRed),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Message cannot be displayed',
                style: TextStyle(
                  color: AppColors.errorRed,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'This message may be corrupted or use an unsupported encryption method',
          style: TextStyle(
            color: textColor.withOpacity(0.7), 
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  return SelectableText(
    message.content,
    style: TextStyle(color: textColor, fontSize: 16),
  );
}
  Widget _buildImageMessage(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.image,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Image',
          style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFileMessage(Color textColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.insert_drive_file, color: AppColors.primaryCyan),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Document',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
              Text(
                message.content,
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceMessage(Color textColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.play_arrow, color: AppColors.primaryCyan),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 20,
                child: Row(
                  children: List.generate(
                    20,
                    (index) => Container(
                      width: 2,
                      height: (index % 3 + 1) * 5.0,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '0:${message.content}',
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemMessage(Color textColor) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: textColor.withOpacity(0.7)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            message.content,
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryStatus() {
    if (message.isRead) {
      return const Icon(Icons.done_all, size: 16, color: Colors.blue);
    } else if (message.isDelivered) {
      return const Icon(Icons.done_all, size: 16, color: Colors.white70);
    } else {
      return const Icon(Icons.done, size: 16, color: Colors.white70);
    }
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
