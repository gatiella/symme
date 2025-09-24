import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:symme/main.dart' as NavigationService;
import 'screens/auth_loading_screen.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'package:flutter/services.dart';

// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
  await NotificationService.firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Set background message handler for FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize notification service
  try {
    await NotificationService.initialize();
    print('Notification service initialized successfully');
  } catch (e) {
    print('Failed to initialize notification service: $e');
  }

  // Hide status bar + navigation bar (immersive fullscreen)
  //SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize screen protection
  //await _initializeScreenProtection();

  runApp(const SymmeApp());
}

// Method to initialize screen protection
// Future<void> _initializeScreenProtection() async {
//   const platform = MethodChannel('com.gatiella.symmeapp/screen_protection');
//   try {
//     await platform.invokeMethod('enableScreenProtection');
//     print('Screen protection enabled');
//   } on PlatformException catch (e) {
//     print("Failed to enable screen protection: '${e.message}'.");
//   }
// }

class SymmeApp extends StatefulWidget {
  const SymmeApp({super.key});

  @override
  State<SymmeApp> createState() => _SymmeAppState();
}

class _SymmeAppState extends State<SymmeApp> {
  @override
  void initState() {
    super.initState();
    
    // Handle initial message after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialMessage();
    });
  }

  Future<void> _handleInitialMessage() async {
    try {
      await NotificationService.handleInitialMessage();
    } catch (e) {
      print('Error handling initial message: $e');
    }
  }

@override
Widget build(BuildContext context) {
  return ChangeNotifierProvider(
    create: (_) => ThemeProvider(),
    child: Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: NavigationService.navigatorKey, // Add this line
          title: 'Symme',
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorSchemeSeed: Colors.deepPurple,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.deepPurple,
            useMaterial3: true,
          ),
          home: const AuthLoadingScreen(),
          debugShowCheckedModeBanner: false,
          routes: {
            '/chat': (context) => _buildChatRoute(context),
          },
        );
      },
    ),
  );
}

  // Helper method to build chat route with arguments
  Widget _buildChatRoute(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final senderId = arguments?['senderId'] as String?;
    
    if (senderId != null) {
      // Return your ChatScreen widget here
      // Example: return ChatScreen(senderId: senderId);
      return Scaffold(
        appBar: AppBar(title: Text('Chat with $senderId')),
        body: Center(child: Text('Chat screen for $senderId')),
      );
    }
    
    // Return fallback screen if no senderId provided
    return const Scaffold(
      body: Center(child: Text('Invalid chat route')),
    );
  }
}