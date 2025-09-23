import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/auth_loading_screen.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
//   } on PlatformException catch (e) {
//     print("Failed to enable screen protection: '${e.message}'.");
//   }
// }

class SymmeApp extends StatelessWidget {
  const SymmeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
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
          );
        },
      ),
    );
  }
}
