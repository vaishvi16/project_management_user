// lib/screens/history_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/project.dart';

class HistoryScreen extends StatefulWidget {
  final String? email;
  HistoryScreen({required this.email});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<Project> _history = [];


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getProjects();
  }
  @override
  Widget build(BuildContext context) {
    // Demo history data


    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: FutureBuilder(
        future: getProjects(),
        builder: (context, asyncSnapshot) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final item = _history[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.history, color: Colors.blue),
                  title: Text(item.name!),
                  subtitle: Text('${item.title} by ${item.members}'),
                ),
              );
            },
          );
        }
      ),
    );
  }

  Future<List<Project>> getProjects() async {
    var url = Uri.parse(
      "https://prakrutitech.xyz/batch_project/view_project.php",
    );
    var response = await http.get(url);

    if (response.statusCode == 200) {
      print("Get project api working! ${response.body.toString()}");
      final jsonResponse = jsonDecode(response.body);

      final List<dynamic> projectsJson = jsonResponse['projects'] ?? [];

      // Convert to list of Project objects
      final List<Project> projects = projectsJson
          .map((json) => Project.fromJson(json))
          .toList();


      _history = projects.where((project) {
        return project.members_email.contains("${widget.email}");
      }).toList();

      print("Filtered projects count: ${_history.length}");

      return _history;
    } else {
      print("Get project api not working!!");
      return [];
    }
  }
}
