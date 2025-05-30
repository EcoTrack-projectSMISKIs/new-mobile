import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApplianceDeleteHelper {
  
  // Method to handle deleting an appliance
  static Future<void> deleteAppliance({
    required BuildContext context,
    required String plugId,
    required String plugName,
    required Function(String) onPlugRemoved, // Callback to update UI
    required VoidCallback onStateUpdate, // Callback for setState
  }) async {
    // Single comprehensive confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Remove Smart Plug',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to remove "$plugName" from your devices.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'This action will:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildBulletPoint('Reset the smart plug to factory settings'),
                    _buildBulletPoint('Remove all usage data'),
                    _buildBulletPoint('Disconnect from your network'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Ensure the plug is connected to power and internet',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 111, 111, 111),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  const Text(
                    'Remove & Reset',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        );
      },
    );

    if (confirmed == true) {
      await _performDeleteWithFeedback(
        context: context,
        plugId: plugId,
        plugName: plugName,
        onPlugRemoved: onPlugRemoved,
        onStateUpdate: onStateUpdate,
      );
    }
  }

  // Helper method to build bullet points
  static Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced delete method with loading feedback
  static Future<void> _performDeleteWithFeedback({
    required BuildContext context,
    required String plugId,
    required String plugName,
    required Function(String) onPlugRemoved,
    required VoidCallback onStateUpdate,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 216, 213, 213),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Removing $plugName...',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we reset your smart plug',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );

    // Call the delete method
    await _performDelete(
      context: context,
      plugId: plugId,
      plugName: plugName,
      onPlugRemoved: onPlugRemoved,
      onStateUpdate: onStateUpdate,
    );

    // Close loading dialog
    Navigator.of(context).pop();
  }

  // API delete method with error handling
  static Future<void> _performDelete({
    required BuildContext context,
    required String plugId,
    required String plugName,
    required Function(String) onPlugRemoved,
    required VoidCallback onStateUpdate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      print('Token not found');
      _showErrorModal(context, 'Authentication error. Please log in again.');
      return;
    }

    final url = Uri.parse('${dotenv.env['BASE_URL']}/api/plugs/$plugId');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Show success modal and handle success callback
        _showSuccessModal(
          context,
          'Smart plug reset and removed successfully',
          () {
            // Call the callback to remove plug from local state
            onPlugRemoved(plugId);
            onStateUpdate();
          },
        );
      } else {
        // Handle different error status codes
        String errorMessage = 'Failed to delete and reset smart plug';
        if (response.statusCode == 404) {
          errorMessage = 'Smart plug not found';
        } else if (response.statusCode == 401) {
          errorMessage = 'Authentication failed. Please log in again.';
        } else if (response.statusCode >= 500) {
          errorMessage = 'Server error. Please try again later.';
        }

        _showErrorModal(context, errorMessage);
      }
    } catch (e) {
      print('Error deleting smart plug: $e');
      String errorMessage = e.toString().contains('Exception:')
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Network error. Please check your connection.';
      
      _showErrorModal(context, errorMessage);
    }
  }

  // Helper method to show error modal
  static void _showErrorModal(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Helper method to show success modal
  static void _showSuccessModal(BuildContext context, String message, VoidCallback onSuccess) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onSuccess();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}