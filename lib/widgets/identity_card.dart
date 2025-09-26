import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';
import '../utils/helpers.dart';

class IdentityCard extends StatelessWidget {
  final String publicId;
  final VoidCallback? onTap;

  const IdentityCard({super.key, required this.publicId, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderSecondary),
      ),
      child: InkWell(
        onTap: onTap ?? () => _copyToClipboard(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primaryCyanDark,
                radius: 24,
                child: Icon(
                  Icons.person,
                  color: AppColors.textPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Secure ID',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      publicId,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to copy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryCyan,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.security,
                color: AppColors.onlineGreen,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: publicId));
    Helpers.showSnackBar(context, 'Secure ID copied to clipboard');
  }
}
