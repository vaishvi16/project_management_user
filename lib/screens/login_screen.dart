// lib/screens/login_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project_management_user/models/user.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'project_details_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _selectedRole;
  static const List<String> _roles = ['Designer', 'Web Developer', 'App Developer', 'Tester', 'Backend'];
  bool _showMessage = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: themeProvider.currentTheme.brightness == Brightness.light
                ? [Colors.blue.shade50, Colors.white]
                : [Colors.indigo.shade900, Colors.black],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Hero(
                    tag: 'logo',
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blue, Colors.cyan]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'User Login',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your account',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.verified_user),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      contentPadding:  EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Enter email' : null,
                  ),
                   SizedBox(height: 16),
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon:  Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Enter password' : null,
                  ),
                  SizedBox(height: 10,),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.admin_panel_settings),
                    ),
                    items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                    onChanged: (value) => setState(() => _selectedRole = value),
                    validator: (value) => value == null ? 'Select role' : null,
                  ),
                  const SizedBox(height: 24),
                  // Login Button with animation
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {

                          loginUser();
                        }
                      },
                      child: const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showMessage = !_showMessage; // toggle message
                      });
                    },
                    child: Text("Forgot Password?"),
                  ),
                  if (_showMessage)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Please contact your admin",
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Theme Toggle (for demhgffhyo)
                  TextButton.icon(
                    onPressed: () => themeProvider.toggleTheme(),
                    icon: Icon(themeProvider.currentThemeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
                    label: Text('Toggle ${themeProvider.currentThemeMode == ThemeMode.dark ? 'Light' : 'Dark'} Mode'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void loginUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      var url = Uri.parse("https://prakrutitech.xyz/batch_project/login.php");
      var response = await http.post(url, body: {
        'email': _emailController.text.toString(),
        'password': _passwordController.text.toString(),
        'role': _selectedRole.toString()
      });
      print("response body of user login ${response.body}");

      final jsonData = jsonDecode(response.body);
      UserModel umodel = UserModel.fromJson(jsonData);
      print("User model: $umodel");

      if(umodel.code == 200){
        print("Login Success");
        print("${umodel.user!.name}");
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const ProjectDetailsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
      else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid Credentials'),
            backgroundColor: Colors.red,
          ),
        );
        print("Login Failed!!");
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
