import 'package:flutter/material.dart';
import 'package:symme/utils/colors.dart';
import '../models/call.dart';
import '../services/call_service.dart';
import '../utils/helpers.dart';

class CallsTab extends StatefulWidget {
  final String? searchQuery;
  const CallsTab({super.key, this.searchQuery});

  @override
  State<CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends State<CallsTab> {
  List<Call> _calls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalls();
  }

  Future<void> _loadCalls() async {
    try {
      final calls = await CallService.getRecentCalls();
      if (mounted) {
        setState(() {
          _calls = calls;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading calls: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.backgroundPrimary
        : Colors.grey.shade50;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _getBackgroundColor(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_calls.isEmpty) {
      return Scaffold(
        backgroundColor: _getBackgroundColor(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
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
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.call, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 32),
                Text(
                  "No Call History",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Your call history will appear here.\nMake your first call to get started!",
                  style: TextStyle(
                    fontSize: 16,
                    color: _getTextSecondaryColor(context),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      body: RefreshIndicator(
        onRefresh: _loadCalls,
        child: ListView.builder(
          itemCount: _calls.length,
          itemBuilder: (context, index) {
            final call = _calls[index];
            return _buildCallItem(context, call);
          },
        ),
      ),
    );
  }

  Widget _buildCallItem(BuildContext context, Call call) {
    final isIncoming = call.status == CallStatus.incoming || call.status == CallStatus.missed;
    final isSuccessful = call.status == CallStatus.ended && call.duration != null;
    final isMissed = call.status == CallStatus.missed;
    
    IconData statusIcon;
    Color statusColor;
    
    if (isMissed) {
      statusIcon = Icons.call_missed;
      statusColor = AppColors.errorRed;
    } else if (isIncoming) {
      statusIcon = Icons.call_received;
      statusColor = AppColors.successGreen;
    } else {
      statusIcon = Icons.call_made;
      statusColor = _getTextSecondaryColor(context);
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Helpers.getColorFromId(
          call.receiverName ?? call.callerName ?? call.callerId,
        ),
        child: Text(
          Helpers.getInitials(
            call.receiverName ?? call.callerName ?? call.callerId,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        call.receiverName ?? call.callerName ?? call.callerId,
        style: TextStyle(
          color: _getTextPrimaryColor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 4),
          Icon(
            call.type == CallType.video ? Icons.videocam : Icons.call,
            size: 16,
            color: _getTextSecondaryColor(context),
          ),
          const SizedBox(width: 4),
          Text(
            isSuccessful 
                ? call.formattedDuration
                : _getStatusText(call.status),
            style: TextStyle(
              color: isMissed ? AppColors.errorRed : _getTextSecondaryColor(context),
              fontWeight: isMissed ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
      trailing: Text(
        Helpers.formatTime(call.timestamp),
        style: TextStyle(
          color: _getTextSecondaryColor(context),
          fontSize: 12,
        ),
      ),
    );
  }

  String _getStatusText(CallStatus status) {
    switch (status) {
      case CallStatus.missed:
        return 'Missed';
      case CallStatus.declined:
        return 'Declined';
      case CallStatus.failed:
        return 'Failed';
      case CallStatus.ended:
        return 'Ended';
      default:
        return status.toString().split('.').last;
    }
  }
}