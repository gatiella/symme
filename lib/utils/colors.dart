import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryCyan = Color(0xFF00D4FF);
  static const Color primaryCyanDark = Color(0xFF0099CC);
  static const Color primaryAccent = Color(0xFF4ECDC4);
  static const Color primaryRed = Color(0xFFFF6B6B);

  // Background Colors
  static const Color backgroundPrimary = Color(0xFF0A0A0A);
  static const Color backgroundSecondary = Color(0xFF1A1A2E);
  static const Color backgroundTertiary = Color(0xFF16213E);

  // Surface Colors
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color surfaceCard = Color(0xFF16213E);
  static const Color surfaceOverlay = Color(0xFF000000); // with opacity

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF999999);
  static const Color textTertiary = Color(0xFF666666);
  static const Color textOnPrimary = Color(0xFF000000);

  // Status Colors
  static const Color onlineGreen = Color(0xFF4ECDC4);
  static const Color errorRed = Color(0xFFFF6B6B);
  static const Color divider = Color(0xFFDDDDDD);
  static const Color warningOrange = Color(0xFFFFB347);
  static const Color successGreen = Color(0xFF4ECDC4);

  // Border Colors
  static const Color borderPrimary = Color(0xFF00D4FF);
  static const Color borderSecondary = Color(0x4D00D4FF); // 30% opacity
  static const Color borderTertiary = Color(0x1A00D4FF); // 10% opacity

  // Avatar Gradient Colors
  static const Color avatarGrad1Start = Color(0xFF00D4FF);
  static const Color avatarGrad1End = Color(0xFF4ECDC4);

  static const Color avatarGrad2Start = Color(0xFFFF6B6B);
  static const Color avatarGrad2End = Color(0xFFFFB347);

  static const Color avatarGrad3Start = Color(0xFF4ECDC4);
  static const Color avatarGrad3End = Color(0xFF45B7D1);

  static const Color avatarGrad4Start = Color(0xFF96CEB4);
  static const Color avatarGrad4End = Color(0xFFFFEAA7);

  static const Color avatarGrad5Start = Color(0xFFFD79A8);
  static const Color avatarGrad5End = Color(0xFFFDCB6E);

  static const Color avatarGrad6Start = Color(0xFF6C5CE7);
  static const Color avatarGrad6End = Color(0xFFA29BFE);

  static const Color avatarGrad7Start = Color(0xFF00B894);
  static const Color avatarGrad7End = Color(0xFF55EFC4);

  static const Color avatarGrad8Start = Color(0xFFE17055);
  static const Color avatarGrad8End = Color(0xFFFAB1A0);

  static const Color avatarGrad9Start = Color(0xFF0984E3);
  static const Color avatarGrad9End = Color(0xFF74B9FF);

  // Input Colors
  static const Color inputBackground = Color(0x1A00D4FF); // 10% opacity
  static const Color inputBorder = Color(0x4D00D4FF); // 30% opacity
  static const Color inputFocusBorder = Color(0xFF00D4FF);

  // Button Colors
  static const Color buttonPrimary = Color(0xFF00D4FF);
  static const Color buttonSecondary = Color(0xFF4ECDC4);
  static const Color buttonDisabled = Color(0xFF333333);

  // Message Bubble Colors
  static const Color messageSent = Color(0xFF00D4FF);
  static const Color messageSentDark = Color(0xFF0099CC);
  static const Color messageReceived = Color(0x3300D4FF); // 20% opacity
  static const Color messageReceivedBorder = Color(0x4D00D4FF); // 30% opacity

  // Badge Colors
  static const Color badgeBackground = Color(0xFFFF6B6B);
  static const Color badgeText = Color(0xFFFFFFFF);

  // Toggle Colors
  static const Color toggleInactive = Color(0xFF333333);
  static const Color toggleActive = Color(0xFF00D4FF);
  static const Color toggleThumb = Color(0xFFFFFFFF);

  // Shadow Colors (used with opacity)
  static const Color shadowPrimary = Color(
    0xFF00D4FF,
  ); // use with opacity 0.3-0.4
  static const Color shadowDark = Color(0xFF000000); // use with opacity 0.2-0.5

  // Overlay Colors (used with opacity)
  static const Color overlayLight = Color(0xFFFFFFFF); // use with opacity 0.1
  static const Color overlayDark = Color(
    0xFF000000,
  );

  static Color? get secondary => null; // use with opacity 0.3-0.5
}

// Gradient Definitions
class AppGradients {
  // Background Gradients
  static final LinearGradient backgroundMain = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
    colors: [
      AppColors.backgroundPrimary,
      AppColors.backgroundSecondary,
      AppColors.backgroundTertiary,
    ],
  );

  // AppBar Gradient
  static final LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryCyan, AppColors.primaryCyanDark],
  );

  static const LinearGradient surfaceCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surfaceDark, AppColors.surfaceCard],
  );

  // Text Gradients
  static const LinearGradient textTitle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryCyan,
      AppColors.primaryRed,
      AppColors.primaryAccent,
    ],
  );

  // Button Gradients
  static const LinearGradient buttonPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryCyan, AppColors.primaryCyanDark],
  );

  static const LinearGradient messageSent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.messageSent, AppColors.primaryCyanDark],
  );

  // Avatar Gradients
  static const LinearGradient avatar1 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.avatarGrad1Start, AppColors.avatarGrad1End],
  );

  static const LinearGradient avatar2 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.avatarGrad2Start, AppColors.avatarGrad2End],
  );

  static const LinearGradient avatar3 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.avatarGrad3Start, AppColors.avatarGrad3End],
  );

  static const LinearGradient avatar4 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.avatarGrad4Start, AppColors.avatarGrad4End],
  );

  static const LinearGradient avatar5 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.avatarGrad5Start, AppColors.avatarGrad5End],
  );

  static const LinearGradient avatar6 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.avatarGrad6Start, AppColors.avatarGrad6End],
  );

  static const LinearGradient avatar7 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.avatarGrad7Start, AppColors.avatarGrad7End],
  );

  static const LinearGradient avatar8 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.avatarGrad8Start, AppColors.avatarGrad8End],
  );

  static const LinearGradient avatar9 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.avatarGrad9Start, AppColors.avatarGrad9End],
  );
}

// Shadow Definitions
class AppShadows {
  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: AppColors.shadowPrimary.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: AppColors.shadowPrimary.withOpacity(0.3),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: AppColors.shadowPrimary.withOpacity(0.4),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> inputFocusShadow = [
    BoxShadow(
      color: AppColors.shadowPrimary.withOpacity(0.3),
      blurRadius: 10,
      offset: const Offset(0, 0),
    ),
  ];
}

// Usage Examples:
/*
// Using solid colors:
Container(
  color: AppColors.primaryCyan,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)

// Using gradients:
Container(
  decoration: BoxDecoration(
    gradient: AppGradients.backgroundMain,
    borderRadius: BorderRadius.circular(12),
  ),
)

// Using shadows:
Container(
  decoration: BoxDecoration(
    color: AppColors.surfaceCard,
    borderRadius: BorderRadius.circular(12),
    boxShadow: AppShadows.cardShadow,
  ),
)

// Using with opacity:
Container(
  color: AppColors.overlayDark.withOpacity(0.3),
)
*/
