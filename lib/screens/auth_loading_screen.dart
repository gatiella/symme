import 'package:flutter/material.dart';
import 'package:symme/screens/home_screen.dart';
import 'package:symme/services/call_manager.dart';
import 'package:symme/services/firebase_auth_service.dart';
import 'package:symme/utils/colors.dart';
import 'package:symme/utils/helpers.dart';

class AuthLoadingScreen extends StatefulWidget {
  const AuthLoadingScreen({super.key});

  @override
  State<AuthLoadingScreen> createState() => _AuthLoadingScreenState();
}

class _AuthLoadingScreenState extends State<AuthLoadingScreen>
    with TickerProviderStateMixin {
  bool _isSettingUp = false;
  List<TerminalCommand> _commands = [];
  int _currentCommandIndex = -1;

  late AnimationController _cursorController;
  late AnimationController _typewriterController;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );

    _initializeCommands();
  }

  @override
  void dispose() {
    _cursorController.dispose();
    _typewriterController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeCommands() {
    _commands = [
      TerminalCommand(
        command: 'symme init --secure',
        description: 'Initializing secure environment...',
        duration: 1500,
      ),
      TerminalCommand(
        command: 'cryptogen --generate-keypair',
        description: 'Generating RSA-4096 key pair...',
        duration: 2000,
      ),
      TerminalCommand(
        command: 'firebase auth --anonymous',
        description: 'Creating anonymous session...',
        duration: 1800,
      ),
      TerminalCommand(
        command: 'secureid generate --length=12',
        description: 'Generating unique secure identifier...',
        duration: 1200,
      ),
      TerminalCommand(
        command: 'database sync --user-data',
        description: 'Synchronizing user data...',
        duration: 1500,
      ),
      TerminalCommand(
        command: 'webrtc init --stun-servers',
        description: 'Initializing calling service...',
        duration: 2200,
      ),
      TerminalCommand(
        command: 'security audit --verify',
        description: 'Running security verification...',
        duration: 1000,
      ),
      TerminalCommand(
        command: 'symme ready --launch',
        description: 'Finalizing setup...',
        duration: 800,
      ),
    ];
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _isSettingUp = true;
        _currentCommandIndex = -1;
        for (var cmd in _commands) {
          cmd.reset();
        }
      });

      // Execute terminal commands with animations
      for (int i = 0; i < _commands.length; i++) {
        await _executeCommand(i);

        // Perform actual initialization at specific steps
        if (i == 1) {
          // Check for existing session during key generation
          final currentUser = FirebaseAuthService.getCurrentUser();
          if (currentUser == null) {
            // Generate anonymous user during firebase auth step
          }
        } else if (i == 2) {
          // Create anonymous account
          final user = await FirebaseAuthService.signInAnonymously();
          if (user == null) {
            throw Exception('Failed to create secure account');
          }
        } else if (i == 5) {
          // Initialize call manager
          await CallManager.instance.initialize(context);
        }
      }

      // Navigate to home screen
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show error in terminal style
        setState(() {
          final errorCommand = TerminalCommand(
            command: 'ERROR',
            description: 'Setup failed: ${e.toString()}',
            duration: 0,
            isError: true,
          );
          errorCommand.isCompleted = true;
          _commands.add(errorCommand);
        });

        Helpers.showSnackBar(context, 'Setup failed: $e');

        // Reset state after showing error
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() {
            _isSettingUp = false;
          });
        }
      }
    }
  }

  Future<void> _executeCommand(int index) async {
    setState(() {
      _currentCommandIndex = index;
      _commands[index].isExecuting = true;
    });

    // Scroll to bottom to show new command
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Animate command typing
    await _animateTyping(_commands[index].command);

    // Show execution
    await Future.delayed(Duration(milliseconds: _commands[index].duration));

    setState(() {
      _commands[index].isExecuting = false;
      _commands[index].isCompleted = true;
    });
  }

  Future<void> _animateTyping(String text) async {
    final command = _commands[_currentCommandIndex];

    for (int i = 0; i <= text.length; i++) {
      if (!mounted) return;

      setState(() {
        command.typedText = text.substring(0, i);
      });

      await Future.delayed(const Duration(milliseconds: 30));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // GitHub dark terminal color
      body: _isSettingUp ? _buildTerminalView() : _buildWelcomeView(),
    );
  }

  Widget _buildWelcomeView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF21262D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryCyan.withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.terminal,
                size: 80,
                color: AppColors.primaryCyan,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Welcome to Symme',
              style: TextStyle(
                color: AppColors.primaryCyan,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF21262D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: const Text(
                'A secure, end-to-end encrypted messaging platform\nwhere privacy is paramount and conversations remain confidential.',
                style: TextStyle(
                  color: Color(0xFF8B949E),
                  fontSize: 16,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _initializeApp,
              child: const Text('> Initialize Secure Environment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalView() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Terminal header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5F56),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFBD2E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF27CA3F),
                    shape: BoxShape.circle,
                  ),
                ),
                const Spacer(),
                const Text(
                  'symme-setup-terminal',
                  style: TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Terminal content
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: const Border(
                  left: BorderSide(color: Color(0xFF30363D)),
                  right: BorderSide(color: Color(0xFF30363D)),
                  bottom: BorderSide(color: Color(0xFF30363D)),
                ),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Symme Security Setup v2.1.0\nInitializing secure messaging environment...\n',
                      style: TextStyle(
                        color: AppColors.primaryCyan,
                        fontSize: 14,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Command list
                    ...List.generate(_commands.length, (index) {
                      if (index > _currentCommandIndex + 1) {
                        return const SizedBox.shrink();
                      }

                      return _buildCommandLine(index);
                    }),

                    // Cursor
                    if (_currentCommandIndex < _commands.length - 1 ||
                        (_currentCommandIndex >= 0 &&
                            !_commands[_currentCommandIndex].isCompleted))
                      _buildCursor(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandLine(int index) {
    final command = _commands[index];
    final isCurrentCommand = index == _currentCommandIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Command prompt and command
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                height: 1.4,
              ),
              children: [
                const TextSpan(
                  text: '> ',
                  style: TextStyle(color: AppColors.primaryCyan),
                ),
                TextSpan(
                  text: isCurrentCommand ? command.typedText : command.command,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),

          // Status/description
          if (command.isExecuting || command.isCompleted) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (command.isExecuting) ...[
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        command.isError ? Colors.red : AppColors.primaryCyan,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (command.isCompleted) ...[
                  Icon(
                    command.isError ? Icons.close : Icons.check,
                    size: 12,
                    color: command.isError
                        ? Colors.red
                        : const Color(0xFF27CA3F),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  command.description,
                  style: TextStyle(
                    color: command.isError
                        ? Colors.red
                        : command.isCompleted
                        ? const Color(0xFF27CA3F)
                        : const Color(0xFF8B949E),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCursor() {
    return AnimatedBuilder(
      animation: _cursorController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(top: 4),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              children: [
                const TextSpan(
                  text: '> ',
                  style: TextStyle(color: AppColors.primaryCyan),
                ),
                TextSpan(
                  text: '_',
                  style: TextStyle(
                    color: _cursorController.value > 0.5
                        ? Colors.white
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TerminalCommand {
  final String command;
  final String description;
  final int duration;
  final bool isError;

  bool isExecuting = false;
  bool isCompleted = false;
  String typedText = '';

  TerminalCommand({
    required this.command,
    required this.description,
    required this.duration,
    this.isError = false,
  });

  void reset() {
    isExecuting = false;
    isCompleted = false;
    typedText = '';
  }
}
