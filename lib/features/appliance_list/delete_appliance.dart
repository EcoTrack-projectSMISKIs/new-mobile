import 'package:ecotrack_mobile/widgets/error_modal.dart';
import 'package:ecotrack_mobile/widgets/success_modal.dart';
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
    required Function(String) onPlugRemoved,
    required VoidCallback onStateUpdate,
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

  // Enhanced delete method with proper error handling
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

    try {
      // Call the delete method with proper error handling
      final success = await _performDelete(
        plugId: plugId,
        plugName: plugName,
      );
      
      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (success) {
        // Add a small delay to ensure the loading dialog is fully dismissed
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Show success modal using custom modal
        if (context.mounted) {
          await context.showCustomSuccessModal(
            title: 'Device Removed',
            message: 'Smart plug reset and removed successfully',
            buttonText: 'Continue',
            onButtonPressed: () {
              Navigator.of(context).pop();
              // Call the callback to remove plug from local state
              onPlugRemoved(plugId);
              onStateUpdate();
            },
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      // Add a small delay to ensure the loading dialog is fully dismissed
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Handle any unhandled exceptions using custom error modal
      if (context.mounted) {
        await context.showCustomErrorModal(
          title: 'Plug Removal Failed',
          message: e.toString().replaceAll('Exception: ', ''),
          buttonText: 'OK',
          onButtonPressed: () {
            Navigator.of(context).pop();
          },
        );
      }
    }
  }

  // API delete method with better error handling and timeout
  static Future<bool> _performDelete({
    required String plugId,
    required String plugName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication error. Please log in again.');
    }

    final url = Uri.parse('${dotenv.env['BASE_URL']}/api/plugs/$plugId'); //- hard delete
    //final url = Uri.parse('${dotenv.env['BASE_URL']}/api/plugs/$plugId/soft-delete'); // - soft delete

    try {
      // Added timeout to prevent hanging
      final response = await http.delete(
        url,
        headers: {
         // 'Authorization': 'Bearer $token', - for hard delete only
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30), // 30 second timeout
        onTimeout: () {
          throw Exception('Request timed out. Please check your connection and try again.');
        },
      );

      if (response.statusCode == 200) {
        return true;
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

        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      } else {
        throw Exception('Network error. Please check your connection and try again.');
      }
    }
  }
}