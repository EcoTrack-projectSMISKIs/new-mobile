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
  final String apiUrl =
      ('${dotenv.env['BASE_URL']}/api/users/6809b239dccf6d94dcea2bfd/plugs');

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchPlugs();
  }

  Future<void> _loadUserIdAndFetchPlugs() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString('userId');

    if (storedUserId != null) {
      setState(() {
        userId = storedUserId;
      });

      await _fetchPlugs();
    } else {
      print("User ID not found in SharedPreferences");
    }
  }

  Future<void> _fetchPlugs() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List plugs = data['plugs'];

        setState(() {
          _plugs = plugs.cast<Map<String, dynamic>>();
          _plugStates = {
            for (var plug in _plugs) plug['_id']: false,
          };
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load plugs');
      }
    } catch (e) {
      print('Error fetching plugs: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> togglePlugPower(String plugId, bool turnOn) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      print('Token not found');
      return;
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
      } else {
        print('Failed to toggle plug. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error toggling plug: $e');
    }
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
                              iconPath:
                                  'assets/icons/appliancelogos/${plug['icon'] ?? 'plug'}.png',
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
