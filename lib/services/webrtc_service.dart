// services/webrtc_service.dart
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call.dart';
import 'firebase_message_service.dart';

class WebRTCService {
  static WebRTCService? _instance;
  static WebRTCService get instance => _instance ??= WebRTCService._();

  WebRTCService._();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final StreamController<MediaStream> _localStreamController =
      StreamController.broadcast();
  final StreamController<MediaStream> _remoteStreamController =
      StreamController.broadcast();
  final StreamController<CallStatus> _callStatusController =
      StreamController.broadcast();

  Stream<MediaStream> get localStream => _localStreamController.stream;
  Stream<MediaStream> get remoteStream => _remoteStreamController.stream;
  Stream<CallStatus> get callStatus => _callStatusController.stream;

  String? _currentCallId;
  CallType? _currentCallType;
  String? _receiverId;
  bool _isBasicInitialized = false; // Only basic web requirements checked
  Timer? _callTimeout;

  // STUN servers configuration
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun.stunprotocol.org:3478'},
      {'urls': 'stun:stun.voiparound.com'},
    ],
    'iceCandidatePoolSize': 10,
  };

  // Peer connection configuration
  final Map<String, dynamic> _pcConstraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  /// Basic initialization - only checks web requirements, no permissions
  Future<void> initialize() async {
    if (_isBasicInitialized) return;

    try {
      // Only check web requirements, no permission requests
      await _checkWebRequirements();
      _isBasicInitialized = true;
      print('WebRTC service basic initialization completed');
    } catch (e) {
      print('WebRTC basic initialization error: $e');
      throw Exception('Failed to initialize WebRTC: $e');
    }
  }

  Future<void> _checkWebRequirements() async {
    // Check if we're running on web and if HTTPS is required
    try {
      // Check if getUserMedia is available
      if (!WebRTC.platformIsWeb) {
        return; // Not web, skip web-specific checks
      }

      // For web, check if we're in a secure context (HTTPS or localhost)
      final isSecureContext =
          Uri.base.scheme == 'https' ||
          Uri.base.host == 'localhost' ||
          Uri.base.host == '127.0.0.1';

      if (!isSecureContext) {
        throw Exception(
          'WebRTC requires HTTPS in production. Please serve your app over HTTPS or use localhost for development.',
        );
      }

      print('Web requirements check passed');
    } catch (e) {
      print('Web requirements check failed: $e');
      rethrow;
    }
  }

  /// Full initialization with permission checks - called when making/receiving calls
  Future<void> _initializeWithPermissions() async {
    // First ensure basic initialization is done
    await initialize();

    // Now request permissions
    await _requestPermissions();
    print('WebRTC service fully initialized with permissions');
  }

  Future<void> _requestPermissions() async {
    try {
      // First, check if devices are available
      final devices = await navigator.mediaDevices.enumerateDevices();
      print('Available devices: ${devices.length}');

      bool hasAudio = false;
      bool hasVideo = false;

      for (var device in devices) {
        if (device.kind == 'audioinput') {
          hasAudio = true;
        } else if (device.kind == 'videoinput') {
          hasVideo = true;
        }
      }

      print('Has audio device: $hasAudio, Has video device: $hasVideo');

      if (!hasAudio) {
        throw Exception(
          'No microphone found. Please connect a microphone and try again.',
        );
      }

      // Try to get audio first (more likely to succeed)
      MediaStream? stream;
      try {
        print('Requesting audio permission...');
        stream = await navigator.mediaDevices.getUserMedia({
          'audio': {
            'echoCancellation': true,
            'noiseSuppression': true,
            'autoGainControl': true,
          },
          'video': false,
        });

        print('Audio permission granted');

        // If we have video devices and audio worked, try video
        if (hasVideo) {
          try {
            print('Requesting video permission...');
            final videoStream = await navigator.mediaDevices.getUserMedia({
              'audio': {
                'echoCancellation': true,
                'noiseSuppression': true,
                'autoGainControl': true,
              },
              'video': {
                'width': {'ideal': 640},
                'height': {'ideal': 480},
                'frameRate': {'ideal': 30},
                'facingMode': 'user',
              },
            });

            // Stop the audio-only stream
            for (var track in stream.getTracks()) {
              track.stop();
            }

            // Use the video stream instead
            stream = videoStream;
            print('Video permission also granted');
          } catch (videoError) {
            print('Video permission denied or failed: $videoError');
            // Keep the audio stream, video will be disabled
          }
        }

        // Stop the permission test stream
        for (var track in stream!.getTracks()) {
          track.stop();
        }
      } catch (e) {
        print('Permission request error: $e');

        // More specific error messages for common issues
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('notfound')) {
          throw Exception(
            'No microphone found. Please connect a microphone and refresh the page.',
          );
        } else if (errorString.contains('notallowed') ||
            errorString.contains('permission')) {
          throw Exception(
            'Microphone access denied. Please allow microphone access and refresh the page.',
          );
        } else if (errorString.contains('notreadable')) {
          throw Exception(
            'Microphone is being used by another application. Please close other applications and try again.',
          );
        } else if (errorString.contains('overconstrained')) {
          throw Exception(
            'Microphone constraints could not be satisfied. Please try with different settings.',
          );
        } else {
          throw Exception('Failed to access microphone: ${e.toString()}');
        }
      }
    } catch (e) {
      print('Permission request failed: $e');
      rethrow;
    }
  }

  Future<void> startCall({
    required String receiverId,
    required CallType callType,
  }) async {
    try {
      print('Starting call to $receiverId, type: $callType');

      // Initialize with permissions - this will now check for microphone
      await _initializeWithPermissions();

      _currentCallType = callType;
      _currentCallId = DateTime.now().millisecondsSinceEpoch.toString();
      _receiverId = receiverId;

      // Set initial status
      _callStatusController.add(CallStatus.outgoing);

      // Set call timeout (60 seconds instead of 30 for better UX)
      _callTimeout?.cancel();
      _callTimeout = Timer(const Duration(seconds: 60), () {
        print('Call timeout reached');
        _callStatusController.add(CallStatus.failed);
        endCall();
      });

      // Create peer connection first
      await _createPeerConnection();

      // Get user media with fallback
      await _getUserMediaWithFallback(callType);

      // Create offer
      print('Creating offer...');
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': callType == CallType.video && _hasVideoTrack(),
      });

      await _peerConnection!.setLocalDescription(offer);
      print('Local description set');

      // Send call signal through Firebase - but don't await it
        FirebaseMessageService.sendCallSignal(
              receiverId: receiverId,
              callId: _currentCallId!,
              type: 'offer',
              data: {
                'sdp': offer.sdp,
                'type': offer.type,
              }, // Replace offer.toMap() with explicit map
              callType: _currentCallType!,
            )
            .then((_) {
              print('Call offer sent successfully');
            })
            .catchError((e) {
              print('Error sending call signal: $e');
              _callStatusController.add(CallStatus.failed);
            });
      print('Call setup completed, returning control to CallManager');
    } catch (e) {
      print('Start call error: $e');
      _callStatusController.add(CallStatus.failed);
      await endCall();
      rethrow;
    }
  }

  Future<void> answerCall({
    required String callId,
    required Map<String, dynamic> offerData,
    required CallType callType,
    required String callerId,
  }) async {
    try {
      print('Answering call $callId from $callerId');

      // Initialize with permissions - this will now check for microphone
      await _initializeWithPermissions();

      _currentCallId = callId;
      _currentCallType = callType;
      _receiverId = callerId;

      // Set initial status
      _callStatusController.add(CallStatus.connecting);

      // Create peer connection
      await _createPeerConnection();

      // Get user media with fallback
      await _getUserMediaWithFallback(callType);

      // Set remote description (offer)
      print('Setting remote description...');
      final offer = RTCSessionDescription(offerData['sdp'], offerData['type']);
      await _peerConnection!.setRemoteDescription(offer);

      // Create answer
      print('Creating answer...');
      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': callType == CallType.video && _hasVideoTrack(),
      });

      await _peerConnection!.setLocalDescription(answer);
      print('Local description set for answer');

      // Send answer through Firebase
      await FirebaseMessageService.sendCallSignal(
        receiverId: callerId,
        callId: callId,
        type: 'answer',
        data: answer.toMap(),
        callType: _currentCallType!, // Use the potentially updated call type
      );

      print('Call answered successfully');
    } catch (e) {
      print('Answer call error: $e');
      _callStatusController.add(CallStatus.failed);
      await endCall();
      rethrow;
    }
  }

  Future<void> _getUserMediaWithFallback(CallType requestedCallType) async {
    try {
      print('Getting user media for call type: $requestedCallType');

      // First, check available devices
      final devices = await navigator.mediaDevices.enumerateDevices();
      bool hasAudio = devices.any((d) => d.kind == 'audioinput');
      bool hasVideo = devices.any((d) => d.kind == 'videoinput');

      if (!hasAudio) {
        throw Exception('No microphone found');
      }

      Map<String, dynamic> constraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      };

      // Try video if requested and available
      if (requestedCallType == CallType.video && hasVideo) {
        constraints['video'] = {
          'width': {'ideal': 640},
          'height': {'ideal': 480},
          'frameRate': {'ideal': 30, 'max': 30},
          'facingMode': 'user',
        };
      }

      try {
        _localStream = await navigator.mediaDevices.getUserMedia(constraints);
        print(
          'Media stream obtained: ${_localStream?.getTracks().length} tracks',
        );
      } catch (e) {
        print('Failed to get media with original constraints: $e');

        // Fallback: try audio only
        if (requestedCallType == CallType.video) {
          print('Falling back to audio-only call');
          _currentCallType = CallType.audio;

          try {
            _localStream = await navigator.mediaDevices.getUserMedia({
              'audio': {
                'echoCancellation': true,
                'noiseSuppression': true,
                'autoGainControl': true,
              },
              'video': false,
            });
            print('Audio-only fallback successful');
          } catch (audioError) {
            throw Exception('Failed to access microphone: $audioError');
          }
        } else {
          throw Exception('Failed to access microphone: $e');
        }
      }

      // Add tracks to peer connection
      if (_peerConnection != null && _localStream != null) {
        for (var track in _localStream!.getTracks()) {
          await _peerConnection!.addTrack(track, _localStream!);
          print('Added track: ${track.kind} (enabled: ${track.enabled})');
        }
      }

      if (_localStream != null) {
        _localStreamController.add(_localStream!);
      }
    } catch (e) {
      print('Get user media error: $e');
      rethrow;
    }
  }

  bool _hasVideoTrack() {
    if (_localStream == null) return false;
    return _localStream!.getVideoTracks().isNotEmpty;
  }

  Future<void> handleCallAnswer(Map<String, dynamic> answerData) async {
    try {
      print('Handling call answer...');
      if (_peerConnection == null) {
        print('No peer connection available');
        return;
      }

      _callTimeout?.cancel(); // Cancel timeout as call is being answered

      final answer = RTCSessionDescription(
        answerData['sdp'],
        answerData['type'],
      );
      await _peerConnection!.setRemoteDescription(answer);

      print('Remote description set for answer');
      _callStatusController.add(CallStatus.connecting);
    } catch (e) {
      print('Handle call answer error: $e');
      _callStatusController.add(CallStatus.failed);
    }
  }

  Future<void> handleIceCandidate(Map<String, dynamic> candidateData) async {
    try {
      if (_peerConnection == null) {
        print('No peer connection for ICE candidate');
        return;
      }

      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );

      await _peerConnection!.addCandidate(candidate);
      print('ICE candidate added: ${candidateData['candidate']}');
    } catch (e) {
      print('Handle ICE candidate error: $e');
    }
  }

  Future<void> declineCall(String callId) async {
    try {
      print('Declining call $callId');

      if (_receiverId != null) {
        await FirebaseMessageService.sendCallSignal(
          receiverId: _receiverId!,
          callId: callId,
          type: 'decline',
          data: {},
          callType: _currentCallType ?? CallType.audio,
        );
      }

      _callStatusController.add(CallStatus.declined);
      await endCall();
    } catch (e) {
      print('Decline call error: $e');
    }
  }

  Future<void> endCall() async {
    try {
      print('Ending call...');

      // Cancel any timers
      _callTimeout?.cancel();

      // Send end call signal if there's an active call
      if (_currentCallId != null && _receiverId != null) {
        try {
          await FirebaseMessageService.sendCallSignal(
            receiverId: _receiverId!,
            callId: _currentCallId!,
            type: 'end',
            data: {},
            callType: _currentCallType ?? CallType.audio,
          );
        } catch (e) {
          print('Error sending end call signal: $e');
        }
      }

      // Stop and dispose of local stream
      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          track.stop();
        }
        await _localStream!.dispose();
        _localStream = null;
      }

      // Stop and dispose of remote stream
      if (_remoteStream != null) {
        for (var track in _remoteStream!.getTracks()) {
          track.stop();
        }
        await _remoteStream!.dispose();
        _remoteStream = null;
      }

      // Close peer connection
      if (_peerConnection != null) {
        await _peerConnection!.close();
        _peerConnection = null;
      }

      _currentCallId = null;
      _currentCallType = null;
      _receiverId = null;

      _callStatusController.add(CallStatus.ended);
      print('Call ended successfully');
    } catch (e) {
      print('End call error: $e');
    }
  }

  Future<void> _createPeerConnection() async {
    try {
      print('Creating peer connection...');
      _peerConnection = await createPeerConnection(_iceServers, _pcConstraints);

      // Handle ICE candidates
      _peerConnection!.onIceCandidate = (candidate) async {
        if (candidate.candidate != null &&
            _currentCallId != null &&
            _receiverId != null) {
          print('Sending ICE candidate: ${candidate.candidate}');
          try {
            await FirebaseMessageService.sendCallSignal(
              receiverId: _receiverId!,
              callId: _currentCallId!,
              type: 'ice-candidate',
              data: {
                'candidate': candidate.candidate,
                'sdpMid': candidate.sdpMid,
                'sdpMLineIndex': candidate.sdpMLineIndex,
              },
              callType: _currentCallType ?? CallType.audio,
            );
          } catch (e) {
            print('Error sending ICE candidate: $e');
          }
        }
      };

      // Handle remote stream
      _peerConnection!.onAddStream = (stream) {
        print('Remote stream added');
        _remoteStream = stream;
        _remoteStreamController.add(stream);
        _callStatusController.add(CallStatus.connected);
        _callTimeout?.cancel(); // Cancel timeout on successful connection
      };

      // Handle connection state changes
      _peerConnection!.onConnectionState = (state) {
        print('Connection state changed: $state');
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            _callStatusController.add(CallStatus.connected);
            _callTimeout?.cancel();
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            _callStatusController.add(CallStatus.ended);
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            _callStatusController.add(CallStatus.failed);
            endCall();
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
            _callStatusController.add(CallStatus.ended);
            break;
          default:
            break;
        }
      };

      // Handle ICE connection state
      _peerConnection!.onIceConnectionState = (state) {
        print('ICE connection state: $state');
        switch (state) {
          case RTCIceConnectionState.RTCIceConnectionStateConnected:
          case RTCIceConnectionState.RTCIceConnectionStateCompleted:
            _callStatusController.add(CallStatus.connected);
            _callTimeout?.cancel();
            break;
          case RTCIceConnectionState.RTCIceConnectionStateFailed:
            _callStatusController.add(CallStatus.failed);
            endCall();
            break;
          case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
            _callStatusController.add(CallStatus.ended);
            break;
          default:
            break;
        }
      };

      print('Peer connection created successfully');
    } catch (e) {
      print('Create peer connection error: $e');
      throw Exception('Failed to create peer connection: $e');
    }
  }

  /// Optional: Check if microphone is available without requesting permissions
  /// This can be used to show UI hints before attempting calls
  Future<bool> isMicrophoneAvailable() async {
    try {
      await initialize(); // Only basic initialization
      final devices = await navigator.mediaDevices.enumerateDevices();
      return devices.any((d) => d.kind == 'audioinput');
    } catch (e) {
      print('Error checking microphone availability: $e');
      return false;
    }
  }

  /// Optional: Check if camera is available without requesting permissions
  /// This can be used to show UI hints before attempting video calls
  Future<bool> isCameraAvailable() async {
    try {
      await initialize(); // Only basic initialization
      final devices = await navigator.mediaDevices.enumerateDevices();
      return devices.any((d) => d.kind == 'videoinput');
    } catch (e) {
      print('Error checking camera availability: $e');
      return false;
    }
  }

  Future<void> toggleMicrophone() async {
    if (_localStream == null) return;

    final audioTracks = _localStream!.getAudioTracks();
    if (audioTracks.isNotEmpty) {
      final audioTrack = audioTracks.first;
      audioTrack.enabled = !audioTrack.enabled;
      print('Microphone ${audioTrack.enabled ? "enabled" : "disabled"}');
    }
  }

  Future<void> toggleCamera() async {
    if (_localStream == null) return;

    final videoTracks = _localStream!.getVideoTracks();
    if (videoTracks.isNotEmpty) {
      final videoTrack = videoTracks.first;
      videoTrack.enabled = !videoTrack.enabled;
      print('Camera ${videoTrack.enabled ? "enabled" : "disabled"}');
    }
  }

  Future<void> switchCamera() async {
    if (_localStream == null) return;

    final videoTracks = _localStream!.getVideoTracks();
    if (videoTracks.isNotEmpty) {
      try {
        await Helper.switchCamera(videoTracks.first);
        print('Camera switched');
      } catch (e) {
        print('Error switching camera: $e');
      }
    }
  }

  bool get isMicrophoneEnabled {
    if (_localStream == null) return false;
    final audioTracks = _localStream!.getAudioTracks();
    return audioTracks.isNotEmpty && audioTracks.first.enabled;
  }

  bool get isCameraEnabled {
    if (_localStream == null) return false;
    final videoTracks = _localStream!.getVideoTracks();
    return videoTracks.isNotEmpty && videoTracks.first.enabled;
  }

  bool get hasActiveCall => _currentCallId != null;

  String? get currentCallId => _currentCallId;

  CallType? get currentCallType => _currentCallType;

  void dispose() {
    print('Disposing WebRTC service');
    _callTimeout?.cancel();
    endCall();
    _localStreamController.close();
    _remoteStreamController.close();
    _callStatusController.close();
  }
}
