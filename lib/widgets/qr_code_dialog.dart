import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QRCodeDialog extends StatelessWidget {
  final String publicId;

  const QRCodeDialog({super.key, required this.publicId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your Secure ID'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Placeholder for QR Code
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.qr_code,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  publicId,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Others can scan this QR code or enter your Secure ID to connect with you securely.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () => _shareId(context),
          child: const Text('Share'),
        ),
      ],
    );
  }

  void _shareId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: publicId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Secure ID copied to clipboard')),
    );
    Navigator.pop(context);
  }
}
