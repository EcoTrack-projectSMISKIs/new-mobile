import 'package:ecotrack_mobile/features/appliance_list/plug_history.dart';
import 'package:ecotrack_mobile/widgets/navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// Import your PlugHistoryPage here
// import 'plug_history.dart';

class ApplianceDetails extends StatefulWidget {
  final String plugId;

  const ApplianceDetails({Key? key, required this.plugId}) : super(key: key);

  @override
  State<ApplianceDetails> createState() => _ApplianceDetailsState();
}

class _ApplianceDetailsState extends State<ApplianceDetails> {
  Map<String, dynamic> energy = {};
  String plugName = '';
  String applianceName = '';
  bool isOn = false;
  bool isLoading = true;
  late String userId;
  String iconKey = 'default';
  String iconVariant = '1';
  String? recommendation;

  @override
  void initState() {
    super.initState();
    initializeUser();
    fetchRecommendation();
  }

  Future<void> initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    fetchPlugInfo();
    fetchEnergyData();
  }

  Future<void> fetchRecommendation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse(
            '${dotenv.env['BASE_URL']}/api/asis/${widget.plugId}/recommend'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        print('AI Recommendation Response: ${response.body}');
        final data = json.decode(response.body);
        setState(() {
          // recommendation = data['recommendation'] ?? "No recommendation found.";
          //recommendation ="${data['recommendation']}\n\nUsage: ${data['yesterdayUsage']}Wh\nNote: ${data['message']}";
          recommendation =
              "Based on your yesterday's usage (${data['yesterdayUsage']}kWh), ${data['recommendation']}"; // not sure if kwh or w
        });
      } else {
        setState(() {
          print(
              'AI Recommendation Response not working / does not have yesterday data: ${response.statusCode}');
          recommendation =
              "We're still collecting data to give you smart energy-saving tips. Keep using the app and connect your appliances so we can tailor advice just for you.";
        });
      }
    } catch (e) {
      print('AI Recommendation Response error: $e');
      setState(() {
        recommendation = "Error: ${e.toString()}";
      });
    }
  }

  Future<void> fetchEnergyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final url = Uri.parse(
          '${dotenv.env['BASE_URL']}/api/plugs/${widget.plugId}/status');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Request URL: $url');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        //final fetchedEnergy = data['energy'];
        final fetchedEnergy = data['raw']['StatusSNS']['ENERGY'];
        // final fetchedPlugName = data['plugName'] ?? '';
        //final fetchedApplianceName = data['applianceName'] ?? '';

        if (!mounted) return;
        setState(() {
          energy = fetchedEnergy ?? {};
          // plugName = fetchedPlugName;
          // applianceName = fetchedApplianceName;
          isOn = (energy['Power'] ?? 0) > 0;
          isLoading = false;
        });
      } else {
        throw Exception(
            'Failed to load energy data. Plug is probably offline.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

//   Future<void> fetchPlugInfo() async {
//   try {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');

//     if (token == null || token.isEmpty) {
//       throw Exception('Authentication token not found');
//     }

//     final url = Uri.parse('${dotenv.env['BASE_URL']}api/auth/mobile/${userId}/plugs');

//     final response = await http.get(
//       url,
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//     );

//     print('Plug Info Response: ${response.statusCode}');
//     print('Plug Info Body: ${response.body}');

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (!mounted) return;
//       setState(() {
//         plugName = data['name'] ?? '';
//         applianceName = data['applianceName'] ?? '';
//       });
//     } else {
//       throw Exception('Failed to load plug info');
//     }
//   } catch (e) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error loading plug info: $e')),
//     );
//   }
// }

  Future<void> fetchPlugInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final url = Uri.parse(
          '${dotenv.env['BASE_URL']}/api/auth/mobile/$userId/plugs/${widget.plugId}');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final plug = jsonDecode(response.body);

        if (!mounted) return;
        setState(() {
          plugName = plug['name'] ?? '';
          applianceName = plug['applianceName'] ?? '';
          iconKey = plug['iconKey'] ?? 'default';
          iconVariant = plug['iconVariant']?.toString() ?? '0';
        });
      } else {
        throw Exception('Failed to load plug info');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading plug info: $e')),
      );
    }
  }

  // Icon variants map - same as in name_plug.dart
  final Map<String, List<String>> applianceIconVariants = {
    'aircon': [
      'assets/icons/appliancelogos/aircon/aircon.png',
      'assets/icons/appliancelogos/aircon/aircon_2.png',
      'assets/icons/appliancelogos/aircon/aircon_3.png',
      'assets/icons/appliancelogos/aircon/aircon_4.png',
      'assets/icons/appliancelogos/aircon/aircon_5.png',
    ],
    'computer': [
      'assets/icons/appliancelogos/computer/computer.png',
      'assets/icons/appliancelogos/computer/computer_2.png',
      'assets/icons/appliancelogos/computer/computer_3.png',
      'assets/icons/appliancelogos/computer/computer_4.png',
      'assets/icons/appliancelogos/computer/computer_5.png',
    ],
    'fan': [
      'assets/icons/appliancelogos/fan/fan.png',
      'assets/icons/appliancelogos/fan/fan_2.png',
      'assets/icons/appliancelogos/fan/fan_3.png',
      'assets/icons/appliancelogos/fan/fan_4.png',
      'assets/icons/appliancelogos/fan/fan_5.png',
    ],
    'laptop': [
      'assets/icons/appliancelogos/laptop/laptop.png',
      'assets/icons/appliancelogos/laptop/laptop_2.png',
      'assets/icons/appliancelogos/laptop/laptop_3.png',
      'assets/icons/appliancelogos/laptop/laptop_4.png',
      'assets/icons/appliancelogos/laptop/laptop_5.png',
    ],
    'microwave': [
      'assets/icons/appliancelogos/microwave/microwave.png',
      'assets/icons/appliancelogos/microwave/microwave_2.png',
      'assets/icons/appliancelogos/microwave/microwave_3.png',
      'assets/icons/appliancelogos/microwave/microwave_4.png',
      'assets/icons/appliancelogos/microwave/microwave_5.png',
    ],
    'refrigerator': [
      'assets/icons/appliancelogos/refrigerator/refrigerator.png',
      'assets/icons/appliancelogos/refrigerator/refrigerator_2.png',
      'assets/icons/appliancelogos/refrigerator/refrigerator_3.png',
      'assets/icons/appliancelogos/refrigerator/refrigerator_4.png',
      'assets/icons/appliancelogos/refrigerator/refrigerator_5.png',
    ],
    'smartphone': [
      'assets/icons/appliancelogos/smartphone/phone.png',
      'assets/icons/appliancelogos/smartphone/phone_2.png',
      'assets/icons/appliancelogos/smartphone/phone_3.png',
      'assets/icons/appliancelogos/smartphone/phone_4.png',
      'assets/icons/appliancelogos/smartphone/phone_5.png',
    ],
    'tv': [
      'assets/icons/appliancelogos/tv/tv.png',
      'assets/icons/appliancelogos/tv/tv_2.png',
      'assets/icons/appliancelogos/tv/tv_3.png',
      'assets/icons/appliancelogos/tv/tv_4.png',
      'assets/icons/appliancelogos/tv/tv_5.png',
    ],
    'washing_machine': [
      'assets/icons/appliancelogos/washing_machine/washingmachine.png',
      'assets/icons/appliancelogos/washing_machine/washingmachine_2.png',
      'assets/icons/appliancelogos/washing_machine/washingmachine_3.png',
      'assets/icons/appliancelogos/washing_machine/washingmachine_4.png',
      'assets/icons/appliancelogos/washing_machine/washingmachine_5.png',
      'assets/icons/appliancelogos/washing_machine/tumble-dryer.png',
    ],
    'default': [
      'assets/icons/appliancelogos/default/default.png',
      'assets/icons/appliancelogos/default/default_2.png',
      'assets/icons/appliancelogos/default/default_3.png',
      'assets/icons/appliancelogos/default/default_4.png',
      'assets/icons/appliancelogos/default/default_5.png',
    ],
  };

  // Helper method to get the correct icon path based on iconKey and iconVariant
  String _getIconPath(String? iconKey, int? iconVariant) {
    final key = iconKey ?? 'default';
    final variant = iconVariant ?? 0;

    final variants =
        applianceIconVariants[key] ?? applianceIconVariants['default']!;
    final safeVariant = variant.clamp(0, variants.length - 1);

    return variants[safeVariant];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        // backgroundColor: Color(0xFF109717),
        leading: IconButton(
          color: Color(0xFF109717),
          //color: Colors.white,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              Image.asset(
                                _getIconPath(
                                    iconKey, int.tryParse(iconVariant)),
                                width: 120,
                                height: 120,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 120),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                plugName,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: isOn
                                          ? Colors.green
                                          : (energy['Power'] == null
                                              ? Colors.orange
                                              : Colors.grey),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(
                                    '${energy['Total'] ?? '0'} W • $applianceName',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // // ENERGY CONSUMPTION HISTORY LINK
                        // Padding(
                        //   padding: const EdgeInsets.symmetric(horizontal: 16),
                        //   child: Align(
                        //     alignment: Alignment.centerRight,
                        //     child: GestureDetector(
                        //       onTap: () {
                        //         Navigator.push(
                        //           context,
                        //           MaterialPageRoute(
                        //             builder: (context) =>
                        //                 PlugHistoryPage(plugId: widget.plugId),
                        //           ),
                        //         );
                        //       },
                        //       child: Row(
                        //         mainAxisSize: MainAxisSize.min,
                        //         children: [
                        //           Icon(
                        //             Icons.history,
                        //             size: 14,
                        //             color: Colors.grey[600],
                        //           ),
                        //           const SizedBox(width: 4),
                        //           Text(
                        //             'View History  ',
                        //             style: TextStyle(
                        //               fontSize: 12,
                        //               color: Colors.grey[600],
                        //               fontWeight: FontWeight.w400,
                        //             ),
                        //           ),
                        //         ],
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        //const SizedBox(height: 5),
// IMPROVED LIVE METRICS SECTION
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.grey.shade50,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.analytics_outlined,
                                        color: Colors.blue.shade600,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Live Metrics',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade600,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Live',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.3,
                                  children: [
                                    _buildEnhancedMetricTile(
                                      'Power',
                                      '${energy['Power'] ?? 0}',
                                      'W',
                                      Icons.flash_on,
                                      Colors.orange,
                                      true, // Primary metric
                                    ),
                                    _buildEnhancedMetricTile(
                                      'Voltage',
                                      '${energy['Voltage'] ?? 0}',
                                      'V',
                                      Icons.electrical_services,
                                      Colors.blue,
                                    ),
                                    _buildEnhancedMetricTile(
                                      'Current',
                                      '${energy['Current'] ?? 0}',
                                      'A',
                                      Icons.settings_input_component,
                                      Colors.purple,
                                    ),
                                    _buildEnhancedMetricTile(
                                      'Factor',
                                      '${energy['Factor'] ?? 0}',
                                      '',
                                      Icons.analytics,
                                      Colors.green,
                                    ),
                                    _buildEnhancedMetricTile(
                                      'Apparent Power',
                                      '${energy['ApparentPower'] ?? 0}',
                                      'VA',
                                      Icons.power,
                                      Colors.indigo,
                                    ),
                                    _buildEnhancedMetricTile(
                                      'Reactive Power',
                                      '${energy['ReactivePower'] ?? 0}',
                                      'VAR',
                                      Icons.power_settings_new,
                                      Colors.teal,
                                    ),
                                    _buildEnhancedMetricTile(
                                      'Today',
                                      '${energy['Today'] ?? 0}',
                                      'kWh',
                                      Icons.today,
                                      Colors.amber,
                                    ),
                                    _buildEnhancedMetricTile(
                                      'Total',
                                      '${energy['Total'] ?? 0}',
                                      'kWh',
                                      Icons.bar_chart,
                                      Colors.red,
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PlugHistoryPage(
                                              plugId: widget.plugId),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.history,
                                          size: 20,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'View Energy Consumption History',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w400,
                                            decoration: TextDecoration.underline, 
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Text("AI Recommendation",
                        //     style: TextStyle(
                        //       fontSize: 20,
                        //       fontWeight: FontWeight.bold,
                        //       color: Colors.black87,
                        //     )),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "     AI Recommendation",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        // AI PART IS HERE ================================================
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // RichText(
                                //   text: TextSpan(
                                //     style: const TextStyle(
                                //       color: Colors.black87,
                                //       fontSize: 16,
                                //     ),
                                //     children: [
                                //       const TextSpan(
                                //           text: 'Your appliance is consuming '),
                                //       TextSpan(
                                //         text: '${energy['Power'] ?? 0} W',
                                //         style: const TextStyle(
                                //             fontWeight: FontWeight.bold),
                                //       ),
                                //       const TextSpan(
                                //         text:
                                //             '. Optimal usage can improve efficiency.',
                                //       ),
                                //     ],
                                //   ),
                                // ),
                                // const SizedBox(height: 16),
                                if (recommendation != null) ...[
                                  // const Text(
                                  //   "AI Recommendation",
                                  //   style: TextStyle(
                                  //     fontSize: 20,
                                  //     fontWeight: FontWeight.bold,
                                  //     color: Colors.black87,
                                  //   ),
                                  // ),
                                  //const SizedBox(height: 8),
                                  Text(
                                    recommendation!,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ] else
                                  const Center(
                                      child: CircularProgressIndicator()),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEnhancedMetricTile(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color, [
    bool isPrimary = false,
  ]) {
    // Create darker version of color for text and icons
    Color darkerColor = Color.fromRGBO(
      (color.red * 0.7).round(),
      (color.green * 0.7).round(),
      (color.blue * 0.7).round(),
      1.0,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPrimary ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary ? color.withOpacity(0.3) : Colors.grey.shade200,
          width: isPrimary ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? color.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: isPrimary ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: darkerColor,
                ),
              ),
              if (isPrimary)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PRIMARY',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: darkerColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isPrimary ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: isPrimary ? darkerColor : const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
