import 'package:flutter/material.dart';
import 'package:ecotrack_mobile/widgets/navbar.dart';
import 'package:ecotrack_mobile/features/appliance_list/appliances.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ecotrack_mobile/widgets/success_modal.dart';
import 'package:ecotrack_mobile/widgets/error_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _selectedIcon = 'plug'; // Default icon
  String _plugName = 'Plug 1';
  bool _isConnected = true;

// Appliances Icons
  final Map<String, String> _applianceIcons = {
    'plug': 'assets/icons/appliancelogos/plug.png',
    'earphones': 'assets/icons/appliancelogos/earphones.png',
    'hair_dryer': 'assets/icons/appliancelogos/hair-dryer.png',
    'laptop': 'assets/icons/appliancelogos/laptop-computer.png',
    'laundry': 'assets/icons/appliancelogos/laundry.png',
    'light_bulb': 'assets/icons/appliancelogos/light-bulb.png',
    'oven': 'assets/icons/appliancelogos/oven.png',
    'powerbank': 'assets/icons/appliancelogos/powerbank.png',
    'refrigerator': 'assets/icons/appliancelogos/refrigator.png',
    'smartphone': 'assets/icons/appliancelogos/smartphone.png',
    'tablet': 'assets/icons/appliancelogos/tablet.png',
    'toaster': 'assets/icons/appliancelogos/toaster.png',
    'tumble_dryer': 'assets/icons/appliancelogos/tumble-dryer.png',
    'airconditioner': 'assets/icons/appliancelogos/air-conditioner.png',
    'television': 'assets/icons/appliancelogos/tv.png',
  };

  // Suggested appliance names
  final List<String> _suggestions = ['Refrigerator', 'TV', 'Air Conditioner'];

  @override
  void initState() {
    super.initState();
    _plugNameController = TextEditingController(text: _plugName);
  }

  @override
  void dispose() {
    _applianceNameController.dispose();
    _plugNameController.dispose();
    super.dispose();
  }


void _saveDevice() async {
  final String plugName = _plugNameController.text.isEmpty ? _plugName : _plugNameController.text;
  final String applianceName = _applianceNameController.text;

  final String url = '${dotenv.env['BASE_URL']}/api/plugs/${widget.plugId}/rename';

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
      body: jsonEncode({'name': plugName, 'applianceName': applianceName}),
    );

    if (response.statusCode == 200) {
      // Configure MQTT Topic via Tasmota REST API
      try {
        final String newIp = widget.plugIp;
        final mqttTopic = 'ecotrack/plug/${widget.plugId}';

        // Set Topic
        final topicUrl = 'http://$newIp/cm?cmnd=Topic%20${Uri.encodeComponent(mqttTopic)}';
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
              // Optional: pass plug data later
              // AppliancesPage(
              //   plugData: {
              //     'icon': _selectedIcon,
              //     'plugId': widget.plugId,
              //   },
              // ),
            ),
          );
        },
      );
    } else {
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




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _plugNameController,
                            onChanged: (value) {
                              setState(() {
                                _plugName = value;
                              });
                            },
                            decoration: InputDecoration(
                              // labelText: 'Plug Name',
                              hintText: 'Enter Plug Name',
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
                          const SizedBox(height: 5),
                          const Text(
                            '   Connected',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Divider(height: 1, color: Colors.grey),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _applianceNameController,
                        decoration: InputDecoration(
                          hintText: 'What appliance is your plug connected to?',
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
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'SUGGESTIONS:',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: _suggestions
                            .map((suggestion) => GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _applianceNameController.text =
                                          suggestion;
                                    });
                                  },
                                  child: Chip(
                                    label: Text(suggestion),
                                    backgroundColor: Colors.grey.shade200,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ))
                            .toList(),
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
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _applianceIcons.entries.map((entry) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIcon = entry.key;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 8), // spacing between icons
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _selectedIcon == entry.key
                                      ? Colors.blue.withOpacity(0.2)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: _selectedIcon == entry.key
                                      ? Border.all(color: Colors.blue, width: 2)
                                      : null,
                                ),
                                child: Image.asset(
                                  entry.value,
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: CustomBottomNavBar(selectedIndex: 2),
      ),
    );
  }
}
