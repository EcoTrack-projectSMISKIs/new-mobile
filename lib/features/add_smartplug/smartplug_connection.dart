import 'dart:convert';

import 'package:ecotrack_mobile/features/add_smartplug/scanTasmotaIP.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:io'; // For SocketException
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:ecotrack_mobile/features/add_smartplug/name_plug.dart';

// ADD DISCONNECT PLUG LOGIC (DONE)
// USE SAVE PREVIOUS WIFI SSID AND PASSWORD TO THE DEVICE AFTER CONFIGURATION (OPTIONAL SINCE PLUG NOW AUTOMATICALLY DISCONNECTS AND THERE IS AUTO-JOINING TO THE HOME WIFI NETWORK)
// ADD MQTT CONFIGURATION TO THE PLUG (DONE)
// PASS USER ID TO THE PLUG HERE

// THIS METHOD USES http://192.168.4.1/cm?cmnd=STATUS%200 BEFORE THE PLUG DISCONNECTS TO THE AP MODE OF PLUG

class PlugConnectedScreen extends StatefulWidget {
  final WiFiAccessPoint plugAccessPoint;

  const PlugConnectedScreen({Key? key, required this.plugAccessPoint})
      : super(key: key);

  @override
  State<PlugConnectedScreen> createState() => _PlugConnectedScreenState();
}

class _PlugConnectedScreenState extends State<PlugConnectedScreen> {
  final TextEditingController _homeWifiSsidController = TextEditingController();
  final TextEditingController _homeWifiPasswordController =
      TextEditingController();

  final List<String> _PLUG_AP_SSIDS = ['ecotrack-plug', 'tasmota'];
  List<WiFiAccessPoint> homeNetworks = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _scanHomeNetworks();
  }

  Future<void> _scanHomeNetworks() async {
    setState(() {
      isScanning = true;
    });

    try {
      await WiFiScan.instance.startScan();
      homeNetworks = await WiFiScan.instance.getScannedResults();
      homeNetworks = homeNetworks
          .where((network) => !_PLUG_AP_SSIDS.any((plugSsid) =>
              network.ssid.toLowerCase().contains(plugSsid.toLowerCase())))
          .toList();
    } catch (e) {
      print('Error scanning home networks: $e');
    }

    setState(() {
      isScanning = false;
    });
  }

  // New function to refresh WiFi networks
  Future<void> _refreshHomeNetworks() async {
    // Show a loading indicator when refreshing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing WiFi networks...')),
    );

    await _scanHomeNetworks();

    // Show completion message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(homeNetworks.isEmpty
            ? 'No WiFi networks found'
            : '${homeNetworks.length} WiFi networks found'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configure Plug')),
      body: isScanning
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Configure ${widget.plugAccessPoint.ssid}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select your home WiFi network:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // Add refresh button
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _refreshHomeNetworks,
                        tooltip: 'Refresh WiFi networks',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: homeNetworks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                    'No networks found. Please check your WiFi.'),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _refreshHomeNetworks,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Refresh'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: homeNetworks.length,
                            itemBuilder: (context, index) {
                              final network = homeNetworks[index];
                              return ListTile(
                                title: Text(network.ssid),
                                leading: Icon(
                                  _homeWifiSsidController.text == network.ssid
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: Colors.blue,
                                ),
                                trailing: Text(
                                  '${network.level} dBm',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                onTap: () {
                                  setState(() {
                                    _homeWifiSsidController.text = network.ssid;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _homeWifiSsidController,
                    decoration: const InputDecoration(
                      labelText: 'WiFi Network',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _homeWifiPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'WiFi Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (_homeWifiSsidController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please select or enter a WiFi network')),
                        );
                        return;
                      }
                      _configureSmartPlug(
                        widget.plugAccessPoint,
                        _homeWifiSsidController.text.trim(),
                        _homeWifiPasswordController.text.trim(),
                        context, // Pass context to the function
                      );
                    },
                    child: const Text('Configure Plug'),
                  ),
                ],
              ),
            ),
    );
  }

/*
// DOUBLE CHECK THIS URL
  Future<void> registerPlugToUser(String ip, String userId) async {
    //final url = Uri.parse(
      //  '${dotenv.env['BASE_URL']}/api/plugs/addFromDevice/$ip/$userId');

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _showSuccessDialog("Plug Linked",
            "The smart plug has been successfully registered to your account.");
        print("Plug successfully linked to user.");
      } else {
        _showErrorDialog("Linking Failed",
            "Failed to link the plug. ${response.statusCode} ${response.body}");
        print("Backend error: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("Error contacting backend: $e");
    }
  }
 */

  Future<void> waitForInternetConnection() async {
    const timeout = Duration(seconds: 60); // Increased timeout
    const pollInterval = Duration(seconds: 2);
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      final result = await Connectivity().checkConnectivity();
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        try {
          // Try connecting to a reliable host to confirm actual internet access
          final lookup = await InternetAddress.lookup('google.com');
          if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
            print("✅ Internet connection detected.");
            return; // Internet is available
          }
        } catch (_) {
          // Device is connected to WiFi/Mobile but has no internet yet
        }
      }
      await Future.delayed(pollInterval);
    }
    throw TimeoutException("No internet connection after plug configuration.");
  }

  Future<String?> retryRegisterPlug(String newIp, String userId,
      {int retries = 5}) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        print("🔄 Attempt ${attempt + 1} to register plug...");
        await Future.delayed(Duration(seconds: 5 + attempt * 2));

        final plugId = await registerPlugToUser(newIp, userId);

        if (plugId != null) {
          print("✅ Plug successfully registered on attempt ${attempt + 1}");
          return plugId;
        } else {
          print(
              "⚠️ Attempt ${attempt + 1} failed but no exception was thrown.");
        }
      } catch (e) {
        print("⚠️ Attempt ${attempt + 1} threw an exception: $e");
      }

      if (attempt < retries - 1) {
        print(
            "🔁 Retrying registerPlugToUser in ${5 + attempt * 2} seconds...");
      } else {
        print("❌ All retry attempts failed.");
      }
    }

    return null;
  }

  Future<bool> waitForDnsReady(String host,
      {int retries = 5, Duration delay = const Duration(seconds: 2)}) async {
    for (int i = 0; i < retries; i++) {
      try {
        final result = await InternetAddress.lookup(host);
        if (result.isNotEmpty) {
          print("✅ DNS for $host is ready: ${result[0].address}");
          return true;
        }
      } catch (_) {
        print("⏳ DNS not ready yet. Retrying...");
        await Future.delayed(delay);
      }
    }
    print("❌ DNS never resolved after $retries attempts.");
    return false;
  }

  Future<String?> registerPlugToUser(String ip, String userId) async {
    final url = Uri.parse(
        '${dotenv.env['BASE_URL']}/api/plugs/addFromDevice/${Uri.encodeComponent(ip)}/${Uri.encodeComponent(userId)}');

    print("Attempting to register plug at: $url");
    final result = await Connectivity().checkConnectivity();
    print("📶 Connectivity status: $result");

    try {
      print("⏳ Waiting for 10 seconds before sending request...");
      print('Final request URL: $url');
      await Future.delayed(const Duration(seconds: 10));
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      print("📬 Response status: ${response.statusCode}");
      print("📄 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['plug'] != null && jsonData['plug']['_id'] != null) {
          return jsonData['plug']['_id'];
        } else {
          print("❌ '_id' not found in response");
          return null;
        }
      } else {
        print("❌ Backend error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } on SocketException catch (e) {
      print("❌ SocketException: $e");
      return null;
    } on TimeoutException catch (e) {
      print("⏱️ TimeoutException: $e");
      return null;
    } catch (e) {
      print("❗ General Exception: $e");
      return null;
    }
  }

  // Add a method to bind to the Wi-Fi network
  Future<bool> bindToWifiNetwork({bool internetRequired = true}) async {
    const platform = MethodChannel('com.example.network/bind');
    try {
      final bool result = await platform.invokeMethod('bindNetwork', {
        'internetRequired': internetRequired,
      });
      print('✅ bindNetwork result: $result');
      return result;
    } on PlatformException catch (e) {
      print('❌ Failed to bind to network: ${e.message}');
      return false;
    }
  }

  Future<void> _configureSmartPlug(
    WiFiAccessPoint plugAccessPoint,
    String homeWifiSsid,
    String homeWifiPassword,
    BuildContext context,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final encodedSsid = Uri.encodeComponent(homeWifiSsid);
      final encodedPassword = Uri.encodeComponent(homeWifiPassword);

      final wifiCredsUrl =
          'http://192.168.4.1/wi?s1=$encodedSsid&p1=$encodedPassword&save';

      final response = await http.get(Uri.parse(wifiCredsUrl)).timeout(
            const Duration(seconds: 5),
          );

      if (response.statusCode != 200) {
        Navigator.of(context).pop();
        _showErrorDialog("WiFi Configuration Failed",
            "Plug returned status code ${response.statusCode}.");
        return;
      }

      // Give time for plug to connect to home WiFi
      await Future.delayed(const Duration(seconds: 10));

// ORIG CODE --------------------------------------------------------
/*
      final statusResp = await http
          .get(Uri.parse('http://192.168.4.1/cm?cmnd=STATUS%200'))
          .timeout(const Duration(seconds: 5));

      final newIpMatch =
          RegExp(r'"IPAddress":"([\d.]+)"').firstMatch(statusResp.body);

      if (newIpMatch == null) {
        Navigator.of(context).pop();
        _showErrorDialog("IP Not Found",
            "Could not determine plug's new IP. Try again or check your router.");
        return;
      }

      final newIp = newIpMatch.group(1)!;
*/

/*   // THIS ONE WORKS!! -----------------------------------------------
      String? newIp;
      for (var i = 0; i < 10; i++) {
        try {
          print("Attempting to fetch new IP...");
          final statusResp = await http
              .get(Uri.parse('http://192.168.4.1/cm?cmnd=STATUS%200'))
              .timeout(const Duration(seconds: 5));

          final match =
              RegExp(r'"IPAddress":"([\d.]+)"').firstMatch(statusResp.body);
          if (match != null) {
            newIp = match.group(1);
            break;
          }
        } catch (_) {}
        await Future.delayed(const Duration(seconds: 3));
      }

      if (newIp == null) {
        Navigator.of(context).pop();
        _showErrorDialog("IP Not Found",
            "Could not determine plug's new IP after multiple attempts. Try again or check your router.");
        return;
      }

      print("Detected Plug IP: $newIp");

      */ //------------------------------------------------------------------

      String? newIp;

    // First try up to 10 times with direct AP mode fetch
      for (var i = 0; i < 10; i++) {
        try {
          print("Attempting to fetch new IP from 192.168.4.1...");
          final statusResp = await http
              .get(Uri.parse('http://192.168.4.1/cm?cmnd=STATUS%200'))
              .timeout(const Duration(seconds: 5));

          final match =
              RegExp(r'"IPAddress":"([\d.]+)"').firstMatch(statusResp.body);
          final ip = match?.group(1);

          if (ip != null && ip != '0.0.0.0') {
            newIp = ip;
            break;
          } else {
            print("⚠️ Got invalid IP: $ip");
          }
        } catch (_) {
          print(
              "Plug is out of AP mode or unreachable, trying to scan the subnet...");
        }

        await Future.delayed(const Duration(seconds: 3));
      }
      print("Direct fetch attempts completed.");

      // If AP mode IP failed, try scanning subnet for Tasmota
      if (newIp == null) {
        print("Direct fetch failed. Scanning subnet...");
        newIp = await scanForTasmotaDevice();
      }

      if (newIp == null) {
        Navigator.of(context).pop();
        _showErrorDialog("IP Not Found",
            "Could not determine plug's new IP after retries and subnet scan. Try again or check your router.");
        return;
      }

      print("Detected Plug IP: $newIp");

      final mqttHost = dotenv.env['MQTT_HOST'] ?? '';
      final mqttUser = dotenv.env['MQTT_USER'] ?? '';
      final mqttPassword = dotenv.env['MQTT_PASSWORD'] ?? '';

      if ([mqttHost, mqttUser, mqttPassword].any((v) => v.isEmpty)) {
        Navigator.of(context).pop();
        _showErrorDialog(
          "Missing MQTT Config",
          "Check your .env file for MQTT_HOST, USER, PASSWORD.",
        );
        return;
      }

      final mqttUrl =
          'http://$newIp/cm?cmnd=Backlog%20MqttHost%20${Uri.encodeComponent(mqttHost)}%3BMqttPort%201883%3BMqttUser%20${Uri.encodeComponent(mqttUser)}%3BMqttPassword%20${Uri.encodeComponent(mqttPassword)}%3BRestart%201';

      final mqttResp = await http.get(Uri.parse(mqttUrl)).timeout(
            const Duration(seconds: 5),
          );

      Navigator.of(context).pop();

      if (mqttResp.statusCode == 200) {
        _showSuccessDialog("Plug Configured",
            "The plug has been connected to WiFi and MQTT.\nNew IP: $newIp");

        try {
          print("wait to connect to home wifi...");
          await waitForInternetConnection();

          print(
              "Connected to home WiFi. Attempting to bind to the main WiFi network before making the registration request...");
          // Bind to the main WiFi network before making the registration request
          final bindSuccess = await bindToWifiNetwork(internetRequired: true);
          print("Network binding result: $bindSuccess");

          if (!bindSuccess) {
            print(
                "⚠️ Network binding failed, but continuing with registration attempt");
          }

          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString('userId');

          if (userId == null) {
            _showErrorDialog("Missing User ID",
                "You must be logged in to register the plug.");
            return;
          }

          final newPlugId = await retryRegisterPlug(newIp, userId);

          if (newPlugId != null) {
            _showSuccessDialog(
              "Plug Linked",
              "The smart plug has been successfully registered to your account.",
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => NamePlugPage(
                  plugId: newPlugId,
                  plugIp: newIp!,
                ),
              ),
            );
          } else {
            _showErrorDialog(
              "Registration Failed",
              "Could not register the plug with the server. Please try again later or check your internet connection.",
              onRetry: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                // Try binding to the network again before retrying
                await bindToWifiNetwork(internetRequired: true);

                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getString('userId');

                if (userId == null) {
                  _showErrorDialog("Missing User ID",
                      "You must be logged in to register the plug.");
                  return;
                }

                final retryPlugId = await retryRegisterPlug(newIp!, userId);

                Navigator.of(context).pop();

                if (retryPlugId != null) {
                  _showSuccessDialog(
                    "Plug Linked",
                    "The smart plug has been successfully registered to your account.",
                  );
                } else {
                  _showErrorDialog(
                    "Registration Failed Again",
                    "Could not register the plug with the server. Please check your network connection and try again later.",
                  );
                }
              },
            );
          }
        } catch (e) {
          _showErrorDialog(
            "Network Error",
            "Failed to connect to the internet after plug configuration: $e",
            onRetry: () async {
              try {
                await waitForInternetConnection();

                // Try binding to the network before retrying registration
                await bindToWifiNetwork(internetRequired: true);

                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getString('userId');

                if (userId == null) {
                  _showErrorDialog("Missing User ID",
                      "You must be logged in to register the plug.");
                  return;
                }

                final retryPlugId = await retryRegisterPlug(newIp!, userId);

                if (retryPlugId != null) {
                  _showSuccessDialog(
                    "Plug Linked",
                    "The smart plug has been successfully registered to your account.",
                  );
                } else {
                  _showErrorDialog(
                    "Registration Failed",
                    "Could not register the plug with the server after retrying.",
                  );
                }
              } catch (e) {
                _showErrorDialog(
                  "Network Error",
                  "Failed to connect to the internet after retrying: $e",
                );
              }
            },
          );
        }
      } else {
        _showErrorDialog("MQTT Config Failed",
            "Failed to configure MQTT. Status ${mqttResp.statusCode}.");
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog("Configuration Error", "Error: $e");
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Try Again'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
