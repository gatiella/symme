import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:symme/utils/colors.dart';
import 'package:symme/utils/helpers.dart';
import 'package:symme/widgets/circles_tab.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_message_service.dart';
import '../services/storage_service.dart';
import '../services/call_manager.dart';
import '../services/presence_service.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';
import 'settings_screen.dart';
import '../widgets/home_navbar.dart';
import '../widgets/chat_tab.dart';
import '../widgets/calls_tab.dart';
import '../widgets/connection_status.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int _currentIndex = 0;
  String? _userSecureId;
  bool _isLoading = true;
  bool _callManagerInitialized = false;
  String _connectionStatus = 'Connecting...';
  Timer? _heartbeatTimer;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Search functionality
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Get theme-aware colors
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAnimations();
    _initializeApp();
    _setupHeartbeat();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    CallManager.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _updateOnlineStatus(true);
        _setupHeartbeat();
        break;
      default:
        _updateOnlineStatus(false);
        _heartbeatTimer?.cancel();
        break;
    }
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _connectionStatus = 'Initializing...');

      final currentUser = FirebaseAuthService.getCurrentUser();
      if (currentUser == null) {
        setState(() => _connectionStatus = 'Signing in...');
        final user = await FirebaseAuthService.signInAnonymously();
        if (user == null) throw Exception('Failed to sign in');
      }

      final secureId = await StorageService.getUserSecureId();
      setState(() {
        _userSecureId = secureId;
        _connectionStatus = 'Connected';
        _isLoading = false;
      });

      // Start animations when loading is complete
      _fadeController.forward();
      _slideController.forward();

      await FirebaseMessageService.cleanupExpiredMessages();
      await _initializeCallManager();

      // Initialize presence service
      await PresenceService.initialize();
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed';
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to initialize: $e');
    }
  }

  Future<void> _initializeCallManager() async {
    try {
      if (_callManagerInitialized) return;

      setState(() => _connectionStatus = 'Setting up calling...');
      await CallManager.instance.initialize(context);

      setState(() {
        _callManagerInitialized = true;
        _connectionStatus = 'Connected';
      });
    } catch (e) {
      setState(() => _connectionStatus = 'Calling service failed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Calling service initialization failed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.2),
              onPressed: _initializeCallManager,
            ),
          ),
        );
      }
    }
  }

  void _setupHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => FirebaseAuthService.updateLastSeen(),
    );
  }

  void _updateOnlineStatus(bool isOnline) {
    if (isOnline) FirebaseAuthService.updateLastSeen();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
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

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingView() : _buildMainContent(),
      bottomNavigationBar: AnimatedOpacity(
        opacity: _isLoading ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 500),
        child: HomeNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            // Add subtle haptic feedback
            if (Theme.of(context).platform == TargetPlatform.iOS) {
              // HapticFeedback.selectionClick(); // Uncomment if you want haptics
            }
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: _isSearching ? 100.0 : 45.0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.appBarGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryCyan.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      automaticallyImplyLeading: false,
      title: _isSearching ? _buildSearchBar() : _buildNormalTitle(),
      actions: _isSearching ? _buildSearchActions() : _buildNormalActions(),
    );
  }

  Widget _buildNormalTitle() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isLoading
          ? Row(
              key: const ValueKey('loading'),
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textOnPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Symme',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            )
          : Row(
              key: const ValueKey('loaded'),
              children: [
                Text(
                  'Symme',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                if (_currentIndex == 0) _buildUnreadBadge(),
              ],
            ),
    );
  }

  Widget _buildUnreadBadge() {
    // Get actual unread count from your message service
    // For now, return empty container if no unread messages
    final unreadCount = 0; // Replace with actual unread count from your service

    if (unreadCount == 0) {
      return const SizedBox.shrink(); // Don't show badge if no unread messages
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        unreadCount > 99 ? '99+' : unreadCount.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: _getSearchHint(),
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
      ],
    );
  }

  String _getSearchHint() {
    switch (_currentIndex) {
      case 0:
        return 'Search conversations...';
      case 1:
        return 'Search circles...';
      case 2:
        return 'Search contacts...';
      case 3:
        return 'Search calls...';
      default:
        return 'Search...';
    }
  }

  List<Widget> _buildSearchActions() {
    return [
      IconButton(
        icon: Icon(Icons.close, color: Colors.white, size: 20),
        onPressed: _toggleSearch,
      ),
    ];
  }

  List<Widget> _buildNormalActions() {
    if (_isLoading) return [];

    return [
      // Search button
      AnimatedSlide(
        offset: _slideAnimation.value,
        duration: const Duration(milliseconds: 500),
        child: AnimatedOpacity(
          opacity: _fadeAnimation.value,
          duration: const Duration(milliseconds: 700),
          child: IconButton(
            icon: Icon(Icons.search, color: Colors.white, size: 20),
            onPressed: _toggleSearch,
            tooltip: 'Search',
          ),
        ),
      ),

      // Connection status
      AnimatedSlide(
        offset: _slideAnimation.value,
        duration: const Duration(milliseconds: 600),
        child: AnimatedOpacity(
          opacity: _fadeAnimation.value,
          duration: const Duration(milliseconds: 800),
          child: ConnectionStatus(
            connectionStatus: _connectionStatus,
            onRefresh: _initializeApp,
            onRegenerateId: _handleRegenerateId,
            onCleanup: _handleCleanupMessages,
          ),
        ),
      ),

      // Debug button
      AnimatedSlide(
        offset: _slideAnimation.value,
        duration: const Duration(milliseconds: 700),
        child: AnimatedOpacity(
          opacity: _fadeAnimation.value,
          duration: const Duration(milliseconds: 900),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.bug_report_rounded,
                color: AppColors.textOnPrimary,
                size: 20,
              ),
              onPressed: _debugUserSetup,
              tooltip: 'Debug User Setup',
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildLoadingView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  AppColors.backgroundPrimary,
                  AppColors.backgroundSecondary.withOpacity(0.5),
                ]
              : [Colors.grey.shade50, Colors.grey.shade100],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo or icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppGradients.appBarGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryCyan.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 40,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Pulsing progress indicator
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? AppColors.divider
                          : Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryCyan,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Status text with fade animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeIn,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Column(
                    children: [
                      Text(
                        _connectionStatus,
                        style: TextStyle(
                          color: _getTextPrimaryColor(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Setting up your secure connection...',
                        style: TextStyle(
                          color: _getTextSecondaryColor(context),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (!_callManagerInitialized) {
      return _buildServiceInitializingView();
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildCurrentTab(),
          ),
        );
      },
    );
  }

  Widget _buildServiceInitializingView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  AppColors.backgroundPrimary,
                  AppColors.backgroundSecondary.withOpacity(0.5),
                ]
              : [Colors.grey.shade50, Colors.grey.shade100],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryCyan.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.phone_rounded,
                size: 30,
                color: AppColors.primaryCyan,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              color: AppColors.primaryCyan,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Setting up calling service...',
              style: TextStyle(
                color: _getTextPrimaryColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: TextStyle(
                color: _getTextSecondaryColor(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    Widget tabContent;

    switch (_currentIndex) {
      case 0:
        tabContent = ChatTab(
          onStartChat: _onStartChat,
          searchQuery: _searchQuery,
        );
        break;
      case 1:
        tabContent = CirclesTab(
          userSecureId: _userSecureId ?? '',
          searchQuery: _searchQuery,
        );
        break;
      case 2:
        tabContent = ContactsScreen(
          onContactAdded: _onContactAdded,
          onStartChat: _onStartChat,
          searchQuery: _searchQuery,
        );
        break;
      case 3:
        tabContent = CallsTab(searchQuery: _searchQuery);
        break;
      case 4:
        tabContent = SettingsScreen(
          userPublicId: _userSecureId ?? '',
          onClearData: _handleClearData,
          onRegenerateId: _handleRegenerateId,
        );
        break;
      default:
        tabContent = Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _getSurfaceColor(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
                const SizedBox(height: 16),
                Text(
                  'Unknown tab',
                  style: TextStyle(
                    color: _getTextPrimaryColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
    }

    // Add floating action button for certain tabs
    return Stack(
      children: [
        tabContent,
        if (_shouldShowFAB()) _buildFloatingActionButton(),
      ],
    );
  }

  bool _shouldShowFAB() {
    // Hide FAB when searching or when not on chat/contacts tabs
    if (_isSearching) return false;
    return _currentIndex == 0 || _currentIndex == 2; // Chat and Contacts tabs
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: AnimatedOpacity(
        opacity: _fadeAnimation.value,
        duration: const Duration(milliseconds: 800),
        child: FloatingActionButton(
          onPressed: () {
            if (_currentIndex == 0) {
              _showNewChatDialog();
            } else if (_currentIndex == 2) {
              //  _showAddContactDialog();
            }
          },
          backgroundColor: AppColors.primaryCyan,
          child: Icon(
            _currentIndex == 0 ? Icons.chat_bubble : Icons.person_add,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showNewChatDialog() async {
    // Load contacts from storage
    final contacts = await StorageService.getContacts();

    if (contacts.isEmpty) {
      // Show message to add contacts first
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _getSurfaceColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.people_outline,
                color: AppColors.primaryCyan,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'No Contacts',
                style: TextStyle(
                  color: _getTextPrimaryColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'You need to add contacts first. Go to the Contacts tab to add people by their Secure ID.',
            style: TextStyle(color: _getTextSecondaryColor(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(color: _getTextSecondaryColor(context)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2); // Switch to contacts tab
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryCyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Add Contacts',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Show contact selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.chat_bubble, color: AppColors.primaryCyan, size: 24),
            const SizedBox(width: 12),
            Text(
              'Start New Chat',
              style: TextStyle(
                color: _getTextPrimaryColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select a contact to start chatting:',
                style: TextStyle(color: _getTextSecondaryColor(context)),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: _getSurfaceColor(context),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Helpers.getColorFromId(
                            contact.publicId,
                          ),
                          child: Text(
                            Helpers.getInitials(contact.name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          contact.name,
                          style: TextStyle(
                            color: _getTextPrimaryColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          contact.publicId,
                          style: TextStyle(
                            color: _getTextSecondaryColor(context),
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.primaryCyan,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _onStartChat(contact.publicId);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: _getTextSecondaryColor(context)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2); // Switch to contacts tab
            },
            child: Text(
              'Add More Contacts',
              style: TextStyle(color: AppColors.primaryCyan),
            ),
          ),
        ],
      ),
    );
  }

  // void _showAddContactDialog() {
  //   final TextEditingController nameController = TextEditingController();
  //   final TextEditingController secureIdController = TextEditingController();

  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       backgroundColor: _getSurfaceColor(context),
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       title: Row(
  //         children: [
  //           Icon(Icons.person_add, color: AppColors.primaryCyan, size: 24),
  //           const SizedBox(width: 12),
  //           Text(
  //             'Add Contact',
  //             style: TextStyle(
  //               color: _getTextPrimaryColor(context),
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //         ],
  //       ),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           TextField(
  //             controller: nameController,
  //             decoration: InputDecoration(
  //               hintText: 'Contact Name',
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(8),
  //                 borderSide: BorderSide(
  //                   color: _getTextSecondaryColor(context).withOpacity(0.3),
  //                 ),
  //               ),
  //               focusedBorder: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(8),
  //                 borderSide: BorderSide(color: AppColors.primaryCyan),
  //               ),
  //             ),
  //             style: TextStyle(color: _getTextPrimaryColor(context)),
  //           ),
  //           const SizedBox(height: 16),
  //           TextField(
  //             controller: secureIdController,
  //             decoration: InputDecoration(
  //               hintText: 'Secure ID',
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(8),
  //                 borderSide: BorderSide(
  //                   color: _getTextSecondaryColor(context).withOpacity(0.3),
  //                 ),
  //               ),
  //               focusedBorder: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(8),
  //                 borderSide: BorderSide(color: AppColors.primaryCyan),
  //               ),
  //             ),
  //             style: TextStyle(color: _getTextPrimaryColor(context)),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text(
  //             'Cancel',
  //             style: TextStyle(color: _getTextSecondaryColor(context)),
  //           ),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             if (nameController.text.trim().isNotEmpty &&
  //                 secureIdController.text.trim().isNotEmpty) {
  //               Navigator.pop(context);
  //               // Add contact logic here
  //               Helpers.showSnackBar(context, 'Contact added successfully!');
  //               _onContactAdded();
  //             }
  //           },
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: AppColors.primaryCyan,
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //           ),
  //           child: const Text('Add', style: TextStyle(color: Colors.white)),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _onContactAdded() => setState(() {});

  void _onStartChat(String otherUserSecureId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChatScreen(otherUserSecureId: otherUserSecureId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          final tween = Tween(begin: begin, end: end);
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: curve,
          );

          return SlideTransition(
            position: tween.animate(curvedAnimation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _debugUserSetup() async {
    print('=== DEBUG USER SETUP ===');
    final currentUser = FirebaseAuthService.getCurrentUser();
    final storedUserId = await StorageService.getUserId();
    final storedSecureId = await StorageService.getUserSecureId();

    print('Current Firebase User: ${currentUser?.uid}');
    print('Stored User ID: $storedUserId');
    print('Stored Secure ID: $storedSecureId');

    if (currentUser != null) {
      try {
        final userSnapshot = await FirebaseDatabase.instance
            .ref('users/${currentUser.uid}')
            .once();
        if (userSnapshot.snapshot.exists) {
          print(
            'Firebase Realtime DB user data: ${userSnapshot.snapshot.value}',
          );
        } else {
          print('User NOT found in Firebase Realtime Database');
        }
      } catch (e) {
        print('Error checking Realtime DB: $e');
      }
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _getSurfaceColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.bug_report_rounded,
                color: AppColors.primaryCyan,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Debug Info',
                style: TextStyle(
                  color: _getTextPrimaryColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDebugInfoItem('User ID', currentUser?.uid ?? "NULL"),
                _buildDebugInfoItem('Stored User ID', storedUserId ?? "NULL"),
                _buildDebugInfoItem('Secure ID', storedSecureId ?? "NULL"),
                _buildDebugInfoItem(
                  'CallManager',
                  _callManagerInitialized ? "Initialized" : "Not initialized",
                ),
                _buildDebugInfoItem(
                  'Search Query',
                  _searchQuery.isEmpty ? "Empty" : _searchQuery,
                ),
                _buildDebugInfoItem('Current Tab', _getCurrentTabName()),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryCyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    print('=== END DEBUG ===');
  }

  String _getCurrentTabName() {
    switch (_currentIndex) {
      case 0:
        return 'Chat';
      case 1:
        return 'Circles';
      case 2:
        return 'Contacts';
      case 3:
        return 'Calls';
      case 4:
        return 'Settings';
      default:
        return 'Unknown';
    }
  }

  Widget _buildDebugInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: _getTextSecondaryColor(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: _getTextPrimaryColor(context),
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegenerateId() async {
    // Show confirmation dialog with improved styling
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.refresh_rounded,
              color: AppColors.warningOrange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Regenerate ID',
              style: TextStyle(
                color: _getTextPrimaryColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'This will generate a new secure ID. Your existing conversations will be lost. Continue?',
          style: TextStyle(
            color: _getTextSecondaryColor(context),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: _getTextSecondaryColor(context),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warningOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Add your regenerate ID logic here
      Helpers.showSnackBar(
        context,
        'ID regeneration functionality coming soon!',
      );
    }
  }

  Future<void> _handleCleanupMessages() async {
    try {
      await FirebaseMessageService.cleanupExpiredMessages();
      Helpers.showSnackBar(context, 'Expired messages cleaned up');
    } catch (_) {
      _showErrorSnackBar('Failed to cleanup messages');
    }
  }

  Future<void> _handleClearData() async {
    try {
      await FirebaseAuthService.signOut();
      await StorageService.clearAllData();
      setState(() {
        _isLoading = true;
        _userSecureId = null;
        _callManagerInitialized = false;
        _isSearching = false;
        _searchController.clear();
        _searchQuery = '';
      });
      // Reset animations
      _fadeController.reset();
      _slideController.reset();
      await _initializeApp();
    } catch (e) {
      _showErrorSnackBar('Failed to clear data: $e');
    }
  }
}
