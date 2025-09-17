import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../utils/helpers.dart';

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
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        contact.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ID: ${contact.publicId}',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Colors.grey[600],
            ),
          ),
          if (contact.isOnline)
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Online',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            )
          else if (contact.lastSeen != null)
            Text(
              'Last seen: ${contact.lastSeen}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
        ],
      ),
      trailing: showActions
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: onCall,
                  tooltip: 'Call',
                ),
                IconButton(
                  icon: const Icon(Icons.message),
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
