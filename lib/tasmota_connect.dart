import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:ecotrack_mobile/plug_connected.dart';
import 'package:flutter/services.dart';

// ADD SAVE PREVIOUS WIFI SSID AND PASSWORD TO THE DEVICE

class TasmotaSmartPlugConnector extends StatefulWidget {
  const TasmotaSmartPlugConnector({Key? key}) : super(key: key);

  @override
  _TasmotaSmartPlugConnectorState createState() =>
      _TasmotaSmartPlugConnectorState();
}

class _TasmotaSmartPlugConnectorState
    extends State<TasmotaSmartPlugConnector> {
  static const List<String> _PLUG_AP_SSIDS = ['tasmota', 'ecotrack-plug'];

  List<WiFiAccessPoint> _accessPoints = <WiFiAccessPoint>[];
  StreamSubscription<List<WiFiAccessPoint>>? _subscription;
  bool _isScanning = false;
  String _statusMessage = "Ready to scan smart plug networks";
  String? _connectingToSSID;

  @override
  void initState() {
    super.initState();
    _checkWiFiScanCapabilities();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkWiFiScanCapabilities() async {
    await [
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();

    final canStartScan = await WiFiScan.instance.canStartScan();
    final canGetResults = await WiFiScan.instance.canGetScannedResults();

    if (canStartScan != CanStartScan.yes ||
        canGetResults != CanGetScannedResults.yes) {
      _showErrorDialog("WiFi Scanning Unavailable",
          "Unable to scan for smart plug networks. Check your device's WiFi and location permissions.");
    }
  }

  void _showErrorDialog(String title, String message) {
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

  Future<void> _scanForSmartPlugs() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _statusMessage = "Scanning for smart plug networks...";
      _accessPoints = [];
    });

    try {
      await WiFiScan.instance.startScan();
      final results = await WiFiScan.instance.getScannedResults();

      setState(() {
        _accessPoints = results
            .where((ap) => _PLUG_AP_SSIDS.any((plugSsid) =>
                ap.ssid.toLowerCase().contains(plugSsid.toLowerCase())))
            .toList();

        _isScanning = false;
        _statusMessage = _accessPoints.isEmpty
            ? "No smart plug networks found"
            : "${_accessPoints.length} smart plug network(s) detected";
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = "Scan error: $e";
      });
    }
  }

Future<bool> bindToWiFiNetwork({required bool internetRequired}) async {
  const platform = MethodChannel('com.example.network/bind');
  try {
    // Pass whether internet is required or not
    final result = await platform.invokeMethod('bindNetwork', {
      'internetRequired': internetRequired,
    });
    print('✅ Bind result: $result');
    return result == true;
  } catch (e) {
    debugPrint('❌ Failed to bind network: $e');
    return false;
  }
}



 Future<void> _connectToPlugAndOpenConfig(
      WiFiAccessPoint plugAccessPoint) async {
    final plugSSID = plugAccessPoint.ssid;

    setState(() {
      _connectingToSSID = plugSSID;
      _statusMessage = "Connecting to $plugSSID...";
    });

    try {
      final connected = await WiFiForIoTPlugin.connect(
        plugSSID,
        security: NetworkSecurity.NONE,
        joinOnce: true,
        withInternet: false,
      );

      if (!connected) {
        setState(() {
          _statusMessage = "Failed to connect to $plugSSID.";
          _connectingToSSID = null;
        });
        return;
      }

      bool isConfirmed = false;
      for (int i = 0; i < 10; i++) {
        final currentSSID = await WiFiForIoTPlugin.getSSID();
        if (currentSSID != null &&
            currentSSID.toLowerCase().contains(plugSSID.toLowerCase())) {
          isConfirmed = true;
          debugPrint("✅ Connected to SSID: $currentSSID");
          break;
        }
        await Future.delayed(const Duration(seconds: 2));
      }

      if (!isConfirmed) {
        setState(() {
          _statusMessage = "Failed to confirm connection to $plugSSID.";
          _connectingToSSID = null;
        });
        return;
      }

      setState(() {
        _statusMessage = "Connected to $plugSSID. Binding to network...";
      });

      final bound = await bindToWiFiNetwork(internetRequired: false);
      if (!bound) {
        _showBrowserFallbackDialog(
          "Network Binding Failed",
          "Could not bind to the plug's network. Please try again or use your browser to access 192.168.4.1.",
        );
        return;
      }

      setState(() {
        _statusMessage = "Bound to $plugSSID. Checking connectivity...";
      });

      await Future.delayed(const Duration(seconds: 2));

      try {
        final socket = await Socket.connect('192.168.4.1', 80,
            timeout: const Duration(seconds: 5));
        debugPrint('✅ Plug socket reachable!');
        socket.destroy();

        final response = await http.get(Uri.parse("http://192.168.4.1/"));
        if (response.statusCode == 200) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PlugConnectedScreen(plugAccessPoint: plugAccessPoint),
            ),
          );
        } else {
          _showBrowserFallbackDialog(
            "Plug Not Responding",
            "192.168.4.1 returned code ${response.statusCode}. Open in browser?",
          );
        }
      } catch (e) {
        debugPrint('❌ Connection error: $e');
        _showBrowserFallbackDialog(
          "Plug Not Responding",
          "Could not connect to 192.168.4.1. Open in browser?",
        );
      }
    } catch (e) {
      _showErrorDialog("Connection Error", e.toString());
    } finally {
      setState(() {
        _connectingToSSID = null;
      });
    }
  }


  void _showBrowserFallbackDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final Uri plugUri = Uri.parse('http://192.168.4.1/');
              if (await canLaunchUrl(plugUri)) {
                await launchUrl(plugUri, mode: LaunchMode.externalApplication);
              } else {
                _showErrorDialog(
                    "Browser Launch Failed", "Could not open browser.");
              }
            },
            child: const Text('Open in Browser'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Plug Configurator'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: $_statusMessage',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scanning for: ${_PLUG_AP_SSIDS.join(", ")} networks',
                ),
              ],
            ),
          ),
          Expanded(
            child: _accessPoints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off,
                            size: 100, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _isScanning
                              ? 'Searching for smart plug networks...'
                              : 'No smart plug networks found',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _accessPoints.length,
                    itemBuilder: (context, index) {
                      final plugAp = _accessPoints[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: Icon(
                            Icons.electrical_services,
                            color: plugAp.level > -70
                                ? Colors.green
                                : plugAp.level > -80
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                          title: Text(plugAp.ssid),
                          subtitle: Text('Signal: ${plugAp.level} dBm'),
                          trailing: ElevatedButton(
                            onPressed: () => _connectToPlugAndOpenConfig(plugAp),
                            child: const Text('Connect'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : _scanForSmartPlugs,
        tooltip: 'Scan for Smart Plugs',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
