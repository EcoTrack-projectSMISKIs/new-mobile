/* // THIS FILE IS NOT USED IN THE APP

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PlugConnectedScreen extends StatefulWidget {
  final String plugIP;

  const PlugConnectedScreen({Key? key, required this.plugIP}) : super(key: key);

  @override
  _PlugConnectedScreenState createState() => _PlugConnectedScreenState();
}

class _PlugConnectedScreenState extends State<PlugConnectedScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize WebView and controller
    WebView.platform = SurfaceAndroidWebView(); // for Android
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _isLoading = progress < 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );
    _webViewController.loadRequest(Uri.parse('http://${widget.plugIP}'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasmota Configuration'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

*/