import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:ecotrack_mobile/widgets/navbar.dart';
import 'package:ecotrack_mobile/features/add_smartplug/smartplug_connection_controller.dart';
import 'package:ecotrack_mobile/features/add_smartplug/select_home_wifi.dart';

class SelectSmartPlugsScreen extends StatefulWidget {
  @override
  _SelectSmartPlugsScreenState createState() => _SelectSmartPlugsScreenState();
}

class _SelectSmartPlugsScreenState extends State<SelectSmartPlugsScreen>
    with TickerProviderStateMixin {
  static const List<String> _PLUG_AP_SSIDS = ['tasmota', 'ecotrack-plug'];
  List<WiFiAccessPoint> _accessPoints = <WiFiAccessPoint>[];
  late AnimationController _scanAnimationController;
  bool isScanning = false;
  bool _hasScannedOnce = false;

  @override
  void initState() {
    super.initState();
    _scanAnimationController =
        AnimationController(vsync: this, duration: Duration(seconds: 2));
    _checkWiFiScanCapabilities();
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkWiFiScanCapabilities() async {
    await [Permission.location, Permission.nearbyWifiDevices].request();
    final canStartScan = await WiFiScan.instance.canStartScan();
    final canGetResults = await WiFiScan.instance.canGetScannedResults();
    if (canStartScan != CanStartScan.yes ||
        canGetResults != CanGetScannedResults.yes) {
      _showErrorDialog(
          "WiFi Scanning Unavailable", "Check location and WiFi permissions.");
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(title: Text(title), content: Text(message), actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("OK")),
      ]),
    );
  }

  void _startScanning() async {
    setState(() {
      isScanning = true;
      _hasScannedOnce = true;
      print("Scanning for smart plugs...");
    });
    _scanAnimationController.repeat();

    // Start the minimum 3-second timer
    final minimumLoadingTime = Future.delayed(Duration(seconds: 3));
    
    try {
      // Start the actual WiFi scan
      final scanFuture = _performWiFiScan();
      
      // Wait for both the minimum loading time AND the scan to complete
      await Future.wait([minimumLoadingTime, scanFuture]);
      
    } catch (e) {
      print("Scan error: $e");
      // Still wait for the minimum time even if there's an error
      await minimumLoadingTime;
    } finally {
      _scanAnimationController.stop();
      setState(() => isScanning = false);
    }
  }

  Future<void> _performWiFiScan() async {
    await WiFiScan.instance.startScan();
    final results = await WiFiScan.instance.getScannedResults();
    setState(() {
      _accessPoints = results
          .where((ap) => _PLUG_AP_SSIDS
              .any((s) => ap.ssid.toLowerCase().contains(s.toLowerCase())))
          .toList();
    });
  }

  Future<bool> bindToWiFiNetwork({required bool internetRequired}) async {
    const platform = MethodChannel('com.example.network/bind');
    try {
      final result = await platform.invokeMethod('bindNetwork', {
        'internetRequired': internetRequired,
      });
      return result == true;
    } catch (e) {
      debugPrint('Failed to bind network: $e');
      return false;
    }
  }

  Future<void> _connectToPlugAndOpenConfig(
      WiFiAccessPoint plugAccessPoint) async {
    final plugSSID = plugAccessPoint.ssid;

    final connected = await WiFiForIoTPlugin.connect(plugSSID,
        security: NetworkSecurity.NONE, joinOnce: true, withInternet: false);
    if (!connected)
      return _showErrorDialog(
          "Connection Failed", "Could not connect to $plugSSID");

    for (int i = 0; i < 10; i++) {
      final ssid = await WiFiForIoTPlugin.getSSID();
      if (ssid?.toLowerCase().contains(plugSSID.toLowerCase()) == true) {
        break;
      }
      await Future.delayed(Duration(seconds: 2));
    }

    if (!await bindToWiFiNetwork(internetRequired: false)) {
      return _showBrowserFallbackDialog(
          "Network Binding Failed", "Try opening 192.168.4.1 in your browser.");
    }

    try {
      final socket = await Socket.connect('192.168.4.1', 80,
          timeout: Duration(seconds: 5));
      socket.destroy();
      final response = await http.get(Uri.parse("http://192.168.4.1/"));
      if (response.statusCode == 200) {
        //Navigator.push(context, MaterialPageRoute(builder: (_) => PlugConnectedScreen(plugAccessPoint: plugAccessPoint)));
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    WiFiConnectionScreen(plugAccessPoint: plugAccessPoint)));
        // print("success");
      } else {
        _showBrowserFallbackDialog(
            "Plug Not Responding", "Open 192.168.4.1 in your browser?");
      }
    } catch (_) {
      _showBrowserFallbackDialog(
          "Plug Unreachable", "Open 192.168.4.1 in your browser?");
    }
  }

  void _showBrowserFallbackDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final url = Uri.parse('http://192.168.4.1/');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                _showErrorDialog("Launch Failed", "Could not open browser.");
              }
            },
            child: Text("Open in Browser"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE7F5E8),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: [
              SizedBox(height: 60),
              Text('Smart Plugs',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600)),
              SizedBox(height: 16),
              Text('Select your smart plug from the list below',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16, color: Colors.grey[600], height: 1.4)),
              SizedBox(height: 40),
              Expanded(
                child: _accessPoints.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isScanning)
                              RotationTransition(
                                turns: _scanAnimationController,
                                child: Container(
                                    width: 40,
                                    height: 40,
                                    child:
                                        CustomPaint(painter: LoadingPainter())),
                              )
                            else
                              Container(
                                padding: EdgeInsets.all(28),
                                width: 330,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(height: 10),
                                    Image.asset('assets/icons/no_smartplug.png',
                                        width: 140, height: 140),
                                    SizedBox(height: 16),
                                    Text(
                                      _accessPoints.isEmpty && !_hasScannedOnce
                                          ? 'Ready to scan'
                                          : 'No smart plug networks found',
                                      style: TextStyle(fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _accessPoints.length,
                        itemBuilder: (context, index) {
                          final ap = _accessPoints[index];
                          return GestureDetector(
                            onTap: () => _connectToPlugAndOpenConfig(ap),
                            child: _buildDeviceCard(ap.ssid, ap.level),
                          );
                        },
                      ),
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isScanning ? null : _startScanning,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Text(isScanning ? 'Scanning...' : 'Scan for Devices',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(selectedIndex: 2),
    );
  }

  Widget _buildDeviceCard(String deviceName, int signal) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.electrical_services,
              color: signal > -70
                  ? Colors.green
                  : signal > -80
                      ? Colors.orange
                      : Colors.red),
          SizedBox(width: 16),
          Expanded(
              child: Text(deviceName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class LoadingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    for (int i = 0; i < 8; i++) {
      final angle = i * 45 * (math.pi / 180);
      final x = center.dx + (radius - 7) * math.cos(angle);
      final y = center.dy + (radius - 7) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 3.0, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}