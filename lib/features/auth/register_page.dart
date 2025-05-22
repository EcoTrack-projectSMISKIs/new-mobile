import 'package:ecotrack_mobile/features/auth/verify_account.dart';
import 'package:ecotrack_mobile/features/t&co/terms_policy_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String username = '';
  String phone = '';
  String email = '';
  String password = '';
  String barangay = '';

  Future<void> register() async {
    final url = Uri.parse('${dotenv.env['BASE_URL']}/api/auth/mobile/register');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "username": username,
          "phone": phone,
          "email": email,
          "password": password,
          "barangay": barangay,
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      final resData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resData['msg'] ?? "Registered successfully")),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => VerifyAccountPage(email: email)),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resData['msg'] ?? "Registration failed")),
        );
      }
    } catch (error) {
      print("Error: $error");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Something went wrong. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.green),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Sign up",
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Please enter your details to create an account.",
                  style: TextStyle(color: Colors.black54),
                ),
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
                      _buildField("Full Name", (val) => name = val),
                      _buildField("Username", (val) => username = val),
                      _buildField("Phone", (val) => phone = val,
                          type: TextInputType.phone),
                      _buildField("Email", (val) => email = val,
                          type: TextInputType.emailAddress),
                      _buildField("Password", (val) => password = val,
                          isPassword: true),
                      DropdownButtonFormField<String>(
                        value: barangay.isNotEmpty ? barangay : null,
                        items: <String>[
                          "Aga",
                          "Balaytigui",
                          "Banilad",
                          "Barangay 1 (Pob.)",
                          "Barangay 2 (Pob.)",
                          "Barangay 3 (Pob.)",
                          "Barangay 4 (Pob.)",
                          "Barangay 5 (Pob.)",
                          "Barangay 6 (Pob.)",
                          "Barangay 7 (Pob.)",
                          "Barangay 8 (Pob.)",
                          "Barangay 9 (Pob.)",
                          "Barangay 10 (Pob.)",
                          "Barangay 11 (Pob.)",
                          "Barangay 12 (Pob.)",
                          "Bilaran",
                          "Bucana",
                          "Bulihan",
                          "Bunducan",
                          "Butucan",
                          "Calayo",
                          "Catandaan",
                          "Cogunan",
                          "Dayap",
                          "Kaylaway",
                          "Kayrilaw",
                          "Latag",
                          "Looc",
                          "Lumbangan",
                          "Malapad Na Bato",
                          "Mataas Na Pulo",
                          "Maugat",
                          "Munting Indang",
                          "Natipuan",
                          "Pantalan",
                          "Papaya",
                          "Putat",
                          "Reparo",
                          "Talangan",
                          "Tumalím",
                          "Utod",
                          "Wawa"
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => barangay = val!),
                        decoration:
                            const InputDecoration(labelText: "Barangay"),
                        validator: (val) =>
                            val == null || val.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              await register();
                            }
                          },
                          child: const Text("Next Step",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Arial',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                              "By continuing, you agree to have read and understood Ecotrack’s "),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const TermsPolicyPage()));
                            },
                            child: const Text("Terms Of Service",
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const Text(" and "),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const TermsPolicyPage()));
                            },
                            child: const Text("Privacy Policy",
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const Text("."),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, Function(String) onChanged,
      {TextInputType type = TextInputType.text, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        keyboardType: type,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.green, width: 2),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black54),
          ),
          border: const UnderlineInputBorder(),
        ),
        onChanged: onChanged,
        validator: (val) => val!.isEmpty ? "Required" : null,
      ),
    );
  }
}
