import 'package:ecotrack_mobile/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String otp;
  const ResetPasswordPage({super.key, required this.email, required this.otp});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  String newPassword = '';
  String confirmPassword = '';
  bool obscure = true;
  bool isLoading = false;

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }
    if (value.length < 8) {
      return "Password must be at least 8 characters long";
    }
    if (value.length > 128) {
      return "Password must be less than 128 characters";
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "Must contain at least one uppercase letter";
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return "Must contain at least one lowercase letter";
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "Must contain at least one number";
    }
    if (!RegExp(r'[!@#$%^&*(),.?\":{}|<>]').hasMatch(value)) {
      return "Must contain at least one special character";
    }
    return null;
  }

  Future<void> resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final url = Uri.parse('${dotenv.env['BASE_URL']}/api/auth/mobile/reset-password');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "otp": widget.otp,
          "newPassword": newPassword,
        }),
      );

      final resData = jsonDecode(response.body);
      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resData['msg'] ?? "Password reset successful")),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resData['msg'] ?? "Reset failed")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong. Please try again.")),
      );
      print("Reset password error: $e");
    }
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
                children: [
                  const SizedBox(height: 40),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Reset Password", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Enter your new password below.", style: TextStyle(color: Colors.black54)),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            obscureText: obscure,
                            decoration: InputDecoration(
                              labelText: "New Password",
                              suffixIcon: IconButton(
                                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => obscure = !obscure),
                              ),
                            ),
                            onChanged: (val) => setState(() => newPassword = val),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            obscureText: obscure,
                            decoration: const InputDecoration(labelText: "Confirm Password"),
                            onChanged: (val) => confirmPassword = val,
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Please confirm your password";
                              if (val != newPassword) return "Passwords do not match";
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: isLoading ? null : resetPassword,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text("Reset Password", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
