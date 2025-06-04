import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:ecotrack_mobile/widgets/navbar.dart';

/// ---------------------------------------------------------------------------
///  MODEL
/// ---------------------------------------------------------------------------
class ApplianceData {
  final String name;
  final int watts;
  final Color color;
  final IconData icon;

  ApplianceData(this.name, this.watts, this.color, this.icon);

  factory ApplianceData.fromJson(Map<String, dynamic> plug, int index,
      List<Color> palette, List<IconData> icons) {
    return ApplianceData(
      plug['applianceName'] ?? plug['name'] ?? 'Unnamed',
      (plug['energy']?['Power'] ?? 0).round(),
      palette[index % palette.length],
      icons[index % icons.length],
    );
  }
}

/// ---------------------------------------------------------------------------
///  MAIN DASHBOARD WIDGET
/// ---------------------------------------------------------------------------
class EnergyDashboard extends StatefulWidget {
  const EnergyDashboard({Key? key}) : super(key: key);

  @override
  State<EnergyDashboard> createState() => _EnergyDashboardState();
}

class _EnergyDashboardState extends State<EnergyDashboard>
    with TickerProviderStateMixin {
  List<ApplianceData> appliancesData = [];
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Color> _palette = [
    const Color(0xFF119718),
    const Color(0xFF8EAC50),
    const Color(0xFFD3D04F),
    const Color(0xFF074799),
    const Color(0xFF009990),
    const Color(0xFF2D710E),
    const Color(0xFF6B7280),
  ];

// REPLACE WITH ICONS ON ASSETS
  final List<IconData> _icons = [
    Icons.power, // used
    Icons.lightbulb_outline,
    Icons.tv,
    Icons.kitchen,
    Icons.ac_unit,
    Icons.computer, // used
    Icons.smartphone, // used
    Icons.speaker,
    Icons.router,
    Icons.electrical_services,
  ];

  Timer? _refreshTimer;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    loadUserIdAndFetchPlugs();

    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        loadUserIdAndFetchPlugs();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadUserIdAndFetchPlugs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId != null && userId.isNotEmpty) {
      fetchUserPlugs(userId);
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'User ID not found.';
      });
    }
  }

  Future<void> fetchUserPlugs(String userId) async {
    final url =
        Uri.parse('${dotenv.env['BASE_URL']}/api/auth/mobile/$userId/plugs/');

    try {
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(res.body);
        final List plugs = body['plugs'] ?? [];

        List<ApplianceData> allData = plugs
            .asMap()
            .entries
            .map((entry) => ApplianceData.fromJson(
                entry.value, entry.key, _palette, _icons))
            .toList();

        allData.sort((a, b) => b.watts.compareTo(a.watts));
        List<ApplianceData> top4 = allData.take(4).toList();

        if (allData.length > 4) {
          int othersWatts =
              allData.skip(4).fold(0, (sum, item) => sum + item.watts);
          top4.add(ApplianceData("Others", othersWatts, const Color(0xFF6B7280),
              Icons.more_horiz));
        }

        setState(() {
          appliancesData = top4;
          isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          errorMessage = 'Server error';
          print("Server error: ${res.statusCode}");
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: There is no internet connection.';
        print("Network error: $e");
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalWatts =
        appliancesData.fold<int>(0, (sum, item) => sum + item.watts);
    final double averageWatts =
        appliancesData.isNotEmpty ? totalWatts / appliancesData.length : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFE7F5E8),
      //   const Color(0xFFF3F4F6), // Light gray background
      //   const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                // gradient: LinearGradient(
                //   begin: Alignment.topLeft,
                //   end: Alignment.bottomRight,
                //   colors: [
                //     Color(0xFF109717),
                //     Color.fromARGB(255, 29, 155, 36),
                //   ],
                // ),
                color: Color(0xFF109717),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Energy Dashboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        // decoration: BoxDecoration(
                        //   color: Colors.white.withOpacity(0.2),
                        //   borderRadius: BorderRadius.circular(16),
                        // ),
                        child: const Icon(
                          Icons.bolt,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Power',
                          value: '${totalWatts}W',
                          icon: Icons.power,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Devices',
                          value: '${appliancesData.length}',
                          icon: Icons.devices,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Chart Section with Legend
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: //const Color(0xFFE7F5E8), // to change bg color
                            const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Power Consumption',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 300,
                            child: _buildChartContent(),
                          ),
                          // Legend
                          if (!isLoading && errorMessage == null && appliancesData.isNotEmpty)
                            _buildLegend(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // // Appliances Grid
                    // if (!isLoading && errorMessage == null && appliancesData.isNotEmpty)
                    //   FadeTransition(
                    //     opacity: _fadeAnimation,
                    //     child: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: [
                    //         const Text(
                    //           'Device Overview',
                    //           style: TextStyle(
                    //             fontSize: 20,
                    //             fontWeight: FontWeight.bold,
                    //             color: Color(0xFF1F2937),
                    //           ),
                    //         ),
                    //         const SizedBox(height: 16),
                    //         GridView.builder(
                    //           shrinkWrap: true,
                    //           physics: const NeverScrollableScrollPhysics(),
                    //           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    //             crossAxisCount: 2,
                    //             crossAxisSpacing: 16,
                    //             mainAxisSpacing: 16,
                    //             childAspectRatio: 1.2,
                    //           ),
                    //           itemCount: appliancesData.length,
                    //           itemBuilder: (context, index) {
                    //             final appliance = appliancesData[index];
                    //             final percentage = totalWatts > 0
                    //                 ? (appliance.watts / totalWatts * 100)
                    //                 : 0.0;

                    //             return _buildApplianceCard(appliance, percentage);
                    //           },
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(
        bottom: false,
        child: CustomBottomNavBar(selectedIndex: 0),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: const Color(0xFF0D8013), size: 24),
              //const Icon(Icons.trending_up, color: Color(0xFF10B981), size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF119718)),
            ),
            SizedBox(height: 16),
            Text('Loading energy data...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (appliancesData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.power_off,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text('No devices found'),
          ],
        ),
      );
    }

    return ModernBarChart(appliancesData: appliancesData);
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Devices',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: appliancesData.map((appliance) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: appliance.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${appliance.name} (${appliance.watts}W)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildApplianceCard(ApplianceData appliance, double percentage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: appliance.color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: appliance.color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: appliance.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  appliance.icon,
                  color: appliance.color,
                  size: 20,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: appliance.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            appliance.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${appliance.watts}W',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: appliance.color,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(appliance.color),
            minHeight: 4,
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
///  MODERN CHART
/// ---------------------------------------------------------------------------
class ModernBarChart extends StatelessWidget {
  const ModernBarChart({Key? key, required this.appliancesData})
      : super(key: key);

  final List<ApplianceData> appliancesData;

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,
      tooltipBehavior: TooltipBehavior(
        enable: true,
        canShowMarker: false,
        borderWidth: 0,
        color: const Color(0xFF1F2937),
        textStyle: const TextStyle(color: Colors.white),
      ),
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(
          color: Colors.transparent, // Hide X-axis labels
          fontSize: 0,
        ),
        isVisible: false, // Hide entire X-axis
      ),
      primaryYAxis: NumericAxis(
        majorGridLines: MajorGridLines(
          width: 1,
          color: Colors.grey[200]!,
        ),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
        ),
      ),
      series: <CartesianSeries<ApplianceData, String>>[
        ColumnSeries<ApplianceData, String>(
          dataSource: appliancesData,
          xValueMapper: (data, _) => data.name,
          yValueMapper: (data, _) => data.watts,
          pointColorMapper: (data, _) => data.color,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.top,
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          spacing: 0.3,
        ),
      ],
    );
  }
}

// import 'dart:async';
// import 'dart:convert';
// import 'dart:math' as math;

// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';
// import 'package:ecotrack_mobile/widgets/navbar.dart';

// /// ---------------------------------------------------------------------------
// ///  MODEL
// /// ---------------------------------------------------------------------------
// class ApplianceData {
//   final String name;
//   final int watts;
//   final Color color;
//   final IconData icon;

//   ApplianceData(this.name, this.watts, this.color, this.icon);

//   factory ApplianceData.fromJson(Map<String, dynamic> plug, int index,
//       List<Color> palette, List<IconData> icons) {
//     return ApplianceData(
//       plug['applianceName'] ?? plug['name'] ?? 'Unnamed',
//       (plug['energy']?['Power'] ?? 0).round(),
//       palette[index % palette.length],
//       icons[index % icons.length],
//     );
//   }
// }

// /// ---------------------------------------------------------------------------
// ///  MAIN DASHBOARD WIDGET
// /// ---------------------------------------------------------------------------
// class EnergyDashboard extends StatefulWidget {
//   const EnergyDashboard({Key? key}) : super(key: key);

//   @override
//   State<EnergyDashboard> createState() => _EnergyDashboardState();
// }

// class _EnergyDashboardState extends State<EnergyDashboard>
//     with TickerProviderStateMixin {
//   List<ApplianceData> appliancesData = [];
//   bool isLoading = true;
//   String? errorMessage;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   final List<Color> _palette = [
//     const Color(0xFF119718),
//     const Color(0xFF8EAC50),
//     const Color(0xFFD3D04F),
//     const Color(0xFF074799),
//     const Color(0xFF009990),
//     const Color(0xFF2D710E),
//     const Color(0xFF6B7280),
//   ];

// // REPLACE WITH ICONS ON ASSETS
//   final List<IconData> _icons = [
//     Icons.power, // used
//     Icons.lightbulb_outline,
//     Icons.tv,
//     Icons.kitchen,
//     Icons.ac_unit,
//     Icons.computer, // used
//     Icons.smartphone, // used
//     Icons.speaker,
//     Icons.router,
//     Icons.electrical_services,
//   ];

//   Timer? _refreshTimer;
  
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));
    
//     // Load dummy data instead of API call
//     loadDummyData();

//     _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
//       if (mounted) {
//         loadDummyData();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _refreshTimer?.cancel();
//     _animationController.dispose();
//     super.dispose();
//   }

//   // Generate dummy data with some randomization
//   Future<void> loadDummyData() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });

//     // Simulate network delay
//     await Future.delayed(Duration(milliseconds: 800));

//     final random = math.Random();
    
//     // Base dummy appliances with realistic power consumption
//     final List<Map<String, dynamic>> dummyAppliances = [
//       {'name': 'Air Conditioner', 'baseWatts': 1500, 'icon': Icons.ac_unit},
//       {'name': 'Refrigerator', 'baseWatts': 150, 'icon': Icons.kitchen},
//       {'name': 'TV', 'baseWatts': 120, 'icon': Icons.tv},
//       {'name': 'Computer', 'baseWatts': 300, 'icon': Icons.computer},
//       {'name': 'Washing Machine', 'baseWatts': 500, 'icon': Icons.local_laundry_service},
//       {'name': 'LED Lights', 'baseWatts': 45, 'icon': Icons.lightbulb_outline},
//       {'name': 'Router', 'baseWatts': 12, 'icon': Icons.router},
//       {'name': 'Phone Charger', 'baseWatts': 5, 'icon': Icons.smartphone},
//       {'name': 'Microwave', 'baseWatts': 800, 'icon': Icons.microwave},
//       {'name': 'Fan', 'baseWatts': 75, 'icon': Icons.air},
//     ];

//     // Randomly select 5-8 appliances and vary their power consumption
//     final selectedAppliances = dummyAppliances..shuffle();
//     final numAppliances = 5 + random.nextInt(4); // 5 to 8 appliances
    
//     List<ApplianceData> allData = [];
    
//     for (int i = 0; i < numAppliances && i < selectedAppliances.length; i++) {
//       final appliance = selectedAppliances[i];
//       final baseWatts = appliance['baseWatts'] as int;
      
//       // Add some variation to the power consumption (±20%)
//       final variation = (baseWatts * 0.2 * (random.nextDouble() - 0.5)).round();
//       final actualWatts = math.max(5, baseWatts + variation);
      
//       allData.add(ApplianceData(
//         appliance['name'] as String,
//         actualWatts,
//         _palette[i % _palette.length],
//         appliance['icon'] as IconData,
//       ));
//     }

//     // Sort by power consumption (highest first)
//     allData.sort((a, b) => b.watts.compareTo(a.watts));
    
//     // Keep top 4 and group the rest as "Others"
//     List<ApplianceData> top4 = allData.take(4).toList();

//     if (allData.length > 4) {
//       int othersWatts = allData.skip(4).fold(0, (sum, item) => sum + item.watts);
//       top4.add(ApplianceData(
//         "Others", 
//         othersWatts, 
//         const Color(0xFF6B7280),
//         Icons.more_horiz
//       ));
//     }

//     setState(() {
//       appliancesData = top4;
//       isLoading = false;
//     });
    
//     _animationController.forward();
//   }

//   // Keep the original API method for when you want to switch back
//   Future<void> loadUserIdAndFetchPlugs() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? userId = prefs.getString('userId');

//     if (userId != null && userId.isNotEmpty) {
//       fetchUserPlugs(userId);
//     } else {
//       setState(() {
//         isLoading = false;
//         errorMessage = 'User ID not found.';
//       });
//     }
//   }

//   Future<void> fetchUserPlugs(String userId) async {
//     final url =
//         Uri.parse('${dotenv.env['BASE_URL']}/api/auth/mobile/$userId/plugs/');

//     try {
//       final res = await http.get(url);

//       if (res.statusCode == 200) {
//         final Map<String, dynamic> body = json.decode(res.body);
//         final List plugs = body['plugs'] ?? [];

//         List<ApplianceData> allData = plugs
//             .asMap()
//             .entries
//             .map((entry) => ApplianceData.fromJson(
//                 entry.value, entry.key, _palette, _icons))
//             .toList();

//         allData.sort((a, b) => b.watts.compareTo(a.watts));
//         List<ApplianceData> top4 = allData.take(4).toList();

//         if (allData.length > 4) {
//           int othersWatts =
//               allData.skip(4).fold(0, (sum, item) => sum + item.watts);
//           top4.add(ApplianceData("Others", othersWatts, const Color(0xFF6B7280),
//               Icons.more_horiz));
//         }

//         setState(() {
//           appliancesData = top4;
//           isLoading = false;
//         });
//         _animationController.forward();
//       } else {
//         setState(() {
//           errorMessage = 'Server responded with ${res.statusCode}';
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Network error: $e';
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final int totalWatts =
//         appliancesData.fold<int>(0, (sum, item) => sum + item.watts);
//     final double averageWatts =
//         appliancesData.isNotEmpty ? totalWatts / appliancesData.length : 0;

//     return Scaffold(
//       backgroundColor: const Color(0xFFE7F5E8),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header Section
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: const BoxDecoration(
//                 color: Color(0xFF109717),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'Energy Dashboard',
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: const Icon(
//                           Icons.bolt,
//                           color: Colors.white,
//                           size: 24,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildStatCard(
//                           title: 'Total Power',
//                           value: '${totalWatts}W',
//                           icon: Icons.power,
//                           color: Colors.white,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: _buildStatCard(
//                           title: 'Devices',
//                           value: '${appliancesData.length}',
//                           icon: Icons.devices,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             // Main Content
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     // Chart Section with Legend
//                     Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFFFFFFF),
//                         borderRadius: BorderRadius.circular(20),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 20,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Power Consumption',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF1F2937),
//                             ),
//                           ),
//                           const SizedBox(height: 20),
//                           SizedBox(
//                             height: 300,
//                             child: _buildChartContent(),
//                           ),
//                           // Legend
//                           if (!isLoading && errorMessage == null && appliancesData.isNotEmpty)
//                             _buildLegend(),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: const SafeArea(
//         bottom: false,
//         child: CustomBottomNavBar(selectedIndex: 0),
//       ),
//     );
//   }

//   Widget _buildStatCard({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Icon(icon, color: const Color(0xFF0D8013), size: 24),
//               const Icon(Icons.trending_up, color: Color(0xFF10B981), size: 16),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1F2937),
//             ),
//           ),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildChartContent() {
//     if (isLoading) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF109717)),
//             ),
//             SizedBox(height: 16),
//             Text('Loading energy data...'),
//           ],
//         ),
//       );
//     }

//     if (errorMessage != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline,
//               size: 48,
//               color: Colors.red[400],
//             ),
//             const SizedBox(height: 16),
//             Text(
//               errorMessage!,
//               style: TextStyle(color: Colors.red[600]),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }

//     if (appliancesData.isEmpty) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.power_off,
//               size: 48,
//               color: Colors.grey,
//             ),
//             SizedBox(height: 16),
//             Text('No devices found'),
//           ],
//         ),
//       );
//     }

//     return ModernBarChart(appliancesData: appliancesData);
//   }

//   Widget _buildLegend() {
//     return Container(
//       margin: const EdgeInsets.only(top: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Devices',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1F2937),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Wrap(
//             spacing: 16,
//             runSpacing: 8,
//             children: appliancesData.map((appliance) {
//               return Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: 16,
//                     height: 16,
//                     decoration: BoxDecoration(
//                       color: appliance.color,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     '${appliance.name} (${appliance.watts}W)',
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: Color(0xFF374151),
//                     ),
//                   ),
//                 ],
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildApplianceCard(ApplianceData appliance, double percentage) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: appliance.color.withOpacity(0.2),
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: appliance.color.withOpacity(0.1),
//             blurRadius: 20,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: appliance.color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(
//                   appliance.icon,
//                   color: appliance.color,
//                   size: 20,
//                 ),
//               ),
//               Text(
//                 '${percentage.toStringAsFixed(1)}%',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                   color: appliance.color,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             appliance.name,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1F2937),
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           const SizedBox(height: 4),
//           Text(
//             '${appliance.watts}W',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: appliance.color,
//             ),
//           ),
//           const SizedBox(height: 8),
//           LinearProgressIndicator(
//             value: percentage / 100,
//             backgroundColor: Colors.grey[200],
//             valueColor: AlwaysStoppedAnimation<Color>(appliance.color),
//             minHeight: 4,
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// ---------------------------------------------------------------------------
// ///  MODERN CHART
// /// ---------------------------------------------------------------------------
// class ModernBarChart extends StatelessWidget {
//   const ModernBarChart({Key? key, required this.appliancesData})
//       : super(key: key);

//   final List<ApplianceData> appliancesData;

//   @override
//   Widget build(BuildContext context) {
//     return SfCartesianChart(
//       backgroundColor: Colors.transparent,
//       plotAreaBorderWidth: 0,
//       tooltipBehavior: TooltipBehavior(
//         enable: true,
//         canShowMarker: false,
//         borderWidth: 0,
//         color: const Color(0xFF1F2937),
//         textStyle: const TextStyle(color: Colors.white),
//       ),
//       primaryXAxis: CategoryAxis(
//         majorGridLines: const MajorGridLines(width: 0),
//         axisLine: const AxisLine(width: 0),
//         labelStyle: const TextStyle(
//           color: Colors.transparent, // Hide X-axis labels
//           fontSize: 0,
//         ),
//         isVisible: false, // Hide entire X-axis
//       ),
//       primaryYAxis: NumericAxis(
//         majorGridLines: MajorGridLines(
//           width: 1,
//           color: Colors.grey[200]!,
//         ),
//         axisLine: const AxisLine(width: 0),
//         labelStyle: const TextStyle(
//           color: Color(0xFF6B7280),
//           fontSize: 12,
//         ),
//       ),
//       series: <CartesianSeries<ApplianceData, String>>[
//         ColumnSeries<ApplianceData, String>(
//           dataSource: appliancesData,
//           xValueMapper: (data, _) => data.name,
//           yValueMapper: (data, _) => data.watts,
//           pointColorMapper: (data, _) => data.color,
//           dataLabelSettings: const DataLabelSettings(
//             isVisible: true,
//             labelAlignment: ChartDataLabelAlignment.top,
//             textStyle: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1F2937),
//             ),
//           ),
//           borderRadius: const BorderRadius.only(
//             topLeft: Radius.circular(8),
//             topRight: Radius.circular(8),
//           ),
//           spacing: 0.3,
//         ),
//       ],
//     );
//   }
// }