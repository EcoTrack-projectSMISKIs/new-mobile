import 'package:ecotrack_mobile/features/auth/verify_account.dart';
import 'package:ecotrack_mobile/features/t&co/terms_policy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers for real-time validation
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String name = '';
  String username = '';
  String phone = '';
  String email = '';
  String password = '';
  String barangay = '';

  bool isLoading = false;
  bool _passwordVisible = false;
  Timer? _validationTimer;

  // Real-time validation states
  bool nameValid = false;
  bool usernameValid = false;
  bool phoneValid = false;
  bool emailValid = false;
  bool passwordValid = false;

  // Error states for server-side validation
  String? usernameError;
  String? phoneError;
  String? emailError;

  // Real-time error messages
  String? nameError;
  String? usernameClientError;
  String? phoneClientError;
  String? emailClientError;
  String? passwordClientError;

  // Password strength indicators
  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasNumbers = false;
  bool hasSpecialCharacters = false;
  bool hasMinLength = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _validationTimer?.cancel();
    super.dispose();
  }

  void _setupListeners() {
    _nameController.addListener(() => _validateFieldRealTime('name'));
    _usernameController.addListener(() => _validateFieldRealTime('username'));
    _phoneController.addListener(() => _validateFieldRealTime('phone'));
    _emailController.addListener(() => _validateFieldRealTime('email'));
    _passwordController.addListener(() => _validateFieldRealTime('password'));
  }

  void _validateFieldRealTime(String field) {
    _validationTimer?.cancel();
    _validationTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          switch (field) {
            case 'name':
              name = _nameController.text;
              nameError = _validateName(_nameController.text);
              nameValid = nameError == null && _nameController.text.isNotEmpty;
              break;
            case 'username':
              username = _usernameController.text;
              usernameClientError = _validateUsername(_usernameController.text, false);
              usernameValid = usernameClientError == null && _usernameController.text.isNotEmpty;
              break;
            case 'phone':
              phone = _phoneController.text;
              phoneClientError = _validatePhone(_phoneController.text, false);
              phoneValid = phoneClientError == null && _phoneController.text.isNotEmpty;
              break;
            case 'email':
              email = _emailController.text;
              emailClientError = _validateEmail(_emailController.text, false);
              emailValid = emailClientError == null && _emailController.text.isNotEmpty;
              break;
            case 'password':
              password = _passwordController.text;
              _updatePasswordStrength(_passwordController.text);
              passwordClientError = _validatePassword(_passwordController.text);
              passwordValid = passwordClientError == null && _passwordController.text.isNotEmpty;
              break;
          }
        });
      }
    });
  }

  void _updatePasswordStrength(String password) {
    hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    hasNumbers = RegExp(r'[0-9]').hasMatch(password);
    hasSpecialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    hasMinLength = password.length >= 8;
  }

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
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return "Name can only contain letters and spaces";
    }
    return null;
  }

  String? _validateUsername(String? value, bool checkServerError) {
    if (checkServerError && usernameError != null) {
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
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return "Username can only contain letters, numbers, and underscores";
    }
    if (!RegExp(r'^[a-zA-Z]').hasMatch(value.trim())) {
      return "Username must start with a letter";
    }
    return null;
  }

  String? _validatePhone(String? value, bool checkServerError) {
    if (checkServerError && phoneError != null) {
      return phoneError;
    }
    
    if (value == null || value.trim().isEmpty) {
      return "Phone number is required";
    }
    
    String cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanPhone.length == 11 && cleanPhone.startsWith('09')) {
      return null;
    } else if (cleanPhone.length == 13 && cleanPhone.startsWith('639')) {
      return null;
    } else if (cleanPhone.length == 10 && cleanPhone.startsWith('9')) {
      return null;
    } else {
      return "Please enter a valid Philippine mobile number";
    }
  }

  String? _validateEmail(String? value, bool checkServerError) {
    if (checkServerError && emailError != null) {
      return emailError;
    }
    
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }
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
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "Password must contain at least one uppercase letter";
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return "Password must contain at least one lowercase letter";
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "Password must contain at least one number";
    }
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

  bool get _isFormValid {
    return nameValid && 
           usernameValid && 
           phoneValid && 
           emailValid && 
           passwordValid && 
           barangay.isNotEmpty;
  }

  Future<void> register() async {
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
          SnackBar(
            content: Text(resData['message'] ?? "Registered successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => VerifyAccountPage(email: email.trim())),
        );
      } else {
        if (!mounted) return;
        
        if (response.statusCode == 409 && resData['errors'] != null) {
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
          
          _formKey.currentState!.validate();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resData['message'] ?? "Registration failed"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (error) {
      print("Error: $error");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong. Please try again."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.green, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 32),
                  child: Text(
                    "Please fill in your details to get started.",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              // Form Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Full Name Field
                      _buildEnhancedField(
                        controller: _nameController,
                        label: "Full Name",
                        icon: Icons.person_outline,
                        isValid: nameValid,
                        errorText: nameError,
                        validator: _validateName,
                        onChanged: (val) {
                          name = val;
                          _clearServerErrors();
                        },
                      ),

                      // Username Field
                      _buildEnhancedField(
                        controller: _usernameController,
                        label: "Username",
                        icon: Icons.alternate_email,
                        isValid: usernameValid,
                        errorText: usernameError ?? usernameClientError,
                        validator: (val) => _validateUsername(val, true),
                        onChanged: (val) {
                          username = val;
                          _clearServerErrors();
                        },
                        helperText: "Must start with a letter, 3-20 characters",
                      ),

                      // Phone Field
                      _buildEnhancedField(
                        controller: _phoneController,
                        label: "Phone Number",
                        icon: Icons.phone_outlined,
                        type: TextInputType.phone,
                        isValid: phoneValid,
                        errorText: phoneError ?? phoneClientError,
                        validator: (val) => _validatePhone(val, true),
                        onChanged: (val) {
                          phone = val;
                          _clearServerErrors();
                        },
                        helperText: "Format: 09xxxxxxxxx",
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
                        ],
                      ),

                      // Email Field
                      _buildEnhancedField(
                        controller: _emailController,
                        label: "Email Address",
                        icon: Icons.email_outlined,
                        type: TextInputType.emailAddress,
                        isValid: emailValid,
                        errorText: emailError ?? emailClientError,
                        validator: (val) => _validateEmail(val, true),
                        onChanged: (val) {
                          email = val;
                          _clearServerErrors();
                        },
                      ),

                      // Password Field with Strength Indicator
                      _buildPasswordField(),

                      // Barangay Dropdown
                      const SizedBox(height: 16),
                      _buildBarangayDropdown(),

                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFormValid ? Colors.green : Colors.grey[300],
                            foregroundColor: _isFormValid ? Colors.white : Colors.grey[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: _isFormValid ? 4 : 0,
                          ),
                          onPressed: (isLoading || !_isFormValid)
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
                                  "Create Account",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Terms and Conditions
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            "By continuing, you agree to ",
                            style: TextStyle(color: Colors.black54),
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
                              "Terms of Service",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text(
                            " and ",
                            style: TextStyle(color: Colors.black54),
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
                              "Privacy Policy",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildEnhancedField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    TextInputType type = TextInputType.text,
    bool isValid = false,
    String? errorText,
    String? helperText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    bool hasError = errorText != null && controller.text.isNotEmpty;
    bool showSuccess = isValid && controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: type,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(
                icon,
                color: hasError
                    ? Colors.red
                    : showSuccess
                        ? Colors.green
                        : Colors.grey[600],
              ),
              suffixIcon: controller.text.isNotEmpty
                  ? Icon(
                      showSuccess
                          ? Icons.check_circle
                          : hasError
                              ? Icons.error
                              : null,
                      color: showSuccess ? Colors.green : Colors.red,
                      size: 20,
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red
                      : showSuccess
                          ? Colors.green
                          : Colors.green,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              labelStyle: TextStyle(
                color: hasError ? Colors.red : Colors.grey[700],
              ),
            ),
            onChanged: onChanged,
            validator: validator,
          ),
          if (helperText != null && !hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(
                helperText,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(
                errorText!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    bool hasError = passwordClientError != null && _passwordController.text.isNotEmpty;
    bool showSuccess = passwordValid && _passwordController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
            decoration: InputDecoration(
              labelText: "Password",
              prefixIcon: Icon(
                Icons.lock_outline,
                color: hasError
                    ? Colors.red
                    : showSuccess
                        ? Colors.green
                        : Colors.grey[600],
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_passwordController.text.isNotEmpty)
                    Icon(
                      showSuccess
                          ? Icons.check_circle
                          : hasError
                              ? Icons.error
                              : null,
                      color: showSuccess ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  IconButton(
                    icon: Icon(
                      _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ],
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red
                      : showSuccess
                          ? Colors.green
                          : Colors.green,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              labelStyle: TextStyle(
                color: hasError ? Colors.red : Colors.grey[700],
              ),
            ),
            onChanged: (val) {
              password = val;
              _clearServerErrors();
            },
            validator: _validatePassword,
          ),
          
          // Password Strength Indicators
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Password Requirements:",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildPasswordRequirement("At least 8 characters", hasMinLength),
                  _buildPasswordRequirement("One uppercase letter", hasUppercase),
                  _buildPasswordRequirement("One lowercase letter", hasLowercase),
                  _buildPasswordRequirement("One number", hasNumbers),
                  _buildPasswordRequirement("One special character", hasSpecialCharacters),
                ],
              ),
            ),
          ],
          
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(
                passwordClientError!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check : Icons.close,
            size: 14,
            color: isMet ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isMet ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarangayDropdown() {
    return DropdownButtonFormField<String>(
      value: barangay.isNotEmpty ? barangay : null,
      decoration: InputDecoration(
        labelText: "Barangay",
        prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      items: <String>[
        "Aga", "Balaytigui", "Banilad", "Barangay 1 (Pob.)", "Barangay 2 (Pob.)",
        "Barangay 3 (Pob.)", "Barangay 4 (Pob.)", "Barangay 5 (Pob.)", "Barangay 6 (Pob.)",
        "Barangay 7 (Pob.)", "Barangay 8 (Pob.)", "Barangay 9 (Pob.)", "Barangay 10 (Pob.)",
        "Barangay 11 (Pob.)", "Barangay 12 (Pob.)", "Bilaran", "Bucana", "Bulihan",
        "Bunducan", "Butucan", "Calayo", "Catandaan", "Cogunan", "Dayap", "Kaylaway",
        "Kayrilaw", "Latag", "Looc", "Lumbangan", "Malapad Na Bato", "Mataas Na Pulo",
        "Maugat", "Munting Indang", "Natipuan", "Pantalan", "Papaya", "Putat", "Reparo",
        "Talangan", "Tumalím", "Utod", "Wawa"
      ].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (val) => setState(() => barangay = val!),
      validator: (val) => val == null || val.isEmpty ? "Please select a barangay" : null,
    );
  }
}