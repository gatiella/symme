import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ConnectionStatus extends StatelessWidget {
  final String connectionStatus;
  final VoidCallback onRefresh;
  final VoidCallback onRegenerateId;
  final VoidCallback onCleanup;

  const ConnectionStatus({
    super.key,
    required this.connectionStatus,
    required this.onRefresh,
    required this.onRegenerateId,
    required this.onCleanup,
  });

  @override
  Widget build(BuildContext context) {
    final bool isConnected = connectionStatus.toLowerCase() == 'connected';

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: isConnected
                ? Colors
                      .green
                      .shade400 // Brighter green
                : connectionStatus.contains('failed')
                ? Colors.red.shade400
                : Colors.orange.shade400,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color:
                    (isConnected
                            ? Colors.green.shade400
                            : Colors.orange.shade400)
                        .withOpacity(0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        Text(
          connectionStatus,
          style: TextStyle(
            color: Colors.white, // Changed to white for visibility
            fontSize: 14,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.4),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          color: AppColors.surfaceCard,
          icon: const Icon(
            Icons.more_vert,
            color: Colors.white, // Changed to white for visibility
          ),
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                onRefresh();
                break;
              case 'regenerate_id':
                onRegenerateId();
                break;
              case 'cleanup':
                onCleanup();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'refresh',
              child: Text(
                "Refresh",
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            PopupMenuItem(
              value: 'regenerate_id',
              child: Text(
                "Regenerate ID",
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            PopupMenuItem(
              value: 'cleanup',
              child: Text(
                "Clean Messages",
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
