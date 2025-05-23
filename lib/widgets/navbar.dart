import 'package:ecotrack_mobile/features/add_smartplug/scan_for_smartplug_controller.dart';
import 'package:ecotrack_mobile/features/appliance_list/appliances.dart';
import 'package:ecotrack_mobile/features/news_and_updates/news_and_updates.dart';
import 'package:ecotrack_mobile/features/account_settings/profile_settings.dart';
import 'package:ecotrack_mobile/features/dashboard/dashboard.dart';
import 'package:ecotrack_mobile/features/add_smartplug/select_smartplug.dart';
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNavBar({Key? key, required this.selectedIndex})
      : super(key: key);

  void _handleTap(BuildContext context, int index) {
    if (index == selectedIndex) return;

    Widget targetPage;
    switch (index) {
      case 0:
        targetPage = const EnergyDashboard();
        break;
      case 1:
        targetPage = const AppliancesPage();
        break;
      case 2:
        targetPage = SelectSmartPlugsScreen();
        break;
      case 3:
        targetPage = const NewsAndUpdates();
        break;
      case 4:
        targetPage = const ProfileSettingsPage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  Widget _buildNavItem(BuildContext context, String iconPath,
      String activeIconPath, String label, int index) {
    final isActive = selectedIndex == index;
    final color = isActive ? Colors.green : Colors.grey;
    final imagePath = isActive ? activeIconPath : iconPath;

    return GestureDetector(
      onTap: () => _handleTap(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imagePath,
            width: 32,
            height: 32,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Proxima Nova")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80, // Increased from default ~56–70 to ~90 for taller bar
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context,
            'assets/icons/navbarlogos/dashboard.png',
            'assets/icons/navbarlogos/dashboard_g.png',
            'Dashboard',
            0,
          ),
          _buildNavItem(
            context,
            'assets/icons/navbarlogos/plug.png',
            'assets/icons/navbarlogos/plug_g.png',
            'Appliances',
            1,
          ),
          _buildNavItem(
            context,
            'assets/icons/navbarlogos/add.png',
            'assets/icons/navbarlogos/add_g.png',
            'Add Device',
            2,
          ),
          _buildNavItem(
            context,
            'assets/icons/navbarlogos/news.png',
            'assets/icons/navbarlogos/news_g.png',
            'Updates',
            3,
          ),
          _buildNavItem(
            context,
            'assets/icons/navbarlogos/settings.png',
            'assets/icons/navbarlogos/settings.png',
            'Settings',
            4,
          ),
        ],
      ),
    );
  }
}
