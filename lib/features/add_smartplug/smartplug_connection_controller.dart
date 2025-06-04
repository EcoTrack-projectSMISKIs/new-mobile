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
      List<WiFiAccessPoint> networks =
          await WiFiScan.instance.getScannedResults();

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

  Future<bool> unbindNetwork() async {
    const platform = MethodChannel('com.example.network/bind');
    try {
      final bool result = await platform.invokeMethod('unbindNetwork');
      print('🔄 unbindNetwork result: $result');
      return result;
    } on PlatformException catch (e) {
      print('❌ Failed to unbind network: ${e.message}');
      return false;
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

    final wifiCredsUrl =
        'http://192.168.4.1/wi?s1=$encodedSsid&p1=$encodedPassword&save';

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

    // Configure the template first
    final templateResult = await configureTemplate(newIp);
    if (!templateResult.success) {
      onLoadingDismiss?.call();
      return templateResult;
    }

    // Short delay to let the plug settle after template/module change
    // await Future.delayed(const Duration(seconds: 3));

    // Moved MQTT configuration here at naming plug stage
    // // Then configure MQTT
    // final mqttConfigResult = await configureMqtt(newIp);
    // if (!mqttConfigResult.success) {
    //   onLoadingDismiss?.call();
    //   return mqttConfigResult;
    // }

    //onLoadingDismiss?.call();
    onLoading?.call("Registering plug...");

    // Now handle registration
    return await registerPlugWithRetry(newIp);
  } catch (e) {
    onLoadingDismiss?.call();
    return ConfigurationResult.error("Configuration Error", "Error: $e");
  }
}


  Future<ConfigurationResult> configureTemplate(String plugIp) async {
  // Template string must be URI-encoded
  const templateJson = '{"NAME":"Athom Plug V2","GPIO":[0,0,0,3104,0,32,0,0,224,576,0,0,0,0],"FLAG":0,"BASE":18}';
  final encodedTemplate = Uri.encodeComponent(templateJson);

  final templateUrl = 'http://$plugIp/cm?cmnd=Template%20$encodedTemplate';
  final moduleUrl = 'http://$plugIp/cm?cmnd=Module%200';

  try {
    // Send the Template command
    final templateResp = await http.get(Uri.parse(templateUrl)).timeout(
          const Duration(seconds: 5),
        );

    if (templateResp.statusCode != 200) {
      return ConfigurationResult.error(
        "Template Config Failed",
        "Failed to send template. Status ${templateResp.statusCode}.",
      );
    }

    // Send the Module 0 command
    final moduleResp = await http.get(Uri.parse(moduleUrl)).timeout(
          const Duration(seconds: 5),
        );

    if (moduleResp.statusCode != 200) {
      return ConfigurationResult.error(
        "Module Config Failed",
        "Failed to set module to 0. Status ${moduleResp.statusCode}.",
      );
    }

    return ConfigurationResult.success(
      "Template Applied",
      "The Tasmota template and module were successfully configured.",
    );
  } catch (e) {
    return ConfigurationResult.error(
      "Template Config Error",
      "Error applying template: $e",
    );
  }
}

// Moved MQTT configuration at name_plug.dart

  // Future<ConfigurationResult> configureMqtt(String plugIp) async {
  //   final mqttHost = dotenv.env['MQTT_HOST'] ?? '';
  //   final mqttUser = dotenv.env['MQTT_USER'] ?? '';
  //   final mqttPassword = dotenv.env['MQTT_PASSWORD'] ?? '';

  //   if ([mqttHost, mqttUser, mqttPassword].any((v) => v.isEmpty)) {
  //     return ConfigurationResult.error(
  //       "Missing MQTT Config",
  //       "Check your .env file for MQTT_HOST, USER, PASSWORD.",
  //     );
  //   }

  //   final mqttUrl =
  //       'http://$plugIp/cm?cmnd=Backlog%20MqttHost%20${Uri.encodeComponent(mqttHost)}%3BMqttPort%201883%3BMqttUser%20${Uri.encodeComponent(mqttUser)}%3BMqttPassword%20${Uri.encodeComponent(mqttPassword)}%3BRestart%201';

  //   try {
  //     final mqttResp = await http.get(Uri.parse(mqttUrl)).timeout(
  //           const Duration(seconds: 5),
  //         );

  //     if (mqttResp.statusCode == 200) {
  //       return ConfigurationResult.success(
  //         "Plug Configured",
  //         "The plug has been connected to WiFi and MQTT.\nNew IP: $plugIp",
  //         data: {'plugIp': plugIp},
  //       );
  //     } else {
  //       return ConfigurationResult.error(
  //         "MQTT Config Failed",
  //         "Failed to configure MQTT. Status ${mqttResp.statusCode}.",
  //       );
  //     }
  //   } catch (e) {
  //     return ConfigurationResult.error(
  //       "MQTT Config Error",
  //       "Error configuring MQTT: $e",
  //     );
  //   }
  // }

  Future<ConfigurationResult> registerPlugWithRetry(String plugIp) async {
  try {
    await Future.delayed(Duration(seconds: 8));
    // Step 1: Unbind from plug's AP network (192.168.4.1) to allow connection to home WiFi
   await unbindNetwork();
   print("Unbound from plug's AP network. Waiting to connect to home WiFi...");

    // Step 2: Wait until device has internet (connected to home WiFi)
    await waitForInternetConnection();

    print("Connected to home WiFi. Attempting to bind to main WiFi network with internet...");

    // Step 3: Bind network to WiFi with internet capability before registration
    final bindSuccess = await bindToWifiNetwork(internetRequired: true);
    print("Network binding result: $bindSuccess");

    if (!bindSuccess) {
      print("⚠️ Warning: Network binding failed, but continuing with registration.");
    }

    // Step 4: Get userId from preferences for registering the plug
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      return ConfigurationResult.error(
        "Missing User ID",
        "You must be logged in to register the plug.",
      );
    }

    // Step 5: Attempt to register the plug with retry logic
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
    // Catch any network or unexpected errors
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

  factory ConfigurationResult.success(String title, String message,
      {Map<String, dynamic>? data}) {
    return ConfigurationResult._(
      success: true,
      title: title,
      message: message,
      data: data,
    );
  }
  factory ConfigurationResult.error(String title, String message,
      {bool canRetry = false, Map<String, dynamic>? retryData}) {
    return ConfigurationResult._(
      success: false,
      title: title,
      message: message,
      canRetry: canRetry,
      retryData: retryData,
    );
  }
}
