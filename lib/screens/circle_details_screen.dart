import 'package:flutter/material.dart';
import 'package:symme/models/circle.dart';
import 'package:symme/models/user.dart';
import 'package:symme/screens/search_user_screen.dart';
import 'package:symme/services/firebase_circle_service.dart';
import 'package:symme/services/firebase_user_service.dart';
import 'package:symme/services/storage_service.dart';
import 'package:symme/utils/colors.dart';
import 'package:symme/utils/helpers.dart';

class CircleDetailsScreen extends StatefulWidget {
  final Circle circle;

  const CircleDetailsScreen({super.key, required this.circle});

  @override
  _CircleDetailsScreenState createState() => _CircleDetailsScreenState();
}

class _CircleDetailsScreenState extends State<CircleDetailsScreen> {
  late Circle _currentCircle;
  String? _currentUserSecureId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentCircle = widget.circle;
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final secureId = await StorageService.getUserSecureId();
      setState(() {
        _currentUserSecureId = secureId;
      });
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

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

  Future<void> _addMember(AppUser user) async {
    if (_currentCircle.members.contains(user.secureId)) {
      _showSnackBar('User is already a member of this circle');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseCircleService.addMemberToCircle(
        _currentCircle.id,
        user.secureId,
      );

      setState(() {
        _currentCircle = _currentCircle.copyWith(
          members: [..._currentCircle.members, user.secureId],
        );
        _isLoading = false;
      });

      _showSnackBar('${user.name} added to circle');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to add member: ${e.toString()}');
    }
  }

  Future<void> _removeMember(String memberSecureId, String memberName) async {
    if (memberSecureId == _currentUserSecureId) {
      _showLeaveCircleDialog();
      return;
    }

    if (_currentCircle.createdBy != _currentUserSecureId) {
      _showSnackBar('Only circle creator can remove members');
      return;
    }

    final confirmed = await _showRemoveMemberDialog(memberName);
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseCircleService.removeMemberFromCircle(
        _currentCircle.id,
        memberSecureId,
      );

      setState(() {
        final updatedMembers = _currentCircle.members
            .where((id) => id != memberSecureId)
            .toList();
        _currentCircle = _currentCircle.copyWith(members: updatedMembers);
        _isLoading = false;
      });

      _showSnackBar('$memberName removed from circle');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to remove member: ${e.toString()}');
    }
  }

  Future<bool> _showRemoveMemberDialog(String memberName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _getSurfaceColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.person_remove, color: AppColors.errorRed),
                const SizedBox(width: 12),
                Text(
                  'Remove Member',
                  style: TextStyle(color: _getTextPrimaryColor(context)),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to remove $memberName from this circle?',
              style: TextStyle(color: _getTextSecondaryColor(context)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: _getTextSecondaryColor(context)),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showLeaveCircleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: AppColors.warningOrange),
            const SizedBox(width: 12),
            Text(
              'Leave Circle',
              style: TextStyle(color: _getTextPrimaryColor(context)),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to leave "${_currentCircle.name}"?',
          style: TextStyle(color: _getTextSecondaryColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: _getTextSecondaryColor(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveCircle();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warningOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveCircle() async {
    if (_currentUserSecureId == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseCircleService.removeMemberFromCircle(
        _currentCircle.id,
        _currentUserSecureId!,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('You left the circle');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to leave circle: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.primaryCyan,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentCircle.name,
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              '${_currentCircle.members.length} member${_currentCircle.members.length != 1 ? 's' : ''}',
              style: TextStyle(
                color: AppColors.textOnPrimary.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppGradients.appBarGradient),
        ),
        actions: [
          if (_currentCircle.createdBy == _currentUserSecureId)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppColors.textOnPrimary),
              color: _getSurfaceColor(context),
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteCircleDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppColors.errorRed),
                      const SizedBox(width: 8),
                      Text(
                        'Delete Circle',
                        style: TextStyle(color: AppColors.errorRed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryCyan),
            )
          : Column(
              children: [
                // Circle Info Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getSurfaceColor(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: Theme.of(context).brightness == Brightness.light
                        ? [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: AppGradients.appBarGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.groups,
                              color: AppColors.textOnPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Circle Info',
                                  style: TextStyle(
                                    color: _getTextPrimaryColor(context),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Created ${_formatCreatedDate(_currentCircle.createdAt)}',
                                  style: TextStyle(
                                    color: _getTextSecondaryColor(context),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Members Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Members',
                        style: TextStyle(
                          color: _getTextPrimaryColor(context),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentCircle.members.length}',
                          style: TextStyle(
                            color: AppColors.primaryCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Members List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _currentCircle.members.length,
                    itemBuilder: (context, index) {
                      final memberSecureId = _currentCircle.members[index];
                      return _buildMemberCard(memberSecureId);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryCyan,
        foregroundColor: Colors.white,
        onPressed: _isLoading ? null : () => _showAddMemberScreen(),
        child: const Icon(Icons.person_add, size: 24),
      ),
    );
  }

  Widget _buildMemberCard(String memberSecureId) {
    return FutureBuilder<AppUser?>(
      future: FirebaseUserService.getUserBySecureId(memberSecureId),
      builder: (context, snapshot) {
        return Card(
          color: _getSurfaceColor(context),
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: Theme.of(context).brightness == Brightness.light ? 1 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildMemberTile(snapshot, memberSecureId),
        );
      },
    );
  }

  Widget _buildMemberTile(
    AsyncSnapshot<AppUser?> snapshot,
    String memberSecureId,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.backgroundSecondary
              : Colors.grey.shade200,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryCyan,
          ),
        ),
        title: Text(
          'Loading...',
          style: TextStyle(color: _getTextSecondaryColor(context)),
        ),
      );
    }

    final bool isCurrentUser = memberSecureId == _currentUserSecureId;
    final bool isCreator = memberSecureId == _currentCircle.createdBy;

    if (!snapshot.hasData || snapshot.data == null) {
      // User not found - show secure ID with error state
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.errorRed.withOpacity(0.2),
          child: Icon(Icons.person_off, color: AppColors.errorRed, size: 20),
        ),
        title: Text(
          memberSecureId,
          style: TextStyle(
            color: _getTextPrimaryColor(context),
            fontFamily: 'monospace',
          ),
        ),
        subtitle: Text(
          'User not found or inactive',
          style: TextStyle(color: AppColors.errorRed, fontSize: 12),
        ),
        trailing:
            (!isCurrentUser && _currentCircle.createdBy == _currentUserSecureId)
            ? IconButton(
                icon: Icon(Icons.person_remove, color: AppColors.errorRed),
                onPressed: () => _removeMember(memberSecureId, memberSecureId),
              )
            : null,
      );
    }

    final user = snapshot.data!;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Helpers.getColorFromId(user.secureId),
        child: Text(
          Helpers.getInitials(user.name.isNotEmpty ? user.name : user.secureId),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              user.name.isNotEmpty ? user.name : user.secureId,
              style: TextStyle(
                color: _getTextPrimaryColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isCreator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Creator',
                style: TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (isCurrentUser && !isCreator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'You',
                style: TextStyle(
                  color: AppColors.primaryCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        user.secureId,
        style: TextStyle(
          color: _getTextSecondaryColor(context),
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
      trailing: _buildMemberActions(user, isCurrentUser, isCreator),
    );
  }

  Widget? _buildMemberActions(
    AppUser user,
    bool isCurrentUser,
    bool isCreator,
  ) {
    if (isCurrentUser) {
      return IconButton(
        icon: Icon(Icons.exit_to_app, color: AppColors.warningOrange),
        onPressed: () => _showLeaveCircleDialog(),
        tooltip: 'Leave Circle',
      );
    }

    if (_currentCircle.createdBy == _currentUserSecureId && !isCreator) {
      return IconButton(
        icon: Icon(Icons.person_remove, color: AppColors.errorRed),
        onPressed: () => _removeMember(user.secureId, user.name),
        tooltip: 'Remove Member',
      );
    }

    return null;
  }

  Future<void> _showAddMemberScreen() async {
    final selectedUser = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(builder: (context) => const SearchUserScreen()),
    );

    if (selectedUser != null) {
      await _addMember(selectedUser);
    }
  }

  void _showDeleteCircleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: AppColors.errorRed),
            const SizedBox(width: 12),
            Text(
              'Delete Circle',
              style: TextStyle(color: _getTextPrimaryColor(context)),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${_currentCircle.name}"? This action cannot be undone.',
          style: TextStyle(color: _getTextSecondaryColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: _getTextSecondaryColor(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCircle();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCircle() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseCircleService.deleteCircle(_currentCircle.id);

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Circle deleted successfully');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to delete circle: ${e.toString()}');
    }
  }

  String _formatCreatedDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else {
      return 'Today';
    }
  }
}
