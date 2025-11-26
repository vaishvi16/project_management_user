// lib/screens/project_details_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:project_management_user/screens/login_screen.dart';
import 'package:project_management_user/shared_preferences/shared_pref.dart';

import '../models/project.dart';
import 'dashboard_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {

  var email;
  ProjectDetailsScreen({this.email});

  static final List<Project> _projects = [];

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<Animation<double>> _staggerAnimations = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  String _selectedSortOption = 'All';
  late Future<List<Project>> _projectsFuture;
  final _formKey = GlobalKey<FormState>();

  // Add this key for RefreshIndicator
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    // Initialize controllers first
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create animations with clamped values
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
          ),
        );

    _scrollController.addListener(_onScroll);

    // Start animations after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
      _pulseController.repeat(reverse: true);
    });

    _projectsFuture = getProjects();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Project> _filteredProjects(List<Project> projects) {
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      projects = projects.where((project) {
        return project.name.toLowerCase().contains(query) ||
            project.description.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedSortOption == "All") {
      return projects; // show all
    }

    final filter = _selectedSortOption.trim().toLowerCase();

    return projects.where((p) {
      return p.status.trim().toLowerCase() == filter;
    }).toList();
  }

  // Safe opacity getter that clamps values between 0 and 1
  double _getSafeOpacity(Animation<double> animation) {
    return animation.value.clamp(0.0, 1.0);
  }

  // Safe scale getter that prevents invalid values
  double _getSafeScale(Animation<double> animation) {
    return animation.value.clamp(
      0.01,
      1.0,
    ); // Minimum scale of 0.01 to avoid invisible elements
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _filteredProjects;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 768;
    final appBarHeight = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: AnimatedOpacity(
          opacity: _scrollOffset > 100 ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: const Text(
            'Projects',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        backgroundColor: _scrollOffset > 100
            ? Colors.white.withOpacity(0.95)
            : Colors.transparent,
        elevation: _scrollOffset > 100 ? 4 : 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: _scrollOffset > 100
                ? null
                : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1976D2), Color(0xFF7B1FA2)],
            ),
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard, color: Colors.white),
            onPressed: _navigateToDashboard,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.white),
            onPressed: _navigateToLoginScreen,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          setState(() {
            _projectsFuture = getProjects();
          });
          await _projectsFuture;
        },
        // Use BouncingScrollPhysics for iOS-like behavior or ClampingScrollPhysics for Android
        notificationPredicate: (notification) {
          // Only enable refresh when at the top of the scroll view
          return _scrollController.positions.first.pixels == 0;
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Hero Section
            SliverToBoxAdapter(
              child: Container(
                height: 320,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1976D2), Color(0xFF7B1FA2)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Stack(
                  children: [
                    // Background Pattern
                    _buildBackgroundPattern(),

                    // Content
                    Padding(
                      padding: EdgeInsets.only(
                        top: appBarHeight + 20,
                        left: 24,
                        right: 24,
                        bottom: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Project Portfolio',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Manage and track all your projects in one place',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Search Bar
                          SlideTransition(
                            position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.5),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: const Interval(
                                  0.5,
                                  1,
                                  curve: Curves.easeOut,
                                ),
                              ),
                            ),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) =>
                                      setState(() => _searchQuery = value),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Search projects...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Projects Count
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: FutureBuilder<List<Project>>(
                  future: _projectsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No projects found'));
                    }

                    final projects = _filteredProjects(snapshot.data!);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${projects.length} Projects',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Sorted by: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSortOption,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  size: 20,
                                  color: Colors.black87,
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'All',
                                    child: Text('All'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'pending',
                                    child: Text('Pending'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'continue',
                                    child: Text('Continue'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'On Hold',
                                    child: Text('On Hold'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'complete',
                                    child: Text('Complete'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedSortOption = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Projects Grid/List
            isWideScreen ? _buildWideScreenGrid() : _buildMobileList(),

            SliverToBoxAdapter(child: const SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned(
      right: -50,
      top: -50,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Colors.white.withOpacity(0.1), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildWideScreenGrid() {
    return FutureBuilder<List<Project>>(
      future: _projectsFuture,
      builder: (BuildContext context, AsyncSnapshot<List<Project>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Container(
              height: 200,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Container(
              height: 200,
              child: Center(child: Text('Error: ${snapshot.error}')),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(child: Text('No projects found')),
          );
        }

        final projects = snapshot.data!;
        final filteredProjects = _filteredProjects(projects);

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.6,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final project = filteredProjects[index];

              return _buildProjectCard(project, index);
            }, childCount: filteredProjects.length),
          ),
        );
      },
    );
  }

  Widget _buildMobileList() {
    return FutureBuilder<List<Project>>(
      future: _projectsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Container(
              height: 200,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Container(
              height: 200,
              child: Center(child: Text('Error: ${snapshot.error}')),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              height: 200,
              child: const Center(child: Text('No projects found')),
            ),
          );
        }

        final projects = snapshot.data!;
        final filteredProjects = _filteredProjects(projects);

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final project = filteredProjects[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: _buildProjectCard(project, index),
            );
          }, childCount: filteredProjects.length),
        );
      },
    );
  }

  Widget _buildProjectCard(Project project, int index) {
    final statusColor = _getStatusColor(project.status);
    final daysRemaining = project.endDate.difference(DateTime.now()).inDays;

    // Safe check for stagger animations - if animations aren't ready, show static card
    if (_staggerAnimations.isEmpty || index >= _staggerAnimations.length) {
      return _buildStaticProjectCard(project, statusColor, daysRemaining);
    }

    final animationIndex = index % _staggerAnimations.length;

    return AnimatedBuilder(
      animation: _staggerAnimations[animationIndex],
      builder: (context, child) {
        final safeOpacity = _getSafeOpacity(_staggerAnimations[animationIndex]);
        final safeScale = _getSafeScale(_staggerAnimations[animationIndex]);

        return Opacity(
          opacity: safeOpacity,
          child: Transform(
            transform: Matrix4.identity()
              ..scale(safeScale)
              ..translate(0.0, 100 * (1 - safeOpacity)),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      child: _buildStaticProjectCard(project, statusColor, daysRemaining),
    );
  }

  Widget _buildStaticProjectCard(
      Project project,
      Color statusColor,
      int daysRemaining,
      ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onCardTap(project.id),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Status Indicator Bar - This will now show the correct color
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),

              // Main content with proper layout
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                project.type,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Dropdown area - This will show the correct status text and color
                        _buildStatusBadge(project),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      project.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 20),

                    // Footer - Removed progress section and added only members and timeline
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Members
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${project.members.length} members',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),

                        // Timeline
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$daysRemaining days left',
                              style: TextStyle(
                                fontSize: 12,
                                color: daysRemaining < 7
                                    ? const Color(0xFFF57C00)
                                    : Colors.grey.shade600,
                                fontWeight: daysRemaining < 7
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Project project) {
    final color = _getStatusColor(project.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'On Hold') {
            String? reason = await _showOnHoldReasonDialog();
            if (reason != null && reason.isNotEmpty) {
              await _updateProjectStatus(project.id, value, reason: reason);
            }
          } else {
            await _updateProjectStatus(project.id, value);
          }
        },

        itemBuilder: (context) => const [
          PopupMenuItem(value: 'pending', child: Text('Pending')),
          PopupMenuItem(value: 'continue', child: Text('Continue')),
          PopupMenuItem(value: 'On Hold', child: Text('On Hold')),
          PopupMenuItem(value: 'complete', child: Text('Complete')),
        ],
        child: Row(
          children: [
            Text(
              _getStatusDisplayText(project.status),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 18, color: Colors.black87),
          ],
        ),
      ),
    );
  }

  String _getStatusDisplayText(String status) {
    status = status.trim().toLowerCase();
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'continue':
        return 'Continue';
      case 'on hold':
        return 'On Hold';
      case 'complete':
        return 'Complete';
      case 'approved':
        return 'Approved';
      default:
        return status;
    }
  }

  Future<void> _updateProjectStatus(String projectId, String status, {String? reason}) async {
    var url = Uri.parse(
      "https://prakrutitech.xyz/batch_project/update_project_status.php",
    );

    var body = {
      'id': projectId,
      'status': status,
    };

    if (reason != null) {
      body['reason_for_hold'] = reason;

    }

    var response = await http.post(url, body: body);

    if (response.statusCode == 200) {
      print("Status updatedddddddd: ${response.body}");
      setState(() {
        _projectsFuture = getProjects();
      });
    } else {
      print("Failed to update status");
    }
  }

  void _onCardTap(String projectId) {
    HapticFeedback.lightImpact();
    _navigateToProjectDetail(projectId);
  }

  void _navigateToDashboard() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToProjectDetail(String projectId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Project Detail'),
        content: Text('Details for project $projectId'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToLoginScreen() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen(),));
    SharedPref.saveLoginStatus(false);
  }

  Color _getStatusColor(String status) {
    status = status.trim().toLowerCase();
    switch (status) {
      case 'pending':
        return const Color(0xFFF57C00);
      case 'continue':
        return const Color(0xFF1976D2);
      case 'on hold':
        return const Color(0xFFD000FF);
      case 'complete':
        return const Color(0xFF388E3C);
      default:
        return Colors.grey;
    }
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

      setState(() {
        _staggerAnimations = List.generate(
          projects.length,
              (index) => Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                0.2 + (0.15 * index),
                1.0,
                curve: Curves.elasticOut,
              ),
            ),
          ),
        );
      });

      final filteredProjects = projects.where((project) {
        return project.members_email.contains("${widget.email}");
      }).toList();

      print("Filtered projects count: ${filteredProjects.length}");

      return filteredProjects;
    } else {
      print("Get project api not working!!");
      return [];
    }
  }

  Future<String?> _showOnHoldReasonDialog() async {
    TextEditingController reasonController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reason for On Hold"),
          content: Form(
            key: _formKey,
            child: TextFormField(
                validator: (val) {
                  if (val!.isEmpty) {
                    return "Please Enter Your Reason";
                  }
                  return null;
                },
              controller: reasonController,
              decoration: InputDecoration(hintText: "Enter reason..."),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if(_formKey.currentState!.validate()){
                  String reason=reasonController.text.toString();
                  if(reason.isEmpty){
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Please Enter Reason")));
                  }else{
                    Navigator.pop(context, reasonController.text.trim());
                  }
                }
                },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}