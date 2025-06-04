import 'package:ecotrack_mobile/features/auth/reset_password_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VerifyOtpPage extends StatefulWidget {
  final String email;
  const VerifyOtpPage({super.key, required this.email});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  String otp = '';
  int _secondsRemaining = 0;
  Timer? _resendTimer;
  bool isLoading = false;

  Future<void> resendOtp() async {
    final url = Uri.parse('${dotenv.env['BASE_URL']}/api/auth/mobile/resend-reset-password-otp');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": widget.email}),
    );
    final resData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resData['msg'] ?? "OTP resent")),
      );

      setState(() => _secondsRemaining = 60);
      _resendTimer?.cancel();
      _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining == 0) {
          timer.cancel();
        } else {
          setState(() => _secondsRemaining--);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resData['msg'] ?? "Failed to resend OTP")),
      );
    }
  }

  Future<void> verifyOtp() async {
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid 6-digit OTP")),
      );
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse('${dotenv.env['BASE_URL']}/api/auth/mobile/verify-forgot-otp');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": widget.email, "otp": otp}),
    );

    final resData = jsonDecode(response.body);
    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordPage(email: widget.email, otp: otp),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resData['message'] ?? "Invalid OTP")),
      );
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.green),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    "Enter OTP code",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "We just sent an OTP code to your email",
                    style: TextStyle(color: Colors.black54),
                  ),
                  Text(
                    widget.email,
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        PinCodeTextField(
                          appContext: context,
                          length: 6,
                          onChanged: (value) => otp = value,
                          keyboardType: TextInputType.number,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(8),
                            fieldHeight: 50,
                            fieldWidth: 40,
                            activeColor: Colors.green,
                            selectedColor: Colors.greenAccent,
                            inactiveColor: Colors.grey.shade300,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Next Step",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Did not receive the OTP code?",
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        _secondsRemaining > 0
                            ? Text(
                                "Resend after ${_secondsRemaining}s",
                                style: const TextStyle(color: Colors.black45),
                              )
                            : TextButton(
                                onPressed: resendOtp,
                                child: const Text(
                                  "Resend OTP",
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}