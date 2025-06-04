import 'dart:convert';
import 'package:ecotrack_mobile/features/appliance_list/delete_appliance.dart';
import 'package:ecotrack_mobile/features/appliance_list/edit_appliance.dart';
import 'package:ecotrack_mobile/widgets/error_modal.dart';
import 'package:ecotrack_mobile/widgets/success_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:ecotrack_mobile/widgets/navbar.dart';
import 'package:ecotrack_mobile/features/appliance_list/appliance_details.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Add this dependency

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
  String? _openSlidableId;

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

// Add this to your class variables
Map<String, double> _energyTotals = {};

// Updated _fetchPlugs method with energy data fetching
Future<void> _fetchPlugs() async {
  if (userId == null) {
    print('User ID is null');
    return;
  }

  final String apiUrl = '${dotenv.env['BASE_URL']}/api/auth/mobile/$userId/plugs';
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  try {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List plugs = data['plugs'];

      Map<String, bool> plugStates = {};
      Map<String, double> energyTotals = {};

      // Fetch status and energy for each plug
      for (var plug in plugs) {
        final plugId = plug['_id'];
        
        // Fetch switch status
        final status = await fetchPlugSwitch(plugId);
        plugStates[plugId] = status;
        
        // Fetch real-time energy data if token exists
        if (token != null && token.isNotEmpty) {
          final energy = await fetchTotalEnergy(plugId, token);
          if (energy != null) {
            energyTotals[plugId] = energy;
          } else {
            energyTotals[plugId] = 0.0; // Default to 0 if fetch fails
          }
        } else {
          energyTotals[plugId] = 0.0; // Default if no token
        }
      }

      if (!mounted) return;
      setState(() {
        _plugs = plugs.cast<Map<String, dynamic>>();
        _plugStates = plugStates;
        _energyTotals = energyTotals;
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

// Helper method to get formatted energy display
String _getEnergyDisplay(String plugId) {
  final energy = _energyTotals[plugId];
  
  if (energy != null) {
    return '${energy.toStringAsFixed(3)} kWh';
  }
  
  // Fallback to 0.000 if no energy data
  return '0.000 kWh';
}

// Enhanced subtitle with energy data from _energyTotals
String _getSubtitle(Map<String, dynamic> plug) {
  final applianceName = plug['applianceName'] ?? 'Unknown Appliance';
  final energyDisplay = _getEnergyDisplay(plug['_id']);
  
  return '$applianceName\nTotal: $energyDisplay';
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication token not found'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }

  // Get plug name for better user feedback
  final plug = _plugs.firstWhere((p) => p['_id'] == plugId, orElse: () => {});
  final plugName = plug['name'] ?? 'Plug';

  // Optimistically update UI if widget still mounted
  if (mounted) {
    setState(() {
      _plugStates[plugId] = turnOn;
    });
  }

  final endpoint = turnOn ? 'on' : 'off';
  final url = Uri.parse('${dotenv.env['BASE_URL']}/api/plugs/$plugId/$endpoint');

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

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$plugName successfully turned ${turnOn ? 'on' : 'off'}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await Future.delayed(const Duration(seconds: 3)); // Give device time to update

      final confirmed = await fetchPlugSwitch(plugId);

      if (mounted) {
        setState(() {
          _plugStates[plugId] = confirmed;
        });

        // If the confirmed state doesn't match what we expected, show a warning
        if (confirmed != turnOn) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$plugName state may not have updated correctly'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      print('Failed to toggle plug. Status code: ${response.statusCode}');

      // Show error snackbar
      if (mounted) {
        setState(() {
          _plugStates[plugId] = !turnOn; // revert UI toggle on failure
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to turn ${turnOn ? 'on' : 'off'} $plugName'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  } catch (e) {
    print('Error toggling plug: $e');

    // Show error snackbar
    if (mounted) {
      setState(() {
        _plugStates[plugId] = !turnOn; // revert UI toggle on error
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error turning ${turnOn ? 'on' : 'off'} $plugName'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

  Future<double?> fetchTotalEnergy(String plugId, String token) async {
  try {
    final url = Uri.parse('${dotenv.env['BASE_URL']}/api/plugs/$plugId/status');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final total = data['raw']?['StatusSNS']?['ENERGY']?['Total'];
      if (total != null && total is num) {
        return total.toDouble();
      } else {
        print('Total energy data is missing or invalid');
        return null;
      }
    } else {
      print('Failed to fetch plug status: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error fetching plug status: $e');
    return null;
  }
}

  Future<void> _editAppliance(Map<String, dynamic> plug) async {
    await EditApplianceService.showEditApplianceModal(
      context: context,
      plug: plug,
      onSuccess: () async {
        // Set loading state
        setState(() {
          _isLoading = true;
        });

        try {
          // Refresh the appliances list
          await _loadUserIdAndFetchPlugs();
        } catch (e) {
          // Handle error if needed
          debugPrint('Error refreshing: $e');
        } finally {
          // Always set loading to false when done
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

// Method to handle deleting an appliance
  // Method to handle plug removal from local state
  void _removePlugFromState(String plugId) {
    _plugs.removeWhere((plug) => plug['_id'] == plugId);
    _plugStates.remove(plugId);
  }

  // Method to trigger UI update
  void _updateUI() {
    setState(() {});
  }

  // Method to call when you want to delete an appliance
  void _onDeletePressed(String plugId, String plugName) {
    ApplianceDeleteHelper.deleteAppliance(
      context: context,
      plugId: plugId,
      plugName: plugName,
      onPlugRemoved: _removePlugFromState,
      onStateUpdate: _updateUI,
    );
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
      backgroundColor: const Color(0xFFE7F5E8),
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
                  ? const Center(
                      child: CircularProgressIndicator(
                      color: Color(0xFF119718),
                    ))
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
                              plug: plug,
                              title: plug['name'] ?? 'Unnamed Plug',
                              // subtitle:
                              //     '${plug['applianceName'] ?? 'Unknown Appliance'}\nTotal: ${plug['energy']?['Total']?.toStringAsFixed(3) ?? '0.000'} kWh',
                              subtitle: _getSubtitle(plug), // Using the helper method
                              iconPath: _getIconPath(
                                  plug['iconKey'], plug['iconVariant']),
                              isOn: isOn,
                              //isDisabled: plug['disabled'] ?? false,
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
    required Map<String, dynamic> plug,
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
      child: Slidable(
        key: Key(plug['_id']),
        closeOnScroll: true,
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.4,
          children: [
            CustomSlidableAction(
              onPressed: (context) => _editAppliance(plug),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              child: const Icon(Icons.edit, size: 32),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
            CustomSlidableAction(
              onPressed: (context) => _onDeletePressed(
                plug['_id'],
                plug['name'] ?? 'Unnamed Plug',
              ),
              backgroundColor: Colors.red,
              child: const Icon(Icons.delete, size: 32, color: Colors.white),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          child: Card(
            elevation: 4, // Changed from 0 to 4 for shadow
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
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        Text(
                          subtitle.split('\n')[1],
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onToggle(!isOn),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Switch.adaptive(
                        value: isOn,
                        activeColor: toggleColor,
                        onChanged: null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
