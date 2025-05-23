import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:ecotrack_mobile/features/add_smartplug/scan_tasmota_ip_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

class PlugConfigurationController {
  final List<String> _PLUG_AP_SSIDS = ['ecotrack-plug', 'tasmota'];
  
  // Callbacks for UI updates
  Function(String message)? onSuccess;
  Function(String title, String message, {VoidCallback? onRetry})? onError;
  Function(String message)? onLoading;
  Function()? onLoadingDismiss;

  PlugConfigurationController({
    this.onSuccess,
    this.onError,
    this.onLoading,
    this.onLoadingDismiss,
  });

  Future<List<WiFiAccessPoint>> scanHomeNetworks() async {
    try {
      await WiFiScan.instance.startScan();
      List<WiFiAccessPoint> networks = await WiFiScan.instance.getScannedResults();
      
      // Filter out plug AP SSIDs
      networks = networks
          .where((network) => !_PLUG_AP_SSIDS.any((plugSsid) =>
              network.ssid.toLowerCase().contains(plugSsid.toLowerCase())))
          .toList();
      
      return networks;
    } catch (e) {
      print('Error scanning home networks: $e');
      return [];
    }
  }

  Future<void> waitForInternetConnection() async {
    const timeout = Duration(seconds: 60);
    const pollInterval = Duration(seconds: 2);
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      final result = await Connectivity().checkConnectivity();
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        try {
          final lookup = await InternetAddress.lookup('google.com');
          if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
            print("✅ Internet connection detected.");
            return;
          }
        } catch (_) {
          // Device is connected to WiFi/Mobile but has no internet yet
        }
      }
      await Future.delayed(pollInterval);
    }
    throw TimeoutException("No internet connection after plug configuration.");
  }

  Future<String?> retryRegisterPlug(String newIp, String userId, {int retries = 5}) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        print("🔄 Attempt ${attempt + 1} to register plug...");
        await Future.delayed(Duration(seconds: 5 + attempt * 2));

        final plugId = await registerPlugToUser(newIp, userId);

        if (plugId != null) {
          print("✅ Plug successfully registered on attempt ${attempt + 1}");
          return plugId;
        } else {
          print("⚠️ Attempt ${attempt + 1} failed but no exception was thrown.");
        }
      } catch (e) {
        print("⚠️ Attempt ${attempt + 1} threw an exception: $e");
      }

      if (attempt < retries - 1) {
        print("🔁 Retrying registerPlugToUser in ${5 + attempt * 2} seconds...");
      } else {
        print("❌ All retry attempts failed.");
      }
    }
    return null;
  }

  Future<bool> waitForDnsReady(String host, {int retries = 5, Duration delay = const Duration(seconds: 2)}) async {
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

  Future<String?> getPlugNewIp() async {
    String? newIp;

    // First try up to 10 times with direct AP mode fetch
    for (var i = 0; i < 10; i++) {
      try {
        print("Attempting to fetch new IP from 192.168.4.1...");
        final statusResp = await http
            .get(Uri.parse('http://192.168.4.1/cm?cmnd=STATUS%200'))
            .timeout(const Duration(seconds: 5));

        final match = RegExp(r'"IPAddress":"([\d.]+)"').firstMatch(statusResp.body);
        final ip = match?.group(1);

        if (ip != null && ip != '0.0.0.0') {
          newIp = ip;
          break;
        } else {
          print("⚠️ Got invalid IP: $ip");
        }
      } catch (_) {
        print("Plug is out of AP mode or unreachable, trying to scan the subnet...");
      }

      await Future.delayed(const Duration(seconds: 3));
    }
    print("Direct fetch attempts completed.");

    // If AP mode IP failed, try scanning subnet for Tasmota
    if (newIp == null) {
      print("Direct fetch failed. Scanning subnet...");
      newIp = await scanForTasmotaDevice();
    }

    return newIp;
  }

  Future<ConfigurationResult> configureSmartPlug({
    required WiFiAccessPoint plugAccessPoint,
    required String homeWifiSsid,
    required String homeWifiPassword,
  }) async {
    try {
      onLoading?.call("Configuring plug...");

      final encodedSsid = Uri.encodeComponent(homeWifiSsid);
      final encodedPassword = Uri.encodeComponent(homeWifiPassword);

      final wifiCredsUrl = 'http://192.168.4.1/wi?s1=$encodedSsid&p1=$encodedPassword&save';

      final response = await http.get(Uri.parse(wifiCredsUrl)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode != 200) {
        onLoadingDismiss?.call();
        return ConfigurationResult.error(
          "WiFi Configuration Failed",
          "Plug returned status code ${response.statusCode}.",
        );
      }

      // Give time for plug to connect to home WiFi
      await Future.delayed(const Duration(seconds: 10));

      final newIp = await getPlugNewIp();

      if (newIp == null) {
        onLoadingDismiss?.call();
        return ConfigurationResult.error(
          "IP Not Found",
          "Could not determine plug's new IP after retries and subnet scan. Try again or check your router.",
        );
      }

      print("Detected Plug IP: $newIp");

      final mqttConfigResult = await configureMqtt(newIp);
      if (!mqttConfigResult.success) {
        onLoadingDismiss?.call();
        return mqttConfigResult;
      }

      onLoadingDismiss?.call();

      // Now handle registration
      return await registerPlugWithRetry(newIp);

    } catch (e) {
      onLoadingDismiss?.call();
      return ConfigurationResult.error("Configuration Error", "Error: $e");
    }
  }

  Future<ConfigurationResult> configureMqtt(String plugIp) async {
    final mqttHost = dotenv.env['MQTT_HOST'] ?? '';
    final mqttUser = dotenv.env['MQTT_USER'] ?? '';
    final mqttPassword = dotenv.env['MQTT_PASSWORD'] ?? '';

    if ([mqttHost, mqttUser, mqttPassword].any((v) => v.isEmpty)) {
      return ConfigurationResult.error(
        "Missing MQTT Config",
        "Check your .env file for MQTT_HOST, USER, PASSWORD.",
      );
    }

    final mqttUrl = 'http://$plugIp/cm?cmnd=Backlog%20MqttHost%20${Uri.encodeComponent(mqttHost)}%3BMqttPort%201883%3BMqttUser%20${Uri.encodeComponent(mqttUser)}%3BMqttPassword%20${Uri.encodeComponent(mqttPassword)}%3BRestart%201';

    try {
      final mqttResp = await http.get(Uri.parse(mqttUrl)).timeout(
        const Duration(seconds: 5),
      );

      if (mqttResp.statusCode == 200) {
        return ConfigurationResult.success(
          "Plug Configured",
          "The plug has been connected to WiFi and MQTT.\nNew IP: $plugIp",
          data: {'plugIp': plugIp},
        );
      } else {
        return ConfigurationResult.error(
          "MQTT Config Failed",
          "Failed to configure MQTT. Status ${mqttResp.statusCode}.",
        );
      }
    } catch (e) {
      return ConfigurationResult.error(
        "MQTT Config Error",
        "Error configuring MQTT: $e",
      );
    }
  }

  Future<ConfigurationResult> registerPlugWithRetry(String plugIp) async {
    try {
      print("wait to connect to home wifi...");
      await waitForInternetConnection();

      print("Connected to home WiFi. Attempting to bind to the main WiFi network before making the registration request...");
      final bindSuccess = await bindToWifiNetwork(internetRequired: true);
      print("Network binding result: $bindSuccess");

      if (!bindSuccess) {
        print("⚠️ Network binding failed, but continuing with registration attempt");
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        return ConfigurationResult.error(
          "Missing User ID",
          "You must be logged in to register the plug.",
        );
      }

      final newPlugId = await retryRegisterPlug(plugIp, userId);

      if (newPlugId != null) {
        return ConfigurationResult.success(
          "Plug Linked",
          "The smart plug has been successfully registered to your account.",
          data: {'plugId': newPlugId, 'plugIp': plugIp},
        );
      } else {
        return ConfigurationResult.error(
          "Registration Failed",
          "Could not register the plug with the server. Please try again later or check your internet connection.",
          canRetry: true,
          retryData: {'plugIp': plugIp},
        );
      }
    } catch (e) {
      return ConfigurationResult.error(
        "Network Error",
        "Failed to connect to the internet after plug configuration: $e",
        canRetry: true,
        retryData: {'plugIp': plugIp},
      );
    }
  }

  Future<ConfigurationResult> retryRegistration(String plugIp) async {
    try {
      await waitForInternetConnection();
      await bindToWifiNetwork(internetRequired: true);

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        return ConfigurationResult.error(
          "Missing User ID",
          "You must be logged in to register the plug.",
        );
      }

      final retryPlugId = await retryRegisterPlug(plugIp, userId);

      if (retryPlugId != null) {
        return ConfigurationResult.success(
          "Plug Linked",
          "The smart plug has been successfully registered to your account.",
          data: {'plugId': retryPlugId, 'plugIp': plugIp},
        );
      } else {
        return ConfigurationResult.error(
          "Registration Failed Again",
          "Could not register the plug with the server. Please check your network connection and try again later.",
        );
      }
    } catch (e) {
      return ConfigurationResult.error(
        "Network Error",
        "Failed to connect to the internet after retrying: $e",
      );
    }
  }
}

class ConfigurationResult {
  final bool success;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool canRetry;
  final Map<String, dynamic>? retryData;

  ConfigurationResult._({
    required this.success,
    required this.title,
    required this.message,
    this.data,
    this.canRetry = false,
    this.retryData,
  });

  String? get plugId => data?['plugId'] as String?;
  String? get plugIp => data?['plugIp'] as String?;

  factory ConfigurationResult.success(String title, String message, {Map<String, dynamic>? data}) {
    return ConfigurationResult._(
      success: true,
      title: title,
      message: message,
      data: data,
    );
  }
  factory ConfigurationResult.error(String title, String message, {bool canRetry = false, Map<String, dynamic>? retryData}) {
    return ConfigurationResult._(
      success: false,
      title: title,
      message: message,
      canRetry: canRetry,
      retryData: retryData,
    );
  }
}