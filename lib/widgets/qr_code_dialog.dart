import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';

class QRCodeDialog extends StatelessWidget {
  final String publicId;

  const QRCodeDialog({super.key, required this.publicId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderSecondary),
      ),
      title: Text(
        'Your Secure ID',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border.all(color: AppColors.borderPrimary),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Placeholder for QR Code
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderSecondary),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.backgroundSecondary,
                  ),
                  child: const Icon(
                    Icons.qr_code,
                    size: 100,
                    color: AppColors.primaryCyan,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  publicId,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Others can scan this QR code or enter your Secure ID to connect with you securely.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: AppColors.primaryCyan),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryCyan,
            foregroundColor: AppColors.textOnPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _shareId(context),
          child: const Text('Share'),
        ),
      ],
    );
  }

  void _shareId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: publicId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Secure ID copied to clipboard'),
        backgroundColor: AppColors.primaryCyanDark,
      ),
    );
    Navigator.pop(context);
  }
}
