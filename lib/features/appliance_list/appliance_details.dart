import 'package:ecotrack_mobile/widgets/navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
      //fetchPlugInfo();
    fetchEnergyData();
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
        final fetchedEnergy = data['energy'];
       final fetchedPlugName = data['plugName'] ?? '';
       final fetchedApplianceName = data['applianceName'] ?? '';

        if (!mounted) return;
        setState(() {
          energy = fetchedEnergy ?? {};
         plugName = fetchedPlugName;
         applianceName = fetchedApplianceName;
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
/*
  Future<void> fetchPlugInfo() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    final url = Uri.parse('${dotenv.env['BASE_URL']}/api/plugs/${widget.plugId}');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('Plug Info Response: ${response.statusCode}');
    print('Plug Info Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        plugName = data['name'] ?? '';
        applianceName = data['applianceName'] ?? '';
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

*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
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
                                'assets/icons/appliancelogos/air-conditioner.png',
                                width: 120,
                                height: 120,
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
                                    '${energy['Total']?.toStringAsFixed(0) ?? '0'} W • $applianceName',
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
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 6)
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Live Metrics',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  childAspectRatio: 3.5,
                                  children: [
                                    _buildMetricTile(
                                        'Power', '${energy['Power'] ?? 0} W'),
                                    _buildMetricTile('Apparent Power',
                                        '${energy['ApparentPower'] ?? 0} VA'),
                                    _buildMetricTile('Reactive Power',
                                        '${energy['ReactivePower'] ?? 0} VAR'),
                                    _buildMetricTile('Voltage',
                                        '${energy['Voltage'] ?? 0} V'),
                                    _buildMetricTile('Current',
                                        '${energy['Current'] ?? 0} A'),
                                    _buildMetricTile(
                                        'Factor', '${energy['Factor'] ?? 0}'),
                                    _buildMetricTile(
                                        'Today', '${energy['Today'] ?? 0} kWh'),
                                    _buildMetricTile(
                                        'Total', '${energy['Total'] ?? 0} kWh'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 16),
                                children: [
                                  const TextSpan(
                                      text: 'Your appliance is consuming '),
                                  TextSpan(
                                    text: '${energy['Power'] ?? 0} W',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const TextSpan(
                                      text:
                                          '. Optimal usage can improve efficiency.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
