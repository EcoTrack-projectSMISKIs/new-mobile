import 'dart:convert';
import 'package:ecotrack_mobile/widgets/error_modal.dart';
import 'package:ecotrack_mobile/widgets/success_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditApplianceService {
  // Static method to show edit appliance modal
  static Future<void> showEditApplianceModal({
    required BuildContext context,
    required Map<String, dynamic> plug,
    required VoidCallback onSuccess,
  }) async {
    // Controllers for the edit modal
    final TextEditingController editPlugNameController =
        TextEditingController(text: plug['name'] ?? 'Plug 1');
      
    // State variables for the modal
    String selectedIconKey = plug['iconKey'] ?? 'default';
    int selectedIconVariant = plug['iconVariant'] ?? 0;

    final List<String> applianceNames = [
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

    String? selectedApplianceName =
        applianceNames.contains(plug['applianceName'])
            ? plug['applianceName']
            : 'Others';

    final TextEditingController editCustomApplianceController =
        TextEditingController(
            text:
                selectedApplianceName == 'Others' ? plug['applianceName'] : '');

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

    String getIconKey(String? applianceName) {
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

    Widget buildIconSelector(StateSetter setModalState) {
      final iconKey = getIconKey(selectedApplianceName);
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
                setModalState(() {
                  selectedIconVariant = index;
                  selectedIconKey = iconKey;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selectedIconVariant == index
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: selectedIconVariant == index
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

    // Show loading dialog
    void showLoadingDialog() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFF109717)),
            ),
          ),
        ),
      );
    }

    // Check if the form is valid
    bool isFormValid() {
      if (selectedApplianceName == 'Others') {
        return editCustomApplianceController.text.trim().isNotEmpty;
      }
      return true; // If not "Others", always valid
    }

    // Save edited device
    Future<void> saveEditedDevice() async {
      // Show loading indicator
      showLoadingDialog();

      // Wait 1 second (simulate loading)
      await Future.delayed(const Duration(seconds: 1));

      final String plugName = editPlugNameController.text.isEmpty
          ? 'Plug 1'
          : editPlugNameController.text;

      final String applianceName = (selectedApplianceName == 'Others')
          ? editCustomApplianceController.text
          : selectedApplianceName ?? 'Unknown';

      final String iconKey = getIconKey(applianceName);
      final String url =
          '${dotenv.env['BASE_URL']}/api/plugs/${plug['_id']}/rename';

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? token = prefs.getString('token');

        if (token == null || token.isEmpty) {
          Navigator.pop(context); // Close loading dialog
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
            'iconKey': iconKey,
            'iconVariant': selectedIconVariant,
          }),
        );

        Navigator.pop(context); // Close loading dialog

        if (response.statusCode == 200) {
          Navigator.pop(context); // Close modal

          context.showCustomSuccessModal(
            message: 'Device updated successfully!',
            onButtonPressed: () {
              Navigator.pop(context); // Close success modal
              onSuccess(); // Call the success callback
            },
          );
        } else {
          debugPrint(
              '❌ Update failed: ${response.statusCode} - ${response.body}');
          context.showCustomErrorModal(
            message: 'Could not update the device. Please try again.',
            onButtonPressed: () {
              Navigator.pop(context);
            },
          );
        }
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        _showErrorModal(context,
            'Something went wrong. Please check your internet connection.');
      }
    }

    // Show the modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header with close button
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.grey),
                        ),
                        const Expanded(
                          child: Text(
                            'Edit your Device',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the close button
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
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

                          // Main form container
                          Container(
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
                                  controller: editPlugNameController,
                                  decoration: InputDecoration(
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
                                const SizedBox(height: 15),
                                const Divider(height: 1, color: Colors.grey),
                                const SizedBox(height: 20),

                                // Appliance dropdown
                                DropdownButtonFormField<String>(
                                  value: selectedApplianceName,
                                  decoration: InputDecoration(
                                    hintText: 'Select an appliance',
                                    hintStyle: const TextStyle(
                                        color: Colors.grey, fontSize: 12.5),
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
                                  items: applianceNames
                                      .map((appliance) =>
                                          DropdownMenuItem<String>(
                                            value: appliance,
                                            child: Text(appliance),
                                          ))
                                      .toList(),
                                  onChanged: (String? value) {
                                    setModalState(() {
                                      selectedApplianceName = value;
                                      final iconKey = getIconKey(value);
                                      selectedIconKey = iconKey;
                                      selectedIconVariant = 0;
                                    });
                                  },
                                ),

                                // Custom appliance name field
                                if (selectedApplianceName == 'Others')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: TextField(
                                      controller: editCustomApplianceController,
                                      onChanged: (value) {
                                        // Update the UI when text changes
                                        setModalState(() {});
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Enter custom appliance name',
                                        hintStyle: const TextStyle(
                                            color: Colors.grey, fontSize: 14),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Colors.green, width: 2),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Colors.green, width: 2),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Colors.green, width: 2),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 15, vertical: 15),
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 20),
                                const Divider(height: 1, color: Colors.grey),
                                const SizedBox(height: 20),

                                // Icon selector
                                const Text(
                                  'Choose an Icon for your Appliance',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                buildIconSelector(setModalState),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Save button - disabled when form is invalid
                          ElevatedButton(
                            onPressed: isFormValid() ? saveEditedDevice : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFormValid() 
                                  ? Colors.green 
                                  : Colors.grey.shade400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              minimumSize: const Size(double.infinity, 55),
                            ),
                            child: Text(
                              'Update Device',
                              style: TextStyle(
                                fontSize: 18,
                                color: isFormValid() 
                                    ? Colors.white 
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
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
          },
        );
      },
    );
  }

  // Helper method to show error modal
  static void _showErrorModal(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Helper method to show success modal
  static void _showSuccessModal(
      BuildContext context, String message, VoidCallback onSuccess) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onSuccess();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}