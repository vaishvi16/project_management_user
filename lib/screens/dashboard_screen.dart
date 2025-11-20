// lib/screens/dashboard_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/project.dart';
import 'history_screen.dart';
import 'project_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _expanded = false;

  static final Map<String, int> _statusCounts = {
    'onhold': 2,
    'continue': 5,
    'pending': 3,
    'complete': 4,
    'approved': 2,
  };

  Map<String, int> _stats = {
    'total_projects': 0,
    'Complete': 0,
    'Pending': 0,
    'On Hold': 0,
    'teamMembers': 0,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 768;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: FutureBuilder(future: _fetchAllStats(), builder: (context,AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }

        // Update stats for UI
        _stats = snapshot.data!;

        return  CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              iconTheme: IconThemeData(
                color: Colors.white,
              ),
              expandedHeight: 120,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1976D2), // Blue 700
                        Color(0xFF7B1FA2), // Purple 600
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.history, color: Colors.white, size: 20),
                  ),
                  onPressed: _navigateToHistory,
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Dashboard Content
            SliverPadding(
              padding: const EdgeInsets.all(16), // Reduced padding to prevent overflow
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Welcome Section
                  _buildWelcomeSection(),
                  const SizedBox(height: 24),

                  // Stats Grid
                  _buildStatsGrid(),
                  const SizedBox(height: 24),

                  // Charts Section
                  // isWideScreen ? _buildWideCharts() : _buildMobileCharts(),
                  const SizedBox(height: 24),


                  // Activity Logs
                  const SizedBox(height: 24), // Extra bottom padding
                ]),
              ),
            ),
          ],
        );

      },)
    );
  }

  Widget _buildWelcomeSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE3F2FD), // Blue 50
                Color(0xFFF3E5F5), // Purple 50
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF90CAF9)), // Blue 200
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: TextStyle(
                        fontSize: 20, // Slightly smaller
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1565C0), // Blue 800
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You have ${_stats['Pending']} projects in progress. '
                          '${_stats['Complete']} completed this month.',
                      style: TextStyle(
                        fontSize: 14, // Smaller font
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox( // Constrained button size
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _navigateToProjects,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2), // Blue 600
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'View All Projects',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 60, // Smaller icon container
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1976D2).withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.rocket_launch,
                  size: 30,
                  color: const Color(0xFF1976D2), // Blue 600
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {
        'title': 'Total Projects',
        'value': _stats['total_projects'].toString(),
        'icon': Icons.assignment,
        'color': const Color(0xFF1976D2), // Blue
        'change': '+12%',
      },
      {
        'title': 'In Progress',
        'value': _stats['Pending'].toString(),
        'icon': Icons.trending_up,
        'color': const Color(0xFFF57C00), // Orange
        'change': '+5%',
      },
      {
        'title': 'Completed',
        'value': _stats['Complete'].toString(),
        'icon': Icons.check_circle,
        'color': const Color(0xFF388E3C), // Green
        'change': '+8%',
      },
      {
        'title': 'On Hold',
        'value': _stats['On Hold'],
        'icon': Icons.pause_circle,
        'color': const Color(0xFFF44336), // Red
        'change': '+2%',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1, // Adjusted aspect ratio
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        final Color color = stat['color'] as Color;

        return AnimatedContainer(
          duration: Duration(milliseconds: 600 + (index * 200)),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(
              top: index.isEven ? 0 : 10,
              bottom: index.isEven ? 10 : 0
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.1 * index, 1, curve: Curves.easeOut),
              )),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.shade100,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            stat['icon'] as IconData,
                            color: color,
                            size: 18,
                          ),
                        ),
                        Text(
                          stat['change'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF388E3C), // Green
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stat['value'].toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stat['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }


  void _navigateToProjects() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ProjectDetailsScreen()),
          (route) => false, // This removes all previous routes
    );
  }

  Future<int> _fetchProjectCount({String? status}) async {
    try {
      String url = "https://prakrutitech.xyz/batch_project/view_project.php";

      if (status != null && status.isNotEmpty) {
        url = "$url?status=$status";
      }

      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        print("here is the data: $data");
        return data['total_projects'] as int;      }
      return 0;
    } catch (e) {
      print("API ERROR: $e");
      return 0;
    }
  }

  Future<Map<String, int>> _fetchAllStats() async {
    final total = await _fetchProjectCount();
    final Complete = await _fetchProjectCount(status: "Complete");
    final OnHold = await _fetchProjectCount(status: "On Hold");
    final Pending = await _fetchProjectCount(status: "Pending");

    return {
      'total_projects': total,
      'Complete': Complete,
      'Pending': Pending,
      'On Hold': OnHold,
      'teamMembers': 12,
    };
  }

}
