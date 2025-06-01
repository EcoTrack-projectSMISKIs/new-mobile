import 'package:flutter/material.dart';

class TermsPolicyPage extends StatefulWidget {
  const TermsPolicyPage({super.key});

  @override
  State<TermsPolicyPage> createState() => _TermsPolicyPageState();
}

class _TermsPolicyPageState extends State<TermsPolicyPage> {
  bool isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Terms & Privacy", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Terms of Service", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              _buildNumberedList([
                "Acceptance of Terms - These Terms govern your use of the app.",
                "Use of the App - You must be 13+ and use it lawfully.",
                "Account Responsibility - You are responsible for your login credentials.",
                "Modifications - We may update the app or Terms at any time.",
                "Termination - Accounts may be suspended for violations.",
                "Limitation of Liability - We are not liable for any damage from use of the app.",
              ]),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Privacy Policy", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              _buildNumberedList([
                "Information We Collect - Name, email, phone, barangay, device stats.",
                "How We Use It - To operate, support, and improve the app.",
                "Data Sharing & Security - We do not sell your data and store it securely.",
                "User Control - You may edit or delete your account.",
                "Updates - Changes will appear in the app.",
              ]),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: isAgreed,
                    onChanged: (val) {
                      setState(() {
                        isAgreed = val ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'I have read and agree to the Terms of Service and Privacy Policy.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isAgreed
                      ? () {
                          // Navigate to next screen or pop
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberedList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final text = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            "$index. $text",
            textAlign: TextAlign.justify,
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
        );
      }).toList(),
    );
  }
}
