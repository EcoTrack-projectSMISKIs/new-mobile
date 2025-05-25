import 'package:flutter/material.dart';
import 'package:ecotrack_mobile/features/add_smartplug/select_smartplug.dart';
import 'package:ecotrack_mobile/features/appliance_list/appliances.dart';
import 'package:ecotrack_mobile/features/dashboard/dashboard.dart';
import 'package:ecotrack_mobile/features/news_and_updates/news_and_updates.dart';
import 'package:ecotrack_mobile/features/account_settings/profile_settings.dart';

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

  Widget _buildNavItem(
      BuildContext context,
      String iconPath,
      String activeIconPath,
      String label,
      int index,
  ) {
    final isActive = selectedIndex == index;
    final color = isActive ? Colors.green : Colors.grey;
    final imagePath = isActive ? activeIconPath : iconPath;

    return GestureDetector(
      onTap: () => _handleTap(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Image.asset(
                imagePath,
                width: 30,
                height: 30,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 16, // Fixed height for text to ensure consistent alignment
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: "Proxima Nova",
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        // Remove spaceEvenly and let Expanded handle the spacing
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _buildNavItem(
              context,
              'assets/icons/navbarlogos/dashboard.png',
              'assets/icons/navbarlogos/dashboard_g.png',
              'Home',
              0,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              'assets/icons/navbarlogos/plug.png',
              'assets/icons/navbarlogos/plug_g.png',
              'Devices',
              1,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              'assets/icons/navbarlogos/add.png',
              'assets/icons/navbarlogos/add_g.png',
              'Device',
              2,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              'assets/icons/navbarlogos/news.png',
              'assets/icons/navbarlogos/news_g.png',
              'News',
              3,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              'assets/icons/navbarlogos/profile.png',
              'assets/icons/navbarlogos/profile_g.png',
              'Profile',
              4,
            ),
          ),
        ],
      ),
    );
  }
}