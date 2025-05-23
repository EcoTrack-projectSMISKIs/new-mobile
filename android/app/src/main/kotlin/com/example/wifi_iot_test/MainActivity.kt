package com.example.wifi_iot_test

import android.net.*
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.network/bind"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "bindNetwork") {
                val internetRequired = call.argument<Boolean>("internetRequired") ?: true
                bindNetwork(result, internetRequired)
            }
        }
    }

    private fun bindNetwork(result: MethodChannel.Result, internetRequired: Boolean) {
        val connectivityManager = getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val networks = connectivityManager.allNetworks
            for (network in networks) {
                val capabilities = connectivityManager.getNetworkCapabilities(network)

                val isWiFi = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
                val hasInternet = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true

                // Match based on internet requirement
                if (isWiFi && (!internetRequired || hasInternet)) {
                    val success = connectivityManager.bindProcessToNetwork(network)
                    Log.i("WiFiBinding", "✅ Bound to Wi-Fi (internetRequired=$internetRequired): $network, Success: $success")
                    result.success(success)
                    return
                }
            }
            Log.e("WiFiBinding", "❌ No suitable Wi-Fi network found (internetRequired=$internetRequired).")
        } else {
            Log.e("WiFiBinding", "❌ Android version < M; not supported.")
        }
        result.success(false)
    }
}
