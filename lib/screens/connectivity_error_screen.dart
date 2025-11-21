import 'package:flutter/material.dart';

class ConnectivityErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;

  const ConnectivityErrorScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding:  EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 60,
                  color: Colors.red.shade400,
                ),
              ),

               SizedBox(height: 32),

              Text(
                "No Internet Connection",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),

               SizedBox(height: 16),

              Text(
                "It looks like you're not connected to the internet. "
                    "Please check your connection and try again.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),



               SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  _showHelpDialog(context);
                },
                child: Text(
                  "Check Network Settings",
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text("Network Help"),
        content:  Text(
            "• Check if Wi-Fi or mobile data is turned on\n"
                "• Restart your router\n"
                "• Move to a location with better signal\n"
                "• Check airplane mode is turned off"
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text("OK"),
          ),
        ],
      ),
    );
  }
}