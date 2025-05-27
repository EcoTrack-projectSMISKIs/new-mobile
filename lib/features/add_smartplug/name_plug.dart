import 'package:flutter/material.dart';
import 'package:ecotrack_mobile/widgets/navbar.dart';
import 'package:ecotrack_mobile/features/appliance_list/appliances.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ecotrack_mobile/widgets/success_modal.dart';
import 'package:ecotrack_mobile/widgets/error_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

///
class NamePlugPage extends StatefulWidget {
  final String plugId;
  final String plugIp;

  const NamePlugPage({Key? key, required this.plugId, required this.plugIp})
      : super(key: key);

  @override
  State<NamePlugPage> createState() => _NamePlugPageState();
}

class _NamePlugPageState extends State<NamePlugPage> {
  final TextEditingController _applianceNameController =
      TextEditingController();
  late TextEditingController _plugNameController;
  String _selectedIconKey = 'default'; // Store icon key instead of full path
  int _selectedIconVariant = 0; // Track which variant is selected
  String _plugName = 'Plug 1';
  String? _selectedApplianceName;
  bool _isConnected = true;
  late TextEditingController _customApplianceNameController;

  final List<String> _applianceNames = [
    'Refrigerator',
    'Aircon',
    'Washing Machine',
    'Computer',
    'Laptop',
    'Smartphone',
    'Electric Fan',
    'Microwave',
    'TV',
    'Others',
  ];

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

  // Helper method to get current icon path
  String get _currentIconPath {
    final iconKey = _getIconKey(_selectedApplianceName);
    final variants =
        applianceIconVariants[iconKey] ?? applianceIconVariants['default']!;
    return variants[_selectedIconVariant.clamp(0, variants.length - 1)];
  }

  @override
  void initState() {
    super.initState();
    _plugNameController = TextEditingController(text: _plugName);
    _customApplianceNameController = TextEditingController();
  }

  @override
  void dispose() {
    _plugNameController.dispose();
    _customApplianceNameController.dispose();
    super.dispose();
  }

  void _saveDevice() async {
    final String plugName =
        _plugNameController.text.isEmpty ? _plugName : _plugNameController.text;
    final String applianceName = (_selectedApplianceName == 'Others')
        ? _customApplianceNameController.text
        : _selectedApplianceName ?? 'Unknown';
    final String iconKey = _getIconKey(applianceName);

    final String url =
        '${dotenv.env['BASE_URL']}/api/plugs/${widget.plugId}/rename';

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        context.showCustomErrorModal(
          message: 'Authentication token missing. Please login again.',
          onButtonPressed: () {
            Navigator.pop(context);
          },
        );
        return;
      }

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': plugName,
          'applianceName': applianceName,
          'iconKey': iconKey, // Send category key
          'iconVariant': _selectedIconVariant, // Send specific variant index
        }),
      );

      if (response.statusCode == 200) {
        // Configure MQTT Topic via Tasmota REST API
        try {
          final String newIp = widget.plugIp;
          final mqttTopic = 'ecotrack/plug/${widget.plugId}';

          // Set Topic
          final topicUrl =
              'http://$newIp/cm?cmnd=Topic%20${Uri.encodeComponent(mqttTopic)}';
          final topicResp = await http.get(Uri.parse(topicUrl));

          if (topicResp.statusCode != 200) {
            debugPrint('⚠️ Setting MQTT topic failed: ${topicResp.body}');
          }
        } catch (e) {
          debugPrint('⚠️ Error sending MQTT topic: $e');
        }

        // ✅ Show success modal
        context.showCustomSuccessModal(
          message: 'Device added successfully!',
          onButtonPressed: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AppliancesPage(),
              ),
            );
          },
        );
      } else {
        debugPrint('❌ Rename failed: ${response.statusCode} - ${response.body}');
        context.showCustomErrorModal(
          message: 'Could not add the device. Please try again.',
          onButtonPressed: () {
            Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      context.showCustomErrorModal(
        message: 'Something went wrong. Please check your internet connection.',
        onButtonPressed: () {
          Navigator.pop(context);
        },
      );
    }
  }

  String _getIconKey(String? applianceName) {
    if (applianceName == null) return 'default';

    final name = applianceName.trim().toLowerCase();

    switch (name) {
      case 'aircon':
      case 'air conditioner':
        return 'aircon';
      case 'computer':
        return 'computer';
      case 'electric fan':
      case 'fan':
        return 'fan';
      case 'laptop':
        return 'laptop';
      case 'microwave':
        return 'microwave';
      case 'refrigerator':
        return 'refrigerator';
      case 'smartphone':
        return 'smartphone';
      case 'tv':
        return 'tv';
      case 'washing machine':
        return 'washing_machine';
      default:
        return 'default';
    }
  }

  void _onApplianceChanged(String? value) {
    setState(() {
      _selectedApplianceName = value;
      final iconKey = _getIconKey(value);
      _selectedIconKey = iconKey;
      _selectedIconVariant = 0; // Reset to first variant when category changes
    });
  }

  Widget _buildIconSelector() {
    final iconKey = _getIconKey(_selectedApplianceName);
    List<String> iconVariants =
        applianceIconVariants[iconKey] ?? applianceIconVariants['default']!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: iconVariants.asMap().entries.map((entry) {
          int index = entry.key;
          String iconPath = entry.value;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIconVariant = index;
                _selectedIconKey = iconKey;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _selectedIconVariant == index
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: _selectedIconVariant == index
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
              ),
              child: Image.asset(
                iconPath,
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.error, size: 40, color: Colors.red);
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    'Congratulations, you have\nsuccessfully connected your device',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Please enter the name of the appliance\nyour device is connected to.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.8),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Name Your Smart Plug',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _plugNameController,
                        onChanged: (value) {
                          setState(() {
                            _plugName = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter Plug Name',
                          hintStyle:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Colors.green, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Colors.green, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Colors.green, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 15),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '   Connected',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Divider(height: 1, color: Colors.grey),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedApplianceName,
                        decoration: InputDecoration(
                          hintText: 'Select an appliance',
                          hintStyle: const TextStyle(
                              color: Colors.grey, fontSize: 12.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Colors.green, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Colors.green, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Colors.green, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 15),
                        ),
                        items: _applianceNames
                            .map((appliance) => DropdownMenuItem<String>(
                                  value: appliance,
                                  child: Text(appliance),
                                ))
                            .toList(),
                        onChanged: _onApplianceChanged, // Use the consistent method
                      ),
                      if (_selectedApplianceName == 'Others')
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: TextField(
                            controller: _customApplianceNameController,
                            decoration: InputDecoration(
                              hintText: 'Enter custom appliance name',
                              hintStyle: const TextStyle(
                                  color: Colors.grey, fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Colors.green, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Colors.green, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Colors.green, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 15),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Colors.grey),
                      const SizedBox(height: 20),
                      const Text(
                        'Choose an Icon for your Appliance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildIconSelector(), // Use the consistent icon selector
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    onPressed: _saveDevice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    child: const Text(
                      'Add Device',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.only(bottom: 12.0),
        child: CustomBottomNavBar(selectedIndex: 2),
      ),
    );
  }
}