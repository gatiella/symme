import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../utils/helpers.dart';
import '../utils/colors.dart';

class ContactListItem extends StatelessWidget {
  final Contact contact;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final bool showActions;

  const ContactListItem({
    super.key,
    required this.contact,
    this.onTap,
    this.onCall,
    this.onMessage,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Helpers.getColorFromId(contact.publicId),
        child: Text(
          Helpers.getInitials(contact.name),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        contact.name,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ID: ${contact.publicId}',
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: AppColors.textSecondary,
            ),
          ),
          if (contact.isOnline)
            Row(
              children: const [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: AppColors.successGreen,
                ),
                SizedBox(width: 4),
                Text(
                  'Online',
                  style: TextStyle(fontSize: 12, color: AppColors.successGreen),
                ),
              ],
            )
          else if (contact.lastSeen != null)
            Text(
              'Last seen: ${contact.lastSeen}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
      trailing: showActions
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.call, color: AppColors.primaryCyan),
                  onPressed: onCall,
                  tooltip: 'Call',
                ),
                IconButton(
                  icon: const Icon(Icons.message, color: AppColors.primaryCyan),
                  onPressed: onMessage,
                  tooltip: 'Message',
                ),
              ],
            )
          : null,
      onTap: onTap,
    );
  }
}
