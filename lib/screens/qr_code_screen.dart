import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeScreen extends StatefulWidget {
  final String? publicId;
  final bool startInScanMode;

  const QrCodeScreen({super.key, this.publicId, this.startInScanMode = false});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  late bool _isScanning;

  @override
  void initState() {
    super.initState();
    _isScanning = widget.startInScanMode || widget.publicId == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isScanning ? 'Scan QR Code' : 'My Secure ID'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isScanning ? _buildScanner() : _buildQrDisplay(),
      ),
    );
  }

  Widget _buildQrDisplay() {
    final theme = Theme.of(context);
    final id = widget.publicId;

    if (id == null) {
      return Center(
        child: Text(
          'No Secure ID to display.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Share this Secure ID',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: id,
              version: QrVersions.auto,
              size: 250,
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          SelectableText(
            id,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => setState(() => _isScanning = true),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Another ID'),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    final theme = Theme.of(context);

    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            final code = capture.barcodes.firstOrNull?.rawValue;
            if (code != null) Navigator.of(context).pop(code);
          },
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.primary, width: 4),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        if (!widget.startInScanMode && widget.publicId != null)
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _isScanning = false),
            ),
          ),
      ],
    );
  }
}
