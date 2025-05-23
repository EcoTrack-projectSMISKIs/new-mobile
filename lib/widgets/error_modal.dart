import 'package:flutter/material.dart';

/// A reusable custom error modal that can be used throughout the app
/// to display error messages with a consistent design.
class CustomErrorModal extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final Widget? icon;
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color titleColor;
  final Color messageBackgroundColor;
  final Color messageColor;
  final Color buttonColor;
  final Color buttonTextColor;

  const CustomErrorModal({
    Key? key,
    this.title = 'Connection Failed',
    required this.message,
    this.buttonText = 'Try Again',
    required this.onButtonPressed,
    this.icon,
    this.backgroundColor = Colors.white,
    this.iconBackgroundColor = const Color(0xFFFFF1F1),
    this.iconColor = const Color(0xFFE75D5D),
    this.titleColor = const Color(0xFF333333),
    this.messageBackgroundColor = const Color(0xFFFFF8E1),
    this.messageColor = const Color(0xFF666666),
    this.buttonColor = const Color(0xFF4CAF50),
    this.buttonTextColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon section
          Container(
            width: 100,
            height: 200,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: icon ??
                  Icon(
                    Icons.error_outline,
                    color: iconColor,
                    size: 100,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Message container with light yellow background
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: messageBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: messageColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          
          // Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: buttonTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension method to easily show the error modal from any context
extension ErrorModalExtension on BuildContext {
  Future<void> showCustomErrorModal({
    String title = 'Connection Failed',
    required String message,
    String buttonText = 'Try Again',
    required VoidCallback onButtonPressed,
    Widget? icon,
    Color? backgroundColor,
    Color? iconBackgroundColor,
    Color? iconColor,
    Color? titleColor,
    Color? messageBackgroundColor,
    Color? messageColor,
    Color? buttonColor,
    Color? buttonTextColor,
  }) {
    return showDialog(
      context: this,
      barrierDismissible: false,
      builder: (BuildContext context) => CustomErrorModal(
        title: title,
        message: message,
        buttonText: buttonText,
        onButtonPressed: onButtonPressed,
        icon: icon,
        backgroundColor: backgroundColor ?? Colors.white,
        iconBackgroundColor: iconBackgroundColor ?? const Color(0xFFFFF1F1),
        iconColor: iconColor ?? const Color(0xFFE75D5D),
        titleColor: titleColor ?? const Color(0xFF333333),
        messageBackgroundColor: messageBackgroundColor ?? const Color(0xFFFFF8E1),
        messageColor: messageColor ?? const Color(0xFF666666),
        buttonColor: buttonColor ?? const Color(0xFF4CAF50),
        buttonTextColor: buttonTextColor ?? Colors.white,
      ),
    );
  }
}