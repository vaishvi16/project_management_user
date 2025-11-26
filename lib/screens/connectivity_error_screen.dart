import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:project_management_user/screens/project_details_screen.dart';
import 'package:project_management_user/screens/splash_screen.dart';

import '../shared_preferences/shared_pref.dart';
import 'login_screen.dart';

class ConnectivityErrorScreen extends StatefulWidget {
  final VoidCallback? onRetry;

  ConnectivityErrorScreen({super.key, this.onRetry});

  @override
  State<ConnectivityErrorScreen> createState() => _ConnectivityErrorScreenState();
}

class _ConnectivityErrorScreenState extends State<ConnectivityErrorScreen> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _navigated = false;
  //already pushed the code..

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
              TextButton(
                onPressed: () {
                  _checkConnectivity();
                },
                child: Text(
                  "Try Again",
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

  void _checkConnectivity() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) async {
          if (_navigated) return; // prevent double navigation

          if (result.contains(ConnectivityResult.mobile) ||
              result.contains(ConnectivityResult.wifi)) {
            bool isLoggedIn = await SharedPref.getLoginStatus();

            setState(() {
              _navigated = true;
            });

            if (isLoggedIn) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProjectDetailsScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          } else {
            setState(() {
              _navigated = true;
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) =>  ConnectivityErrorScreen()),
            );
          }
        });
  }
}