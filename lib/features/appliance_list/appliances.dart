import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:ecotrack_mobile/widgets/navbar.dart';
import 'package:ecotrack_mobile/features/appliance_list/appliance_details.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppliancesPage extends StatefulWidget {
  const AppliancesPage({Key? key}) : super(key: key);

  @override
  _AppliancesPageState createState() => _AppliancesPageState();
}

class _AppliancesPageState extends State<AppliancesPage> {
  List<Map<String, dynamic>> _plugs = [];
  Map<String, bool> _plugStates = {};
  bool _isLoading = true;
  String? userId;

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

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchPlugs();
  }

  Future<void> _loadUserIdAndFetchPlugs() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString('userId');

    if (storedUserId != null) {
      if (!mounted) return;
      setState(() {
        userId = storedUserId;
      });

      await _fetchPlugs();
    } else {
      print("User ID not found in SharedPreferences");
    }
  }

  Future<void> _fetchPlugs() async {
    if (userId == null) {
      print('User ID is null');
      return;
    }

    final String apiUrl =
        '${dotenv.env['BASE_URL']}/api/auth/mobile/$userId/plugs';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List plugs = data['plugs'];

        Map<String, bool> plugStates = {};

        // Fetch status for each plug
        for (var plug in plugs) {
          final plugId = plug['_id'];
          final status = await fetchPlugSwitch(plugId);
          plugStates[plugId] = status;
        }

        if (!mounted) return;
        setState(() {
          _plugs = plugs.cast<Map<String, dynamic>>();
          _plugStates = plugStates;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load plugs');
      }
    } catch (e) {
      print('Error fetching plugs: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<bool> fetchPlugSwitch(String plugId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      print('Token not found');
      return false;
    }

    final url = Uri.parse('${dotenv.env['BASE_URL']}/api/plugs/$plugId/switch');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == true; // status is boolean
      } else {
        print('Failed to fetch plug status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error fetching plug status: $e');
      return false;
    }
  }

 Future<void> togglePlugPower(String plugId, bool turnOn) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null || token.isEmpty) {
    print('Token not found');
    return;
  }

  // Optimistically update UI if widget still mounted
  if (mounted) {
    setState(() {
      _plugStates[plugId] = turnOn;
    });
  }

  final endpoint = turnOn ? 'on' : 'off';
  final url =
      Uri.parse('${dotenv.env['BASE_URL']}/api/plugs/$plugId/$endpoint');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print('Plug $plugId turned ${turnOn ? 'on' : 'off'}');

      await Future.delayed(const Duration(seconds: 3)); // Give device time to update

      final confirmed = await fetchPlugSwitch(plugId);

      if (mounted) {
        setState(() {
          _plugStates[plugId] = confirmed;
        });
      }
    } else {
      print('Failed to toggle plug. Status code: ${response.statusCode}');

      if (mounted) {
        setState(() {
          _plugStates[plugId] = !turnOn; // revert UI toggle on failure
        });
      }
    }
  } catch (e) {
    print('Error toggling plug: $e');

    if (mounted) {
      setState(() {
        _plugStates[plugId] = !turnOn; // revert UI toggle on error
      });
    }
  }
}


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
      backgroundColor: const Color(0xFFF0E6FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 30, top: 20, bottom: 10),
              child: Text(
                'Appliances',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Gotham',
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _plugs.isEmpty
                      ? const Center(child: Text('No plugs found'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          itemCount: _plugs.length,
                          itemBuilder: (context, index) {
                            final plug = _plugs[index];
                            final isOn = _plugStates[plug['_id']] ?? false;

                            return _buildApplianceCard(
                              context,
                              title: plug['name'] ?? 'Unnamed Plug',
                              subtitle:
                                  '${plug['applianceName'] ?? 'Unknown Appliance'}\nTotal: ${plug['energy']?['Total']?.toStringAsFixed(3) ?? '0.000'} kWh',
                              iconPath: _getIconPath(
                                  plug['iconKey'], plug['iconVariant']),
                              isOn: isOn,
                              onToggle: (value) async {
                                setState(() {
                                  _plugStates[plug['_id']] = value;
                                });

                                await togglePlugPower(plug['_id'], value);
                              },
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ApplianceDetails(plugId: plug['_id']),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        bottom: false,
        child: CustomBottomNavBar(selectedIndex: 1),
      ),
    );
  }

  Widget _buildApplianceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String iconPath,
    required bool isOn,
    required Function(bool) onToggle,
    Function()? onTap,
    Color toggleColor = Colors.green,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Card(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Image.asset(
                  iconPath,
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.electrical_services, size: 50),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle.split('\n')[0],
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      Text(
                        subtitle.split('\n')[1],
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isOn,
                  onChanged: onToggle,
                  activeColor: toggleColor,
                  activeTrackColor: toggleColor.withOpacity(0.5),
                  inactiveThumbColor: Colors.grey[300],
                  inactiveTrackColor: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
