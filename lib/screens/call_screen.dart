import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call.dart';
import '../services/webrtc_service.dart';
import '../services/call_service.dart';
import '../utils/helpers.dart';
import '../utils/colors.dart';
import '../services/call_manager.dart';

class CallScreen extends StatefulWidget {
  final Call call;
  final bool isIncoming;

  const CallScreen({super.key, required this.call, required this.isIncoming});

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  final WebRTCService _webRTCService = WebRTCService.instance;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isConnected = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerEnabled = false;

  CallStatus _callStatus = CallStatus.connecting;
  Timer? _callTimer;
  int _callDuration = 0;

  StreamSubscription<MediaStream>? _localStreamSubscription;
  StreamSubscription<MediaStream>? _remoteStreamSubscription;
  StreamSubscription<CallStatus>? _callStatusSubscription;

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Get theme-aware colors
  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.backgroundPrimary
        : Colors.grey.shade900;
  }

  Color _getTextPrimaryColor(BuildContext context) {
    return Colors.white; // Always white for call screen
  }

  Color _getTextSecondaryColor(BuildContext context) {
    return Colors.white.withOpacity(0.8);
  }

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _initializeAnimations();
    _initializeCall();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _localStreamSubscription?.cancel();
    _remoteStreamSubscription?.cancel();
    _callStatusSubscription?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeIn));

    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }

  Future<void> _initializeCall() async {
    try {
      _listenToStreams();
      _listenToCallStatus();

      if (widget.isIncoming) {
        setState(() {
          _callStatus = CallStatus.incoming;
        });
      } else {
        await _webRTCService.startCall(
          receiverId: widget.call.receiverId,
          callType: widget.call.type,
        );
        setState(() {
          _callStatus = CallStatus.outgoing;
        });
      }
    } catch (e) {
      _showError('Failed to initialize call: ${e.toString()}');
      _endCall();
    }
  }

  void _listenToStreams() {
    _localStreamSubscription = _webRTCService.localStream.listen((stream) {
      setState(() {
        _localRenderer.srcObject = stream;
      });
    });

    _remoteStreamSubscription = _webRTCService.remoteStream.listen((stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
        _isConnected = true;
      });
      _startCallTimer();
    });
  }

  void _listenToCallStatus() {
    _callStatusSubscription = _webRTCService.callStatus.listen((status) {
      setState(() {
        _callStatus = status;
      });

      switch (status) {
        case CallStatus.connected:
          _startCallTimer();
          break;
        case CallStatus.ended:
          _endCall();
          break;
        case CallStatus.failed:
          _showError('Call failed');
          _endCall();
          break;
        default:
          break;
      }
    });
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleMute() async {
    await _webRTCService.toggleMicrophone();
    setState(() {
      _isMuted = !_webRTCService.isMicrophoneEnabled;
    });
  }

  Future<void> _toggleVideo() async {
    if (widget.call.type == CallType.video) {
      await _webRTCService.toggleCamera();
      setState(() {
        _isVideoEnabled = _webRTCService.isCameraEnabled;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (widget.call.type == CallType.video) {
      await _webRTCService.switchCamera();
    }
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerEnabled = !_isSpeakerEnabled;
    });
  }

  Future<void> _endCall() async {
    try {
      await _webRTCService.endCall();
      await CallService.endCall(widget.call.id, duration: _callDuration);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _declineCall() async {
    try {
      await _webRTCService.declineCall(widget.call.id);
      await CallService.declineCall(widget.call.id);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      Helpers.showSnackBar(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      body: SafeArea(
        child: Stack(
          children: [
            _buildVideoBackground(),
            _buildGradientOverlay(),
            _buildTopBar(),
            _buildUserInfo(),
            _buildControlButtons(),
            if (widget.call.type == CallType.video && _isVideoEnabled)
              _buildLocalVideoPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoBackground() {
    if (widget.call.type == CallType.video &&
        _isConnected &&
        _remoteRenderer.srcObject != null) {
      return Positioned.fill(
        child: RTCVideoView(
          _remoteRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryCyan.withOpacity(0.3),
            _getBackgroundColor(context),
            AppColors.primaryCyan.withOpacity(0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    if (widget.call.type == CallType.video && _isConnected) {
      return Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.transparent,
                Colors.black.withOpacity(0.6),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryCyan.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.call.type == CallType.video
                        ? Icons.videocam
                        : Icons.call,
                    color: AppColors.primaryCyan,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.call.type == CallType.video
                        ? 'Video Call'
                        : 'Voice Call',
                    style: TextStyle(
                      color: _getTextPrimaryColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_isConnected)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'End-to-End Encrypted',
                      style: TextStyle(
                        color: _getTextPrimaryColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Positioned.fill(
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User Avatar with pulse animation
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale:
                        _callStatus == CallStatus.connecting ||
                            _callStatus == CallStatus.outgoing
                        ? _pulseAnimation.value
                        : 1.0,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Helpers.getColorFromId(
                              widget.call.receiverName ??
                                  widget.call.receiverId,
                            ),
                            Helpers.getColorFromId(
                              widget.call.receiverName ??
                                  widget.call.receiverId,
                            ).withOpacity(0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryCyan.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          Helpers.getInitials(
                            widget.call.receiverName ?? widget.call.receiverId,
                          ),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _getTextPrimaryColor(context),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Contact name
              Text(
                widget.call.receiverName ?? widget.call.receiverId,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _getTextPrimaryColor(context),
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Call status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: _getTextSecondaryColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Call duration
              if (_callDuration > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryCyan.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    _formatDuration(_callDuration),
                    style: TextStyle(
                      color: _getTextPrimaryColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: widget.isIncoming && _callStatus == CallStatus.incoming
              ? _buildIncomingCallControls()
              : _buildActiveCallControls(),
        ),
      ),
    );
  }

// Only the fixed accept button section from CallScreen
  Widget _buildIncomingCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.call_end,
          backgroundColor: AppColors.errorRed,
          size: 70,
          onPressed: _declineCall,
          label: 'Decline',
        ),
        _buildControlButton(
          icon: Icons.call,
          backgroundColor: AppColors.successGreen,
          size: 70,
<<<<<<< HEAD
        onPressed: () async {
          try {
            setState(() {
              _callStatus = CallStatus.connecting;
            });

            // Answer the call through CallManager - FIXED
            await CallManager.instance.answerCall(widget.call);

            print('Call answered successfully');
          } catch (e) {
            print('Error accepting call: $e');
            _showError('Failed to accept call: ${e.toString()}');

            // Reset status on error
            setState(() {
              _callStatus = CallStatus.incoming;
            });
          }
        },
=======
          onPressed: () async {
            try {
              setState(() {
                _callStatus = CallStatus.connecting;
              });

              // Answer the call through CallManager
              await CallManager.instance.answerCall(widget.call);

              print('Call answered successfully');
            } catch (e) {
              print('Error accepting call: $e');
              _showError('Failed to accept call: ${e.toString()}');

              // Reset status on error
              setState(() {
                _callStatus = CallStatus.incoming;
              });
            }
          },
>>>>>>> 820952c0717f9cdac2a2dbc29d315ff596adbca7
          label: 'Accept',
        ),
      ],
    );
  }
  Widget _buildActiveCallControls() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 10,
      children: [
        _buildControlButton(
          icon: _isMuted ? Icons.mic_off : Icons.mic,
          isActive: _isMuted,
          onPressed: _toggleMute,
          label: _isMuted ? 'Unmute' : 'Mute',
        ),
        if (widget.call.type == CallType.video)
          _buildControlButton(
            icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            isActive: !_isVideoEnabled,
            onPressed: _toggleVideo,
            label: _isVideoEnabled ? 'Camera Off' : 'Camera On',
          ),
        _buildControlButton(
          icon: Icons.call_end,
          backgroundColor: AppColors.errorRed,
          size: 70,
          onPressed: _endCall,
          label: 'End Call',
        ),
        _buildControlButton(
          icon: _isSpeakerEnabled ? Icons.volume_up : Icons.volume_down,
          isActive: _isSpeakerEnabled,
          onPressed: _toggleSpeaker,
          label: _isSpeakerEnabled ? 'Speaker Off' : 'Speaker',
        ),
        if (widget.call.type == CallType.video)
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            onPressed: _switchCamera,
            label: 'Flip',
          ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
    Color? backgroundColor,
    double size = 60,
    String? label,
  }) {
    final effectiveColor =
        backgroundColor ??
        (isActive ? AppColors.primaryCyan : Colors.white.withOpacity(0.2));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: effectiveColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: effectiveColor.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.4),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: _getTextSecondaryColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocalVideoPreview() {
    return Positioned(
      top: 100,
      right: 20,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryCyan.withOpacity(0.8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: RTCVideoView(
              _localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (_callStatus) {
      case CallStatus.outgoing:
        return 'Calling...';
      case CallStatus.incoming:
        return 'Incoming call';
      case CallStatus.connecting:
        return 'Connecting...';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.ended:
        return 'Call ended';
      case CallStatus.declined:
        return 'Call declined';
      case CallStatus.failed:
        return 'Call failed';
      default:
        return '';
    }
  }
}
