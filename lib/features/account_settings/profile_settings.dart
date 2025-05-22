import 'dart:io';
import 'package:ecotrack_mobile/widgets/navbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecotrack_mobile/features/landing_page/landing_page.dart';
import 'package:image_picker/image_picker.dart';

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
        title: Text("Edit $title"),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Save"),
          ),
        ],
      ),
    );
    if (result != null && result != currentValue) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, result);
      loadUserData();
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        profileImage = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: profileImage != null
                    ? FileImage(profileImage!)
                    : const AssetImage("assets/icons/profile_icon.png") as ImageProvider,
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            _buildProfileOption("Username", username, 'username'),
            _buildProfileOption("Email", email, 'email'),
            _buildProfileOption("Phone", phone, 'phone'),
            _buildProfileOption("Barangay", barangay, 'barangay'),
            const SizedBox(height: 40),
            _buildLogoutButton(context),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        bottom: false,
            child: CustomBottomNavBar(selectedIndex: 4),
        )
    );
  }

  Widget _buildProfileOption(String title, String value, String key) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit),
      onTap: () => _editField(title, key, value),
      // add edit functionality if needed
      // write code in this part
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LandingPage()),
          (Route<dynamic> route) => false,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text("Logout", style: TextStyle(fontSize: 16, color: Colors.white)),
    );
  }
}
