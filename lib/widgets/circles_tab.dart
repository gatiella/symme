import 'package:flutter/material.dart';
import 'package:symme/models/circle.dart';
import 'package:symme/screens/circle_details_screen.dart';
import 'package:symme/screens/create_circle_screen.dart';
import 'package:symme/services/firebase_circle_service.dart';
import 'package:symme/utils/colors.dart';

class CirclesTab extends StatefulWidget {
  final String userSecureId;
  final String? searchQuery; // Add this line

  const CirclesTab({super.key, required this.userSecureId, this.searchQuery});

  @override
  _CirclesTabState createState() => _CirclesTabState();
}

class _CirclesTabState extends State<CirclesTab> {
  // Get theme-aware colors based on brightness
  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.backgroundPrimary
        : Colors.grey.shade50;
  }

  Color _getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.surfaceCard
        : Colors.white;
  }

  Color _getTextPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.textPrimary
        : Colors.grey.shade900;
  }

  Color _getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondary
        : Colors.grey.shade600;
  }

  Color _getSurfaceVariantColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.backgroundSecondary
        : Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      body: StreamBuilder<List<Circle>>(
        stream: FirebaseCircleService.getCircles(widget.userSecureId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primaryCyan),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.errorRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading circles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _getTextPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(
                      fontSize: 14,
                      color: _getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final circles = snapshot.data!;
          return _buildCirclesList(circles);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryCyan,
        foregroundColor: Colors.white,
        elevation: 6,
        child: const Icon(Icons.add, size: 28),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  CreateCircleScreen(userSecureId: widget.userSecureId),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_outlined,
                size: 64,
                color: AppColors.primaryCyan.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Circles Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first circle to start connecting\nwith groups of friends and family',
              style: TextStyle(
                fontSize: 16,
                color: _getTextSecondaryColor(context),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateCircleScreen(userSecureId: widget.userSecureId),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Circle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryCyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCirclesList(List<Circle> circles) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: circles.length,
      itemBuilder: (context, index) {
        final circle = circles[index];
        return _buildCircleCard(circle);
      },
    );
  }

  Widget _buildCircleCard(Circle circle) {
    return Card(
      color: _getSurfaceColor(context),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CircleDetailsScreen(circle: circle),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Circle Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryCyan,
                      AppColors.primaryCyan.withOpacity(0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCyan.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.groups, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),

              // Circle Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      circle.name,
                      style: TextStyle(
                        color: _getTextPrimaryColor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${circle.members.length} member${circle.members.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: _getTextSecondaryColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCreatedDate(circle.createdAt),
                      style: TextStyle(
                        color: _getTextSecondaryColor(context).withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getSurfaceVariantColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: _getTextSecondaryColor(context),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCreatedDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return 'Created ${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return 'Created ${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return 'Created ${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return 'Created ${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else {
      return 'Created just now';
    }
  }
}
