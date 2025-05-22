import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

Future<String?> scanForTasmotaDevice() async {
  final info = NetworkInfo();
  final ip = await info.getWifiIP();

  if (ip == null || !ip.contains('.')) {
    print("❌ Unable to get local IP.");
    return null;
  }

  final subnet = ip.substring(0, ip.lastIndexOf('.') + 1); // e.g., 192.168.1.

  print("🔍 Scanning subnet: $subnet");

  final futures = <Future<String?>>[];

  for (int i = 1; i < 255; i++) {
    final testIp = '$subnet$i';
    futures.add(_checkTasmotaAtIp(testIp));
  }

  final results = await Future.wait(futures);
  final foundIp = results.firstWhere((ip) => ip != null, orElse: () => null);

  if (foundIp != null) {
    print("✅ Tasmota device found at $foundIp");
  } else {
    print("❌ Tasmota device not found on subnet.");
  }

  return foundIp;
}

Future<String?> _checkTasmotaAtIp(String ip) async {
  try {
    final url = Uri.parse('http://$ip/cm?cmnd=Status%200');
    final resp = await http.get(url).timeout(const Duration(seconds: 2));

    if (resp.statusCode == 200 && resp.body.contains('"Status"')) {
      final match = RegExp(r'"IPAddress":"([\d.]+)"').firstMatch(resp.body);
      final foundIp = match?.group(1);

      if (foundIp != null && foundIp != '0.0.0.0') {
        return foundIp;
      }
    }
  } catch (_) {
    // Ignore timeout or connection error
  }
  return null;
}

