import 'package:flutter/material.dart';
import '../utils/colors.dart';

class HomeNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HomeNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.surfaceDark,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: AppColors.primaryCyan,
      unselectedItemColor: AppColors.textSecondary,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chats"),
        BottomNavigationBarItem(
          icon: Icon(Icons.circle_outlined),
          label: "Circles",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: "Contacts"),
        BottomNavigationBarItem(icon: Icon(Icons.phone), label: "Calls"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
      ],
    );
  }
}
