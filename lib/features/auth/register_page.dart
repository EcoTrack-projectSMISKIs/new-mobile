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

  bool isLoading = false;

  // Error states for server-side validation
  String? usernameError;
  String? phoneError;
  String? emailError;

  // Input validation methods
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Full name is required";
    }
    if (value.trim().length < 2) {
      return "Name must be at least 2 characters long";
    }
    if (value.trim().length > 50) {
      return "Name must be less than 50 characters";
    }
    // Check if name contains only letters and spaces
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return "Name can only contain letters and spaces";
    }
    return null;
  }

  String? _validateUsername(String? value) {
    // Check server-side error first
    if (usernameError != null) {
      return usernameError;
    }
    
    if (value == null || value.trim().isEmpty) {
      return "Username is required";
    }
    if (value.trim().length < 3) {
      return "Username must be at least 3 characters long";
    }
    if (value.trim().length > 20) {
      return "Username must be less than 20 characters";
    }
    // Check if username contains only alphanumeric characters and underscores
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return "Username can only contain letters, numbers, and underscores";
    }
    // Check if username starts with a letter
    if (!RegExp(r'^[a-zA-Z]').hasMatch(value.trim())) {
      return "Username must start with a letter";
    }
    return null;
  }

  String? _validatePhone(String? value) {
    // Check server-side error first
    if (phoneError != null) {
      return phoneError;
    }
    
    if (value == null || value.trim().isEmpty) {
      return "Phone number is required";
    }
    // Remove any non-digit characters for validation
    String cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Philippine mobile number validation (09xxxxxxxxx or +639xxxxxxxxx)
    if (cleanPhone.length == 11 && cleanPhone.startsWith('09')) {
      return null; // Valid format: 09xxxxxxxxx
    } else if (cleanPhone.length == 13 && cleanPhone.startsWith('639')) {
      return null; // Valid format: +639xxxxxxxxx (without the +)
    } else if (cleanPhone.length == 10 && cleanPhone.startsWith('9')) {
      return null; // Valid format: 9xxxxxxxxx
    } else {
      return "Please enter a valid Philippine mobile number";
    }
  }

  String? _validateEmail(String? value) {
    // Check server-side error first
    if (emailError != null) {
      return emailError;
    }
    
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }
    // Email regex pattern
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(value.trim())) {
      return "Please enter a valid email address";
    }
    if (value.trim().length > 100) {
      return "Email must be less than 100 characters";
    }
    return null;
  }

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
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "Password must contain at least one uppercase letter";
    }
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return "Password must contain at least one lowercase letter";
    }
    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "Password must contain at least one number";
    }
    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return "Password must contain at least one special character";
    }
    return null;
  }

  // Clear server-side errors when user starts typing
  void _clearServerErrors() {
    if (usernameError != null || phoneError != null || emailError != null) {
      setState(() {
        usernameError = null;
        phoneError = null;
        emailError = null;
      });
    }
  }

  Future<void> register() async {
    // Clear any previous server-side errors
    setState(() {
      usernameError = null;
      phoneError = null;
      emailError = null;
      isLoading = true;
    });

    final url = Uri.parse('${dotenv.env['BASE_URL']}/api/auth/mobile/register');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name.trim(),
          "username": username.trim().toLowerCase(),
          "phone": phone.trim(),
          "email": email.trim().toLowerCase(),
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
          SnackBar(content: Text(resData['message'] ?? "Registered successfully")),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => VerifyAccountPage(email: email.trim())),
        );
      } else {
        if (!mounted) return;
        
        // Handle specific field errors
        if (response.statusCode == 409 && resData['errors'] != null) {
          // Handle field-specific errors from server (HTTP 409 with errors object)
          Map<String, dynamic> errors = resData['errors'];
          setState(() {
            if (errors.containsKey('username')) {
              usernameError = errors['username'];
            }
            if (errors.containsKey('phone')) {
              phoneError = errors['phone'];
            }
            if (errors.containsKey('email')) {
              emailError = errors['email'];
            }
          });
          
          // Re-validate the form to show the errors
          _formKey.currentState!.validate();
        } else {
          // Show general error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resData['message'] ?? "Registration failed")),
          );
        }
      }
    } catch (error) {
      print("Error: $error");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Something went wrong. Please try again.")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
                      _buildField(
                        "Full Name", 
                        (val) {
                          name = val;
                          _clearServerErrors();
                        },
                        validator: _validateName,
                      ),
                      _buildField(
                        "Username", 
                        (val) {
                          username = val;
                          _clearServerErrors();
                        },
                        validator: _validateUsername,
                        hasError: usernameError != null,
                      ),
                      _buildField(
                        "Phone", 
                        (val) {
                          phone = val;
                          _clearServerErrors();
                        },
                        type: TextInputType.phone,
                        validator: _validatePhone,
                        hasError: phoneError != null,
                      ),
                      _buildField(
                        "Email", 
                        (val) {
                          email = val;
                          _clearServerErrors();
                        },
                        type: TextInputType.emailAddress,
                        validator: _validateEmail,
                        hasError: emailError != null,
                      ),
                      _buildField(
                        "Password", 
                        (val) {
                          password = val;
                          _clearServerErrors();
                        },
                        isPassword: true,
                        validator: _validatePassword,
                      ),
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
                            val == null || val.isEmpty ? "Please select a barangay" : null,
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
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    await register();
                                  }
                                },
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  "Next Step",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Arial',
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
Wrap(
  alignment: WrapAlignment.center,
  children: [
    const Text(
      "By continuing, you agree to have read and understood Ecotrack's ",
    ),
    GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TermsPolicyPage(),
          ),
        );
      },
      child: const Text(
        "Terms Of Service and Privacy Policy.",
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
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
      {TextInputType type = TextInputType.text, 
       bool isPassword = false, 
       String? Function(String?)? validator,
       bool hasError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        keyboardType: type,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: hasError ? Colors.red : Colors.black,
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.green, 
              width: 2
            ),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.black54,
            ),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          border: const UnderlineInputBorder(),
        ),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}