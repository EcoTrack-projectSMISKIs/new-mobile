import 'package:ecotrack_mobile/features/add_smartplug/name_plug.dart';
import 'package:ecotrack_mobile/widgets/navbar.dart';
import 'package:ecotrack_mobile/features/add_smartplug/smartplug_connection_controller.dart';
import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WiFiConnectionScreen extends StatefulWidget {
  final WiFiAccessPoint plugAccessPoint;
  
  const WiFiConnectionScreen({Key? key, required this.plugAccessPoint})
      : super(key: key);


  @override
  _WiFiConnectionScreenState createState() => _WiFiConnectionScreenState();
}

class _WiFiConnectionScreenState extends State<WiFiConnectionScreen> {
  String? selectedNetwork;
  bool isRefreshing = false;
  bool isConnecting = false;
  
  List<WiFiAccessPoint> availableNetworks = [];
  late PlugConfigurationController _controller;

@override
void initState() {
  super.initState();

  _initializeController();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadInitialNetworks(); 
  });
}


  void _initializeController() {
    _controller = PlugConfigurationController(
      onSuccess: (message) {
        _hideLoadingDialog();
        _showSuccessDialog('Success', message, '', '');
      },
      onError: (title, message, {onRetry}) {
        _hideLoadingDialog();
        _showErrorDialog(title, message, onRetry: onRetry);
      },
      onLoading: (message) {
        _showLoadingDialog(message);
      },
      onLoadingDismiss: () {
        _hideLoadingDialog();
      },
    );
  }

  Future<void> _loadInitialNetworks() async {
    await _refreshNetworks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3EBFF),
      body: SafeArea(
        child: Column(
          children: [
            // Top section with back button
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF109717),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      
                      // Wi-Fi info card
                      _buildWiFiInfoCard(),
                      
                      SizedBox(height: 28),
                      
                      // Available networks section
                      _buildNetworksSection(),
                      
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        bottom: false,
        child: CustomBottomNavBar(selectedIndex: 2),
      ),
    );
  }

  Widget _buildWiFiInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Wi-Fi icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Color(0xFF109717),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.wifi,
              color: Colors.white,
              size: 50,
            ),
          ),
          
          SizedBox(height: 15),
          
          // Title
          Text(
            'Wi-Fi',
            style: TextStyle(
              fontSize: 24,
              fontFamily: "Gotham",
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          
          SizedBox(height: 5),
          
          // Description
          Text(
            'Connect to your smart plug via Wi-Fi, below is the credentials for device connection.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontFamily: "Gotham",
              fontWeight: FontWeight.w400,
              color: const Color(0xFF141414),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with "AVAILABLE NETWORKS" and refresh button
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AVAILABLE NETWORKS',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: "Gotham",
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF918F8F),
                  letterSpacing: 0.5,
                ),
              ),
              // Refresh button
              GestureDetector(
                onTap: isRefreshing ? null : _refreshNetworks,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isRefreshing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF109717),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.refresh,
                          color: Color(0xFF109717),
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ),
        
        // Networks list card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(15),
            child: availableNetworks.isEmpty
                ? _buildEmptyNetworksState()
                : Column(
                    children: [
                      for (int i = 0; i < availableNetworks.length; i++) ...[
                        _buildNetworkItem(availableNetworks[i]),
                        if (i < availableNetworks.length - 1)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              color: Colors.grey[200],
                              thickness: 1,
                              height: 1,
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyNetworksState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.grey[400],
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'No networks found',
            style: TextStyle(
              fontSize: 16,
              fontFamily: "Gotham",
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Pull down to refresh or check your WiFi',
            style: TextStyle(
              fontSize: 12,
              fontFamily: "Gotham",
              fontWeight: FontWeight.w400,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshNetworks() async {
    if (isRefreshing) return;
    
    setState(() {
      isRefreshing = true;
    });

    try {
      // Show scanning message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Scanning for WiFi networks...'),
            ],
          ),
          backgroundColor: Color(0xFF109717),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Use the controller to scan for networks
      final networks = await _controller.scanHomeNetworks();
      
      setState(() {
        availableNetworks = networks;
        isRefreshing = false;
      });

      // Show completion message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            availableNetworks.isEmpty
                ? 'No WiFi networks found'
                : '${availableNetworks.length} WiFi networks found',
          ),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        isRefreshing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning networks: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Widget _buildNetworkItem(WiFiAccessPoint network) {
    bool isSelected = selectedNetwork == network.ssid;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedNetwork = network.ssid;
        });
        
        _showPasswordDialog(network);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            // Wi-Fi signal icon with strength
            Icon(
              _getSignalIcon(network.level),
              color: _getSignalColor(network.level),
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    network.ssid,
                    style: TextStyle(
                      fontSize: 17,
                      fontFamily: "Gotham",
                      fontWeight: FontWeight.w400,
                      color: isSelected ? Color(0xFF109717) : Colors.black87,
                    ),
                  ),
                  if (network.capabilities.isNotEmpty)
                    Text(
                      network.capabilities,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: "Gotham",
                        fontWeight: FontWeight.w300,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${network.level} dBm',
              style: TextStyle(
                fontSize: 12,
                fontFamily: "Gotham",
                fontWeight: FontWeight.w300,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(width: 8),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getSignalIcon(int level) {
    if (level >= -50) return Icons.wifi;
    if (level >= -60) return Icons.wifi_2_bar;
    if (level >= -70) return Icons.wifi_1_bar;
    return Icons.wifi_off;
  }

  Color _getSignalColor(int level) {
    if (level >= -50) return Colors.green;
    if (level >= -60) return Colors.orange;
    if (level >= -70) return Colors.red;
    return Colors.grey;
  }

  void _showPasswordDialog(WiFiAccessPoint network) {
    TextEditingController passwordController = TextEditingController();
    bool isPasswordVisible = false;
    bool isJoining = false; // Added loading state for join button
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          SizedBox(height: 25),
                          
                          // Title
                          Text(
                            'Enter Password for "${network.ssid}"',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              fontFamily: "Gotham",
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: 15),
                          
                          // Header row with Cancel, Title, Join
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: isJoining ? null : () => Navigator.pop(context), // Disable when joining
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: isJoining ? Colors.grey : Color(0xFF4B3FF2),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: "Gotham",
                                  ),
                                ),
                              ),
                              Text(
                                'Enter Password',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  fontFamily: "Gotham",
                                ),
                              ),
                              // Modified Join button with loading
                              Container(
                                child: isJoining
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4B3FF2)),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Joining...',
                                            style: TextStyle(
                                              color: Color(0xFF4B3FF2),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: "Gotham",
                                            ),
                                          ),
                                        ],
                                      )
                                    : TextButton(
                                        onPressed: passwordController.text.isNotEmpty 
                                          ? () async {
                                              setStateDialog(() {
                                                isJoining = true; // Start loading
                                              });
                                              
                                              Navigator.pop(context);
                                              await _connectToNetwork(network, passwordController.text);
                                            }
                                          : null,
                                        child: Text(
                                          'Join',
                                          style: TextStyle(
                                            color: passwordController.text.isNotEmpty 
                                              ? Color(0xFF4B3FF2) 
                                              : Colors.grey,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: "Gotham",
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 10),
                          
                          // Password input field
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[600],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: passwordController,
                                    enabled: !isJoining, // Disable when joining
                                    obscureText: !isPasswordVisible,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '••••••••••',
                                      hintStyle: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setStateDialog(() {});
                                    },
                                  ),
                                ),
                                GestureDetector(
                                  onTap: isJoining ? null : () { // Disable when joining
                                    setStateDialog(() {
                                      isPasswordVisible = !isPasswordVisible;
                                    });
                                  },
                                  child: Icon(
                                    isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                    color: isJoining ? Colors.white38 : Colors.white70, // Change opacity when joining
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          Spacer(),
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

  Future<void> _connectToNetwork(WiFiAccessPoint network, String password) async {
    if (isConnecting) return;
    
    setState(() {
      isConnecting = true;
    });

    try {
      // Show loading dialog immediately after dialog closes
      _showLoadingDialog('Connecting to ${network.ssid}...');
      
      // Use the controller to configure the smart plug
      final result = await _controller.configureSmartPlug(
        plugAccessPoint: widget.plugAccessPoint,
        homeWifiSsid: network.ssid,
        homeWifiPassword: password,
      );

      setState(() {
        isConnecting = false;
      });

      _hideLoadingDialog(); // Hide loading dialog

      if (result.success) {
        _showSuccessDialog(result.title, result.message, result.plugId!, result.plugIp!);
      } else {
        if (result.canRetry && result.retryData != null) {
          _showErrorDialog(
            result.title, 
            result.message,
            onRetry: () => _retryConfiguration(result.retryData!['plugIp']),
          );
        } else {
          _showErrorDialog(result.title, result.message);
        }
      }
    } catch (e) {
      setState(() {
        isConnecting = false;
      });
      
      _hideLoadingDialog(); // Hide loading dialog on error
      
      _showErrorDialog(
        'Configuration Error',
        'Failed to configure smart plug: $e',
      );
    }
  }

  Future<void> _retryConfiguration(String plugIp) async {
    try {
      final result = await _controller.retryRegistration(plugIp);
      
      if (result.success) {
        _showSuccessDialog(result.title, result.message, result.plugId!, result.plugIp!);
      } else {
        _showErrorDialog(result.title, result.message);
      }
    } catch (e) {
      _showErrorDialog(
        'Retry Failed',
        'Failed to retry configuration: $e',
      );
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
              SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Gotham",
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

void _showSuccessDialog(String title, String message, String newPlugId, String plugIp) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: "Gotham",
            fontWeight: FontWeight.w600,
            color: Color(0xFF4CAF50),
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontFamily: "Gotham",
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontFamily: "Gotham",
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  ).then((_) {
    // Navigate after the dialog is closed
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NamePlugPage(
          plugId: newPlugId,  // This will have the correct value
          plugIp: plugIp,  
        ),
      ),
    );
  });
}


  void _showErrorDialog(String title, String message, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontFamily: "Gotham",
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: "Gotham",
              fontSize: 14,
            ),
          ),
          actions: [
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onRetry();
                },
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: Color(0xFF4B3FF2),
                    fontFamily: "Gotham",
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                onRetry != null ? 'Cancel' : 'OK',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: "Gotham",
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}