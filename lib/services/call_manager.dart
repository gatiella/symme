// services/call_manager.dart - Fixed version
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:symme/screens/call_screen.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/call.dart';
import '../services/call_service.dart';
import '../services/webrtc_service.dart';
import '../services/navigation_service.dart';
import '../services/presence_service.dart';
import '../utils/colors.dart';

class CallManager {
  static CallManager? _instance;
  static CallManager get instance => _instance ??= CallManager._();

  CallManager._();

  final WebRTCService _webRTCService = WebRTCService.instance;

  StreamSubscription<Call>? _incomingCallSubscription;
  StreamSubscription<Map<String, dynamic>>? _callSignalSubscription;

  Call? _currentCall;
  Timer? _ringtoneTimer;
  Timer? _callTimeoutTimer;

  // Track processed calls to prevent duplicates
  final Set<String> _processedCalls = <String>{};
  final Set<String> _processedSignals = <String>{};

  bool get hasActiveCall => _currentCall != null;
  Call? get currentCall => _currentCall;

  Future<void> initialize(BuildContext context) async {
    try {
      print('Initializing CallManager...');

      // Initialize services
      await CallService.initialize();
      await _webRTCService.initialize();
      await PresenceService.initialize();

      _listenForIncomingCalls();
      _listenForCallSignals();

      print('CallManager initialized successfully');
    } catch (e) {
      print('Error initializing CallManager: $e');
      rethrow;
    }
  }

  void _listenForIncomingCalls() {
    _incomingCallSubscription = CallService.incomingCalls.listen(
          (call) {
        // Prevent duplicate processing
        if (_processedCalls.contains(call.id)) {
          print('Ignoring duplicate incoming call: ${call.id}');
          return;
        }

        _processedCalls.add(call.id);
        print('Received incoming call: ${call.id}');
        _handleIncomingCall(call);
      },
      onError: (error) {
        print('Error listening for incoming calls: $error');
      },
    );
  }

  void _listenForCallSignals() {
    _callSignalSubscription = CallService.callSignals.listen(
          (signal) {
        // Generate a unique ID for this signal to prevent duplicates
        final signalKey = '${signal['callId']}_${signal['type']}_${signal['timestamp']}';

        if (_processedSignals.contains(signalKey)) {
          print('Ignoring duplicate signal: ${signal['type']} for call ${signal['callId']}');
          return;
        }

        _processedSignals.add(signalKey);
        print('Received call signal: ${signal['type']} for call ${signal['callId']}');
        _handleCallSignal(signal);
      },
      onError: (error) {
        print('Error listening for call signals: $error');
      },
    );
  }

  void _handleIncomingCall(Call call) {
    if (_currentCall != null) {
      print('Already in a call, declining incoming call: ${call.id}');
      declineCall(call);
      return;
    }

    _currentCall = call;
    _startRingtone();
    _showIncomingCallScreen(call);
  }

  void _handleCallSignal(Map<String, dynamic> signal) async {
    try {
      // Validate signal structure
      if (!signal.containsKey('type') ||
          !signal.containsKey('callId') ||
          !signal.containsKey('data')) {
        print('Invalid signal structure: missing required fields');
        return;
      }

      final type = signal['type'] as String?;
      final callId = signal['callId'] as String?;
      final data = signal['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

      if (type == null || callId == null) {
        print('Invalid signal: type or callId is null');
        return;
      }

      print('Processing signal type: $type for call: $callId');

      switch (type) {
        case 'offer':
        // Handle incoming call offer
          final callType = signal['callType'] == 'video'
              ? CallType.video
              : CallType.audio;
          final call = Call(
            id: callId,
            callerId: signal['senderId'] as String? ?? '',
            receiverId: signal['receiverId'] as String? ?? '',
            type: callType,
            status: CallStatus.incoming,
            timestamp: DateTime.now(),
          );

          // Store offer data in call metadata
          final callWithData = call.copyWith(metadata: data);
          _handleIncomingCall(callWithData);
          break;

        case 'answer':
        // Handle call answer
          _cancelCallTimeout();
          await _webRTCService.handleCallAnswer(data);
          break;

        case 'ice-candidate':
        // Handle ICE candidate
          await _webRTCService.handleIceCandidate(data);
          break;

        case 'decline':
        // Handle call decline
          _handleCallDeclined();
          break;

        case 'end':
        // Handle call end
          _handleCallEnded();
          break;

        case 'timeout':
        // Handle call timeout
          final reason = data['reason'] as String?;
          _handleCallTimeout(reason);
          break;

        default:
          print('Unknown signal type: $type');
          break;
      }
    } catch (e) {
      print('Error handling call signal: $e');
    }
  }

  Future<CallResult> startCall({
    required String receiverSecureId,
    required CallType callType,
  }) async {
    try {
      print('Starting call to $receiverSecureId');

      if (hasActiveCall) {
        return CallResult(
          success: false,
          error: 'Another call is already in progress',
        );
      }

      // Check if we have microphone available
      final hasMic = await _webRTCService.isMicrophoneAvailable();
      if (!hasMic) {
        return CallResult(
          success: false,
          error:
          'Microphone not available. Please connect a microphone and try again.',
        );
      }

      // For video calls, check camera availability
      if (callType == CallType.video) {
        final hasCamera = await _webRTCService.isCameraAvailable();
        if (!hasCamera) {
          return CallResult(
            success: false,
            error:
            'Camera not available. Please connect a camera or switch to audio call.',
          );
        }
      }

      // Enable wakelock to keep screen on
      await WakelockPlus.enable();

      try {
        // This will check if user is online and available
        final call = await CallService.initiateCall(
          receiverSecureId: receiverSecureId,
          callType: callType,
        );

        if (call == null) {
          await WakelockPlus.disable();
          return CallResult(success: false, error: 'Failed to initiate call');
        }

        _currentCall = call.copyWith(status: CallStatus.outgoing);

        // Set timeout for outgoing call (30 seconds)
        _setCallTimeout();

        // Show call screen
        _showCallScreen(_currentCall!, isIncoming: false);

        // Start WebRTC call
        await _webRTCService.startCall(
          receiverId: call.receiverId,
          callType: call.type,
        );

        return CallResult(success: true);
      } catch (e) {
        await WakelockPlus.disable();

        // Handle specific error messages
        String errorMessage = e.toString();
        if (errorMessage.contains('not available for calls')) {
          errorMessage = 'User is not available for calls right now';
        } else if (errorMessage.contains('not found')) {
          errorMessage = 'User not found';
        } else if (errorMessage.contains('another call')) {
          errorMessage = 'User is currently in another call';
        } else if (errorMessage.contains('Microphone access denied')) {
          errorMessage = 'Please allow microphone access to make calls';
        } else if (errorMessage.contains('No microphone found')) {
          errorMessage = 'No microphone detected. Please connect a microphone.';
        } else {
          errorMessage = 'Failed to start call: ${e.toString()}';
        }

        return CallResult(success: false, error: errorMessage);
      }
    } catch (e) {
      await WakelockPlus.disable();
      return CallResult(
        success: false,
        error: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  void _setCallTimeout() {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = Timer(const Duration(seconds: 30), () {
      print('Call timeout reached');
      _showTimeoutMessage('Call timeout - no answer');
      endCall();
    });
  }

  void _cancelCallTimeout() {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = null;
  }

  void _handleCallTimeout(String? reason) {
    _cancelCallTimeout();
    _stopRingtone();
    _currentCall = null;

    String message = 'Call ended';
    if (reason == 'no_answer') {
      message = 'No answer';
    } else if (reason == 'missed') {
      message = 'Call missed';
    }

    _showTimeoutMessage(message);
  }

  void _showTimeoutMessage(String message) {
    final context = NavigationService.currentContext;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.call_end, color: AppColors.errorRed, size: 20),
            const SizedBox(width: 12),
            Text(
              message,
              style: TextStyle(
                color: AppColors.errorRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> answerCall(Call call) async {
    try {
      print('Answering call: ${call.id}');

      _stopRingtone();
      await WakelockPlus.enable();

      _currentCall = call;
      await CallService.answerCall(call.id);
      _showCallScreen(call, isIncoming: true);

      // Handle the WebRTC answer if offer data is available
      if (call.metadata != null && call.metadata!.isNotEmpty) {
        await _webRTCService.answerCall(
          callId: call.id,
          offerData: call.metadata!,
          callType: call.type,
          callerId: call.callerId,
        );
      }
    } catch (e) {
      print('Error answering call: $e');
      await WakelockPlus.disable();
      _showErrorMessage('Failed to answer call: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> declineCall(Call call) async {
    try {
      print('Declining call: ${call.id}');

      _stopRingtone();
      await CallService.declineCall(call.id);
      await _webRTCService.declineCall(call.id);

      // Remove from processed sets
      _processedCalls.remove(call.id);
      _currentCall = null;
    } catch (e) {
      print('Error declining call: $e');
      _showErrorMessage('Error declining call');
    }
  }

  Future<void> endCall() async {
    try {
      print('Ending call');

      _stopRingtone();
      _cancelCallTimeout();
      await WakelockPlus.disable();

      if (_currentCall != null) {
        await CallService.endCall(_currentCall!.id);
        await _webRTCService.endCall();

        // Remove from processed sets
        _processedCalls.remove(_currentCall!.id);
        _currentCall = null;
      }
    } catch (e) {
      print('Error ending call: $e');
    }
  }

  void _handleCallDeclined() {
    print('Call was declined');
    _stopRingtone();
    _cancelCallTimeout();

    if (_currentCall != null) {
      _processedCalls.remove(_currentCall!.id);
    }
    _currentCall = null;

    _showMessage('Call declined', isError: false);
  }

  void _handleCallEnded() async {
    print('Call ended by remote');
    _stopRingtone();
    _cancelCallTimeout();
    await WakelockPlus.disable();

    if (_currentCall != null) {
      _processedCalls.remove(_currentCall!.id);
    }
    _currentCall = null;
  }

  void _showIncomingCallScreen(Call call) {
    NavigationService.push(CallScreen(call: call, isIncoming: true));
  }

  void _showCallScreen(Call call, {required bool isIncoming}) {
    NavigationService.push(CallScreen(call: call, isIncoming: isIncoming));
  }

  void _startRingtone() {
    _ringtoneTimer?.cancel();

    // Start vibration pattern
    _vibrate();

    // Repeat vibration every 3 seconds
    _ringtoneTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _vibrate();
    });
  }

  void _stopRingtone() {
    _ringtoneTimer?.cancel();
    _ringtoneTimer = null;
  }

  void _vibrate() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 1000);
      }
    } catch (e) {
      print('Error vibrating: $e');
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    final context = NavigationService.currentContext;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: isError ? AppColors.errorRed : AppColors.textOnPrimary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError ? AppColors.errorRed : AppColors.textOnPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.errorRed : AppColors.primaryCyan,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorMessage(String message) {
    _showMessage(message, isError: true);
  }

  // Get call status for UI display
  Future<String> getCallStatus(String secureId) async {
    return await CallService.getUserCallStatus(secureId);
  }

  // Check if calling is available
  Future<bool> isCallingAvailable() async {
    try {
      final hasMic = await _webRTCService.isMicrophoneAvailable();
      return hasMic;
    } catch (e) {
      print('Error checking calling availability: $e');
      return false;
    }
  }

  // Check if video calling is available
  Future<bool> isVideoCallingAvailable() async {
    try {
      final hasMic = await _webRTCService.isMicrophoneAvailable();
      final hasCamera = await _webRTCService.isCameraAvailable();
      return hasMic && hasCamera;
    } catch (e) {
      print('Error checking video calling availability: $e');
      return false;
    }
  }

  void dispose() {
    print('Disposing CallManager');
    _incomingCallSubscription?.cancel();
    _callSignalSubscription?.cancel();
    _stopRingtone();
    _cancelCallTimeout();

    // Clear processed sets
    _processedCalls.clear();
    _processedSignals.clear();

    _webRTCService.dispose();
    CallService.dispose();
    WakelockPlus.disable();
  }
}

// Result class for better error handling
class CallResult {
  final bool success;
  final String? error;

  CallResult({required this.success, this.error});
}