import 'package:ecotrack_mobile/features/dashboard/dashboard.dart';
import 'package:ecotrack_mobile/features/landing_page/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import 'package:ecotrack_mobile/features/add_smartplug/name_plug.dart';
// import 'package:ecotrack_mobile/widgets/error_modal.dart';
// import 'package:ecotrack_mobile/widgets/success_modal.dart';
// import 'package:ecotrack_mobile/features/appliance_list/appliances.dart';
// import 'package:ecotrack_mobile/features/news_and_updates/news_and_updates.dart';
// import 'package:ecotrack_mobile/features/add_smartplug/select_smartplug.dart';
// import 'package:wifi_scan/wifi_scan.dart';
// import 'package:ecotrack_mobile/features/add_smartplug/static.dart';
// import 'package:ecotrack_mobile/widgets/navbar.dart';
// import 'package:ecotrack_mobile/features/add_smartplug/select_home_wifi.dart';
// import 'package:ecotrack_mobile/features/appliance_list/appliance_details.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // important
  await dotenv.load(fileName: ".env"); // important
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const SplashScreen(),  // SplashScreen first
    );
  }
}



class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    await Future.delayed(const Duration(seconds: 2)); // Optional splash delay

    if (token != null && token.isNotEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EnergyDashboard()),
      );
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LandingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF109717),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/lottie/logo.png',
              width: 160, //120
            ),
            const SizedBox(height: 32),
            const Text(
              'ecotrack',
              style: TextStyle(
                fontSize: 40, //24
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            )
          ],
        ),
      ),
    );
  }
}




//TESTING THE FRONTEND OF NAME PLUG PAGE HERE

// void main() {
//   runApp(
//     MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: NamePlugPage(plugId: "682af74da563e5b1fb6dca1d", plugIp: "172.20.10.3"),

//     ),
//   );
// }




// void main() {
//   runApp(
//     MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: ApplianceDetails(plugId: "682f0fbe2fbdf8bda0d3cfb9"),
//     ),
//   );
// }




// TESTING THE FRONTEND OF MODALS


// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Modal Demo',
//       home: const ModalDemoPage(),
//     );
//   }
// }

// class ModalDemoPage extends StatelessWidget {
//   const ModalDemoPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Custom Modal Demo')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                 context.showCustomSuccessModal(
//                   message: 'This is a success message!',
//                   onButtonPressed: () {
//                     Navigator.pop(context); // Close the modal
//                   },
//                 );
//               },
//               child: const Text('Show Success Modal'),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 context.showCustomErrorModal(
//                   message: 'This is an error message!',
//                   onButtonPressed: () {
//                     Navigator.pop(context); // Close the modal
//                   },
//                 );
//               },
//               child: const Text('Show Error Modal'),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.only(bottom: 12.0),
//         child: CustomBottomNavBar(selectedIndex: 2),
//       ),
//     );
//   }
// }

