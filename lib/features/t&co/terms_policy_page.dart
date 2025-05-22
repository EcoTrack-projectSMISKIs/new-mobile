import 'package:flutter/material.dart';

class TermsPolicyPage extends StatelessWidget {
  const TermsPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Terms & Privacy")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Terms of Service", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                "By using the EcoTrack mobile application, you agree to the following terms:\n\n"
                "1. Acceptance of Terms\n- These Terms govern your use of the app.\n"
                "2. Use of the App\n- You must be 13+ and use it lawfully.\n"
                "3. Account Responsibility\n- You are responsible for your login credentials.\n"
                "4. Modifications\n- We may update the app or Terms at any time.\n"
                "5. Termination\n- Accounts may be suspended for violations.\n"
                "6. Limitation of Liability\n- We are not liable for any damage from use of the app.",
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 24),
              Text("Privacy Policy", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                "1. Information We Collect\n- Name, email, phone, barangay, device stats.\n"
                "2. How We Use It\n- To operate, support, and improve the app.\n"
                "3. Data Sharing & Security\n- We do not sell your data and store it securely.\n"
                "4. User Control\n- You may edit or delete your account.\n"
                "5. Updates\n- Changes will appear in the app.",
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}