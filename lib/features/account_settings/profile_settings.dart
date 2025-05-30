import 'dart:io';
import 'package:ecotrack_mobile/widgets/navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecotrack_mobile/features/landing_page/landing_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  String name = "";
  String username = "";
  String email = "";
  String phone = "";
  String barangay = "";
  File? profileImage;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

Future<void> loadUserData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (!mounted) return;
  setState(() {
    name = prefs.getString('name') ?? "Not Set";
    username = prefs.getString('username') ?? "Not Set";
    email = prefs.getString('email') ?? "Not Set";
    phone = prefs.getString('phone') ?? "Not Set";
    barangay = prefs.getString('barangay') ?? "Not Set";
  });
}

Future<void> _editField(String title, String key, String currentValue) async {
  TextEditingController controller = TextEditingController(text: currentValue);

  final result = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "Edit $title",
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
          ),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text("Save"),
        ),
      ],
    ),
  );

  if (result != null && result != currentValue) {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (key == 'name' || key == 'username') {
      // Update via API
      String? token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
        return;
      }

      final response = await http.put(
        Uri.parse('${dotenv.env['BASE_URL']}/api/auth/mobile/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({key: result}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedValue = data['user'][key] ?? result;
        await prefs.setString(key, updatedValue);
        loadUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? 'Failed to update')),
        );
      }
    } else {
      // Just update locally
      await prefs.setString(key, result);
      loadUserData();
    }
  }
}


  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      if (!mounted) return;
      setState(() {
        profileImage = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section with gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF109717),
                    Color.fromARGB(255, 71, 161, 74),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    children: [
                      // Back button and title
                      Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                "         Profile Settings",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48), // Balance the back button
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Profile image section
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 65,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: profileImage != null
                                    ? FileImage(profileImage!)
                                    : null,
                                child: profileImage == null
                                    ? Icon(
                                        Icons.person,
                                        size: 65,
                                        color: Colors.grey.shade600,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "@$username",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Profile fields section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile info card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: Text(
                            "Personal Information",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        _buildProfileField("Full Name", name, "name",
                            isEditable: true),
                        _buildDivider(),
                        _buildProfileField("Username", username, "username",
                            isEditable: true),
                        _buildDivider(),
                        _buildProfileField("Email", email, "email",
                            isEditable: false),
                        _buildDivider(),
                        _buildProfileField("Phone", phone, "phone",
                            isEditable: false),
                        _buildDivider(),
                        _buildProfileField("Barangay", barangay, "barangay",
                            isEditable: false),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Logout button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final shouldLogout = await _showLogoutConfirmation();
                        if (shouldLogout == true) {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          await prefs.clear();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LandingPage()),
                            (Route<dynamic> route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, size: 20, color: Colors.white,),
                          SizedBox(width: 8),
                          Text(
                            "Logout",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        bottom: false,
        child: CustomBottomNavBar(selectedIndex: 4),
      ),
    );
  }

  Widget _buildProfileField(String label, String value, String key,
      {required bool isEditable}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (!isEditable) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.lock,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (isEditable)
            IconButton(
              onPressed: () => _editField(label, key, value),
              icon: Icon(
                Icons.edit,
                color: Colors.green.shade600,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade200,
      indent: 20,
      endIndent: 20,
    );
  }

  Future<bool?> _showLogoutConfirmation() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Logout",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}