import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../widgets/radial_arc_menu.dart';
import 'vriyda_login_screen.dart';

/// Comprehensive Chairman Dashboard matching Stitch code.html and DESIGN.md:
/// - Brand Header with "VRIYDA PORTAL", Live status, School Name, Executive View, Action Badges
/// - Horizontal Nav Tabs (8 Core Views: Overview, Branch Tree, Users, Student 360, Finance & Fees, Growth, Academics, Operations)
/// - Rotating 4-Card Circular Carousel with auto-transition / pager dots
/// - Branch Performance ranking list with collection progress bars
/// - Exception-first Critical Alerts & Needs Attention cards
/// - Floating Radial Arc Rotary Menu (Swipe to rotate, glowing orbital buttons, quick navigation)
class ChairmanDashboardScreen extends StatefulWidget {
  final UserSession user;
  const ChairmanDashboardScreen({super.key, required this.user});

  @override
  State<ChairmanDashboardScreen> createState() =>
      _ChairmanDashboardScreenState();
}

class _ChairmanDashboardScreenState extends State<ChairmanDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;
  String _activeView = 'view-overview';
  bool _isArcMenuOpen = false;

  // Interactive state for Group Overview
  int _activeKpiSet = 0;
  Timer? _kpiTimer;
  late final PageController _kpiPageController;
  final Set<String> _approvedItemIds = {};
  final Set<String> _acknowledgedAlertIds = {};

  // Interactive state for Attendance Audit
  String _attendancePrimaryTab = 'students'; // 'students' | 'staff'
  DateTime _selectedAttendanceDate = DateTime(2026, 11, 13);
  String _studentResidencyFilter =
      'all-students'; // 'all-students' | 'hostel-residents' | 'day-scholars'
  String _staffRoleFilter =
      'all-staff'; // 'all-staff' | 'teaching' | 'non-teaching'
  String _staffSubFilter = 'all-nt';
  String _selectedBranchFilter =
      'all'; // 'all' or branch id ('steel-plant', 'gachibowli', etc.)
  String _selectedClassFilter = 'all'; // 'all' or class name ('Class 10', etc.)
  String _selectedSectionFilter =
      'all'; // 'all' or section name ('Sec A', 'Sec B')
  String _selectedDeptFilter = 'all'; // 'all' or dept name ('Physics', etc.)
  String _selectedShiftFilter = 'general'; // 'general' | 'morning' | 'evening'
  final Set<String> _expandedBranchIds = {'steel-plant'};
  String _rosterFilterPill =
      'all'; // 'all' | 'not-marked' | 'present' | 'absentees' | 'teaching' | 'non-teaching' | 'leave' | 'absent'
  String _attendanceSearchQuery = '';

  static final List<Map<String, dynamic>> _attendanceStudentRecords = [
    {
      'initials': 'AK',
      'name': 'Aadhya K.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'hostel-residents',
      'status': 'Not marked',
      'rollNo': 'KP-10-01',
      'meta': 'Class 10 • Sec A • Kukatpally',
    },
    {
      'initials': 'AK',
      'name': 'Aadhya Kumar',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KD-10-04',
      'meta': 'Class 10 • Sec A • Kondapur',
    },
    {
      'initials': 'AK',
      'name': 'Aarav Kumar',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'class': 'Class 2',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MD-02-02',
      'meta': 'Class 2 • Sec A • Maddipalem',
    },
    {
      'initials': 'AP',
      'name': 'Aarav Patel',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 6',
      'section': 'Sec A',
      'residency': 'hostel-residents',
      'status': 'Not marked',
      'rollNo': 'GB-06-08',
      'meta': 'Class 6 • Sec A • Gachibowli',
    },
    {
      'initials': 'AS',
      'name': 'Aarav Sharma',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-10-12',
      'meta': 'Class 10 • Sec A • Steel Plant',
    },
    {
      'initials': 'VN',
      'name': 'Varun Nambiar',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 10',
      'section': 'Sec B',
      'residency': 'hostel-residents',
      'status': 'Not marked',
      'rollNo': 'SP-10-24',
      'meta': 'Class 10 • Sec B • Steel Plant',
    },
    {
      'initials': 'SR',
      'name': 'Sanya Reddy',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 9',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-09-05',
      'meta': 'Class 9 • Sec A • Steel Plant',
    },
    {
      'initials': 'RK',
      'name': 'Rohan Kulkarni',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 5',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-05-03',
      'meta': 'Class 5 • Sec A • Steel Plant',
    },
    {
      'initials': 'DR',
      'name': 'Diya Rao',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 2',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-02-11',
      'meta': 'Class 2 • Sec A • Gachibowli',
    },
    {
      'initials': 'NM',
      'name': 'Nikhil Menon',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'class': 'Class 1',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MD-01-07',
      'meta': 'Class 1 • Sec A • Maddipalem',
    },
    {
      'initials': 'PA',
      'name': 'Pranav Anand',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 8',
      'section': 'Sec A',
      'residency': 'hostel-residents',
      'status': 'Not marked',
      'rollNo': 'KP-08-14',
      'meta': 'Class 8 • Sec A • Kukatpally',
    },
    {
      'initials': 'KV',
      'name': 'Kavya Varma',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'class': 'Class 7',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KD-07-09',
      'meta': 'Class 7 • Sec A • Kondapur',
    },
    {
      'initials': 'IS',
      'name': 'Ishaan Sen',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'hostel-residents',
      'status': 'Not marked',
      'rollNo': 'MP-10-02',
      'meta': 'Class 10 • Sec A • Madhapur',
    },
    {
      'initials': 'MG',
      'name': 'Meera Gupta',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 9',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-09-08',
      'meta': 'Class 9 • Sec A • Madhapur',
    },
  ];

  static final List<Map<String, dynamic>> _attendanceStaffRecords = [
    {
      'initials': 'KR',
      'name': 'Dr. K. S. Rao',
      'role': 'PGT Physics • Steel Plant',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Physics',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:42 AM',
      'phone': '+91 98490 12345',
    },
    {
      'initials': 'MA',
      'name': 'M. Ananya',
      'role': 'TGT English • Gachibowli',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'department': 'English',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:48 AM',
      'phone': '+91 94401 56789',
    },
    {
      'initials': 'RK',
      'name': 'Rajesh Kumar',
      'role': 'Transport Mgr • Steel Plant',
      'category': 'non-teaching',
      'subRole': 'transport-mgr',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Transport',
      'shift': 'morning',
      'status': 'Present',
      'subStatus': '08:15 AM',
      'phone': '+91 98852 44321',
    },
    {
      'initials': 'SV',
      'name': 'S. Venkat',
      'role': 'Admin Officer • Maddipalem',
      'category': 'non-teaching',
      'subRole': 'account-mgr',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:35 AM',
      'phone': '+91 91212 99011',
    },
    {
      'initials': 'LD',
      'name': 'Lakshmi Devi',
      'role': 'Librarian • Kondapur',
      'category': 'non-teaching',
      'subRole': 'librarian',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'department': 'Library',
      'shift': 'general',
      'status': 'On Leave',
      'subStatus': 'Casual',
      'phone': '+91 97000 88214',
    },
    {
      'initials': 'SB',
      'name': 'Suresh Babu',
      'role': 'Bus Attendant • Kukatpally',
      'category': 'non-teaching',
      'subRole': 'bus-attendant',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'department': 'Transport',
      'shift': 'morning',
      'status': 'Absent',
      'subStatus': 'Uninformed',
      'phone': '+91 93910 33412',
    },
    {
      'initials': 'HW',
      'name': 'Harish Warrier',
      'role': 'Hostel Warden • Gachibowli',
      'category': 'non-teaching',
      'subRole': 'hostel-warden',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'department': 'Administration',
      'shift': 'evening',
      'status': 'Present',
      'subStatus': '07:50 AM',
      'phone': '+91 98480 33221',
    },
    {
      'initials': 'RP',
      'name': 'Ritu Priya',
      'role': 'Receptionist • Madhapur',
      'category': 'non-teaching',
      'subRole': 'receptionist',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:40 AM',
      'phone': '+91 99887 66554',
    },
    {
      'initials': 'PS',
      'name': 'P. Sreenivas',
      'role': 'PGT Mathematics • Kukatpally',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'department': 'Physics',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:25 AM',
      'phone': '+91 94411 22334',
    },
    {
      'initials': 'GS',
      'name': 'Geetha Sharma',
      'role': 'Primary Teacher • Maddipalem',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'department': 'English',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:30 AM',
      'phone': '+91 98844 55667',
    },
    {
      'initials': 'AN',
      'name': 'Anil Nair',
      'role': 'Facilities Incharge • Steel Plant',
      'category': 'non-teaching',
      'subRole': 'bus-attendant',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Facilities & Security',
      'shift': 'morning',
      'status': 'Absent',
      'subStatus': 'Sick Leave',
      'phone': '+91 91234 56780',
    },
    {
      'initials': 'SK',
      'name': 'Sunita Krishnan',
      'role': 'Secondary Faculty • Kondapur',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'department': 'English',
      'shift': 'general',
      'status': 'On Leave',
      'subStatus': 'Half Day',
      'phone': '+91 97766 55443',
    },
  ];

  @override
  void initState() {
    super.initState();
    _kpiPageController = PageController(initialPage: _activeKpiSet);
    _fetchDashboard();
    _startKpiTimer();
  }

  @override
  void dispose() {
    _kpiTimer?.cancel();
    _kpiPageController.dispose();
    super.dispose();
  }

  void _startKpiTimer() {
    _kpiTimer?.cancel();
    _kpiTimer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (!mounted) return;
      final nextSet = (_activeKpiSet + 1) % 3;
      if (_kpiPageController.hasClients) {
        _kpiPageController.animateToPage(
          nextSet,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _selectKpiSet(int index) {
    HapticFeedback.selectionClick();
    if (_kpiPageController.hasClients) {
      _kpiPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
    _startKpiTimer();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = await SessionManager.getToken();

    if (token != null && token != 'demo-chairman-token') {
      try {
        final res = await http.get(
          Uri.parse(ApiConfig.ownerDashboard),
          headers: ApiConfig.authHeaders(token),
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (mounted) {
            setState(() {
              _dashboardData = body is Map<String, dynamic> ? body : null;
              _isLoading = false;
            });
          }
          return;
        } else if (res.statusCode == 401) {
          final refreshed = await AuthService.refreshToken();
          if (refreshed) {
            final newToken = await SessionManager.getToken();
            if (newToken != null) {
              final retryRes = await http.get(
                Uri.parse(ApiConfig.ownerDashboard),
                headers: ApiConfig.authHeaders(newToken),
              );
              if (retryRes.statusCode == 200) {
                final body = jsonDecode(retryRes.body);
                if (mounted) {
                  setState(() {
                    _dashboardData = body is Map<String, dynamic> ? body : null;
                    _isLoading = false;
                  });
                }
                return;
              }
            }
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLogout() async {
    await SessionManager.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const VriydaLoginScreen()),
      (route) => false,
    );
  }

  void _switchView(String viewId) {
    HapticFeedback.selectionClick();
    setState(() {
      _activeView = viewId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orgName =
        _dashboardData?['orgName'] ??
        widget.user.organizationName ??
        'Sai Ravindra School';
    final group = _dashboardData?['group'] as Map<String, dynamic>?;
    final branches = _dashboardData?['branches'] as List<dynamic>? ?? [];
    final alerts = _dashboardData?['alerts'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(
        0xFFF6F8FC,
      ), // Crisp SaaS Canvas from DESIGN.md
      body: SafeArea(
        child: Stack(
          children: [
            // Main Scrollable Body
            RefreshIndicator(
              onRefresh: _fetchDashboard,
              color: const Color(0xFF7C3AED),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
                children: [
                  // 1. App Header
                  _buildHeader(orgName),

                  const SizedBox(height: 12),

                  // 2. Horizontal Navigation Tabs
                  _buildNavTabs(),

                  const SizedBox(height: 14),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    )
                  else if (_errorMessage != null)
                    _buildErrorCard()
                  else
                    _buildActiveViewContent(group, branches, alerts),
                ],
              ),
            ),

            // 3. Radial Arc Wheel Menu Layer (Overlay & Trigger FAB)
            Positioned.fill(
              child: RadialArcMenu(
                isOpen: _isArcMenuOpen,
                onToggle: () {
                  setState(() => _isArcMenuOpen = !_isArcMenuOpen);
                },
                onItemSelected: (selectedId) {
                  _switchView(selectedId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Header Component ---
  Widget _buildHeader(String orgName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'VRIYDA PORTAL',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Live',
                style: TextStyle(
                  color: Color(0xFF065F46),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF630ED4)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF7C3AED,
                          ).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'V',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orgName,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Chairman Portal · Executive View',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderIconBtn(
                  Icons.refresh_rounded,
                  const Color(0xFFF59E0B),
                  _fetchDashboard,
                ),
                const SizedBox(width: 6),
                _buildHeaderIconBtn(
                  Icons.notifications_outlined,
                  const Color(0xFFF43F5E),
                  () {},
                ),
                const SizedBox(width: 6),
                _buildUserAvatar(),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.user.name.isNotEmpty ? widget.user.name : 'Chairman',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user.email,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Log out',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleLogout();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'C',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  // --- Horizontal Nav Tabs ---
  Widget _buildNavTabs() {
    final tabs = [
      {
        'id': 'view-overview',
        'label': 'Overview',
        'icon': Icons.dashboard_outlined,
      },
      {
        'id': 'view-branches',
        'label': 'Branch Tree',
        'icon': Icons.account_tree_outlined,
      },
      {'id': 'view-users', 'label': 'Users', 'icon': Icons.people_outline},
      {
        'id': 'view-attendance',
        'label': 'Attendance',
        'icon': Icons.fact_check_outlined,
      },
      {
        'id': 'view-lookup',
        'label': 'Student Lookup',
        'icon': Icons.search_rounded,
      },
      {
        'id': 'view-finance',
        'label': 'Finance & Fees',
        'icon': Icons.account_balance_wallet_outlined,
      },
      {
        'id': 'view-growth',
        'label': 'Growth & Admissions',
        'icon': Icons.trending_up_rounded,
      },
      {
        'id': 'view-academics',
        'label': 'Academics',
        'icon': Icons.school_outlined,
      },
      {
        'id': 'view-operations',
        'label': 'Operations',
        'icon': Icons.business_center_outlined,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tabs.map((t) {
          final isSelected = _activeView == t['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => _switchView(t['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF7C3AED,
                            ).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 5),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34D399),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- View Switcher ---
  Widget _buildActiveViewContent(
    Map<String, dynamic>? group,
    List<dynamic> branches,
    List<dynamic> alerts,
  ) {
    switch (_activeView) {
      case 'view-branches':
        return _buildBranchTreeView(branches);
      case 'view-lookup':
        return _buildStudentLookupView();
      case 'view-finance':
        return _buildFinanceFeesView(group);
      case 'view-growth':
        return _buildGrowthView();
      case 'view-academics':
        return _buildAcademicsView();
      case 'view-operations':
        return _buildOperationsView();
      case 'view-classes':
        return _buildClassesView();
      case 'view-attendance':
        return _buildAttendanceView();
      case 'view-lessons':
        return _buildLessonPlansView();
      case 'view-timetable':
        return _buildTimetableView();
      case 'view-ai':
        return _buildAiInsightsView();
      case 'view-transport':
        return _buildTransportView();
      case 'view-comm':
        return _buildNoticeBoardView();
      case 'view-exams':
        return _buildExamsMarksView();
      case 'view-users':
        return _buildUsersView();
      case 'view-overview':
      default:
        return _buildOverviewContent(group, branches, alerts);
    }
  }

  // --- 1. OVERVIEW CONTENT (Default) ---
  // --- 1. OVERVIEW CONTENT (Default - Matching code.html Group Overview) ---
  Widget _buildOverviewContent(
    Map<String, dynamic>? group,
    List<dynamic> branches,
    List<dynamic> alerts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header (code.html lines 127-138)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Group Overview',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Executive View · Live metrics',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.circle, color: Color(0xFF10B981), size: 6),
                  SizedBox(width: 5),
                  Text(
                    'Chairman',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 1. Dynamic 4-Card Rotating Circular KPI Stage (code.html lines 140-245)
        _buildRotatingCircularKpiStage(group),

        const SizedBox(height: 14),

        // 2. Financial Performance Area Chart & Aging (code.html lines 246-354)
        _buildFinancialPerformanceCard(group),

        const SizedBox(height: 14),

        // 3. Branch Performance Benchmark Quick Widget (code.html lines 355-395)
        _buildBranchBenchmarkQuickWidget(),

        const SizedBox(height: 14),

        // 4. Performance Quadrant Card (code.html lines 396-485)
        _buildPerformanceQuadrantCard(branches),

        const SizedBox(height: 14),

        // 5. Branch Comparison Progress Bars Card (code.html lines 486-588)
        _buildBranchComparisonHealthCard(branches),

        const SizedBox(height: 14),

        // 6. Needs Your Attention Section (code.html lines 589-798)
        _buildNeedsYourAttentionSection(alerts),
      ],
    );
  }

  // ===========================================================================
  // SECTION 1: Dynamic 4-Card Rotating Circular KPI Stage (code.html lines 140-245)
  // Covers KPIs: Active Students, YTD Revenue, Fee Collection %, Student Attendance,
  // Capacity Used, Critical Alerts, Staff Attendance
  // ===========================================================================
  Widget _buildRotatingCircularKpiStage(Map<String, dynamic>? group) {
    // Dynamic values from backend if present, fallback to exact web reference screen values
    final students = group?['students'] ?? 122;
    final ytdRevenue = group?['revenue'] ?? '₹1.4 Cr';
    final collectionPct = group?['collectionPct'] ?? 68.2;
    final studentAttendance = group?['studentAttendanceRatio'] ?? '22/122';
    final cashToday = group?['cashCollectedToday'] ?? '₹0.2 L';
    final newAdmissions = group?['newAdmissions'] ?? 25;
    final staffFilled = group?['staffCount'] ?? 46;
    final studentAttrition = group?['attrition'] ?? 4.9;
    final operatingMargin = group?['ebitdaMargin'] ?? 36.7;
    final staffAttendance = group?['staffAttendanceRatio'] ?? '0/46';
    final outstanding = group?['outstandingFees'] ?? '₹45.0 L';
    final criticalAlerts = group?['alertsCritical'] ?? 4;

    final categories = ['Core Performance', 'Cash & Staffing', 'Operations & Margins'];
    final categoryName = categories[_activeKpiSet];

    // 3 sets × 4 cards = 12 metrics matching exact web reference screen
    final List<List<Map<String, dynamic>>> sets = [
      // SET 1: Core Performance
      [
        {
          'label': 'Active Students',
          'value': '$students',
          'badge': '+11.9%',
          'badgeColor': const Color(0xFF059669),
          'badgeBg': const Color(0xFFECFDF5),
          'valColor': const Color(0xFF0F172A),
        },
        {
          'label': 'YTD Revenue',
          'value': '$ytdRevenue',
          'badge': '+0%',
          'badgeColor': const Color(0xFF7C3AED),
          'badgeBg': const Color(0xFFFAF5FF),
          'valColor': const Color(0xFF7C3AED),
        },
        {
          'label': 'Fees Collected',
          'value': '$collectionPct%',
          'badge': '-19.8 pts',
          'badgeColor': const Color(0xFFE11D48),
          'badgeBg': const Color(0xFFFFE4E6),
          'valColor': const Color(0xFF0F172A),
        },
        {
          'label': 'Student Attend',
          'value': '$studentAttendance',
          'badge': '18.0%',
          'badgeColor': const Color(0xFF64748B),
          'badgeBg': const Color(0xFFF1F5F9),
          'valColor': const Color(0xFF0F172A),
        },
      ],
      // SET 2: Cash & Staffing
      [
        {
          'label': 'Cash Today',
          'value': '$cashToday',
          'badge': 'Counters',
          'badgeColor': const Color(0xFF059669),
          'badgeBg': const Color(0xFFECFDF5),
          'valColor': const Color(0xFF059669),
        },
        {
          'label': 'New Admissions',
          'value': '$newAdmissions',
          'badge': 'This Month',
          'badgeColor': const Color(0xFF7C3AED),
          'badgeBg': const Color(0xFFFAF5FF),
          'valColor': const Color(0xFF7C3AED),
        },
        {
          'label': 'Staff Filled',
          'value': '$staffFilled',
          'badge': '23 Open',
          'badgeColor': const Color(0xFFD97706),
          'badgeBg': const Color(0xFFFFFBEB),
          'valColor': const Color(0xFF0F172A),
        },
        {
          'label': 'Student Attrition',
          'value': '$studentAttrition%',
          'badge': '-1.1 pts',
          'badgeColor': const Color(0xFF059669),
          'badgeBg': const Color(0xFFECFDF5),
          'valColor': const Color(0xFF059669),
        },
      ],
      // SET 3: Operations & Margins
      [
        {
          'label': 'Operating Margin',
          'value': '$operatingMargin%',
          'badge': 'EBITDA',
          'badgeColor': const Color(0xFF059669),
          'badgeBg': const Color(0xFFECFDF5),
          'valColor': const Color(0xFF7C3AED),
        },
        {
          'label': 'Staff Attend',
          'value': '$staffAttendance',
          'badge': '0 Absent',
          'badgeColor': const Color(0xFFE11D48),
          'badgeBg': const Color(0xFFFFE4E6),
          'valColor': const Color(0xFFE11D48),
        },
        {
          'label': 'Outstanding Fees',
          'value': '$outstanding',
          'badge': 'Due',
          'badgeColor': const Color(0xFFD97706),
          'badgeBg': const Color(0xFFFFFBEB),
          'valColor': const Color(0xFFD97706),
        },
        {
          'label': 'Critical Alerts',
          'value': '$criticalAlerts Crit',
          'badge': 'Action',
          'badgeColor': const Color(0xFFE11D48),
          'badgeBg': const Color(0xFFFFE4E6),
          'valColor': const Color(0xFFE11D48),
        },
      ],
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x99FAF5FF), Colors.white, Color(0xB2F8FAFC)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xE5EDE9FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pager Header & Set Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    categoryName.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEDE9FE)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Row(
                      children: List.generate(3, (idx) {
                        final isSel = idx == _activeKpiSet;
                        return GestureDetector(
                          onTap: () => _selectKpiSet(idx),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: isSel ? 9 : 7,
                            height: isSel ? 9 : 7,
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF7C3AED)
                                  : const Color(0xFFDDD6FE),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 1,
                      height: 10,
                      color: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_activeKpiSet + 1} / 3',
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Horizontal Sliding Carousel for the 3 KPI Sets (Core Performance, Growth & People, Operations & Attendance)
          // Slides automatically horizontally every 4s AND allows user to manually swipe/slide smoothly
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final itemWidth = availableWidth / 4;
              final circleSize = (itemWidth - 10).clamp(58.0, 68.0);
              final numFontSize = circleSize >= 64 ? 15.5 : 14.0;
              final badgeFontSize = circleSize >= 64 ? 8.5 : 7.5;

              return SizedBox(
                height: circleSize + 28,
                child: PageView.builder(
                  controller: _kpiPageController,
                  physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
                  onPageChanged: (idx) {
                    setState(() {
                      _activeKpiSet = idx;
                    });
                    _startKpiTimer();
                  },
                  itemCount: sets.length,
                  itemBuilder: (context, setIndex) {
                    final cards = sets[setIndex];
                    return Row(
                      children: cards.map((c) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Circular card containing prominent numbers and badge
                                Container(
                                  width: circleSize,
                                  height: circleSize,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xCCEDE9FE),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7C3AED).withValues(alpha: 0.16),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Increased font size for inside numbers with auto-scaling for ratios
                                      Builder(builder: (context) {
                                        final valStr = c['value'] as String;
                                        final dynamicNumFontSize = valStr.length > 5
                                            ? (circleSize >= 64 ? 13.0 : 12.0)
                                            : numFontSize;
                                        return Text(
                                          valStr,
                                          style: TextStyle(
                                            color: c['valColor'] as Color,
                                            fontSize: dynamicNumFontSize,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.4,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      }),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: c['badgeBg'] as Color,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: (c['badgeColor'] as Color).withValues(alpha: 0.2),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          c['badge'] as String,
                                          style: TextStyle(
                                            color: c['badgeColor'] as Color,
                                            fontSize: badgeFontSize,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Text label displayed underneath against each circle
                                Text(
                                  c['label'] as String,
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // Timed Progress Indicator Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3.5,
              child: LinearProgressIndicator(
                value: (_activeKpiSet + 1) / 3.0,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF7C3AED),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 2: Financial Performance Area Chart & Aging (code.html lines 246-354)
  // Covers Feature: Revenue vs Operating Expenses (trend)
  // ===========================================================================
  Widget _buildFinancialPerformanceCard(Map<String, dynamic>? group) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Financial Performance',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5FF),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFEDE9FE)),
                          ),
                          child: const Text(
                            'FY 2024–25',
                            style: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Revenue vs Operating Expenses & Fee Realization',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.circle, color: Color(0xFF10B981), size: 5),
                        SizedBox(width: 4),
                        Text(
                          'EBITDA ₹4.0 L (32%)',
                          style: TextStyle(
                            color: Color(0xFF065F46),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Operating Strong',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Revenue vs OpEx Chart (Cash Trajectory)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CASH TRAJECTORY (₹ LAKHS)',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Revenue',
                              style: TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 2,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF43F5E),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'OpEx',
                              style: TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: CustomPaint(painter: CashTrajectoryPainter()),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Apr',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Jun',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Aug',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Oct',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Dec',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Feb',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Mar',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Fee Realization Ring
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x80FAF5FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEDE9FE)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(76, 76),
                        painter: FeeRealizationRingPainter(
                          collectedPct: 67.6,
                          duePct: 18.9,
                          overduePct: 13.5,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            '67.6%',
                            style: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'REALIZED',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7C3AED),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Collected',
                                style: TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            '₹94.5 L',
                            style: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Due Current',
                                style: TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            '₹26.4 L',
                            style: TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF43F5E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Overdue',
                                style: TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            '₹19.1 L',
                            style: TextStyle(
                              color: Color(0xFFE11D48),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Receivables Aging
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'RECEIVABLES AGING',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                '₹45.5 L Total',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildAgingBox(
                '0–30 D',
                '₹18.7 L',
                '41.1%',
                const Color(0xFF059669),
                const Color(0xFFF8FAFC),
              ),
              const SizedBox(width: 6),
              _buildAgingBox(
                '31–60 D',
                '₹12.3 L',
                '27.0%',
                const Color(0xFFD97706),
                const Color(0xFFF8FAFC),
              ),
              const SizedBox(width: 6),
              _buildAgingBox(
                '61–90 D',
                '₹8.7 L',
                '19.1%',
                const Color(0xFFE11D48),
                const Color(0xFFF8FAFC),
              ),
              const SizedBox(width: 6),
              _buildAgingBox(
                '90+ D',
                '₹5.9 L',
                '12.8%',
                const Color(0xFFBE123C),
                const Color(0xFFFFF1F2),
                borderColor: const Color(0xFFFECDD3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgingBox(
    String period,
    String amount,
    String pct,
    Color accentColor,
    Color bg, {
    Color? borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor ?? const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              period,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              pct,
              style: TextStyle(
                color: accentColor,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 3: Branch Performance Benchmark Quick Widget (code.html lines 355-395)
  // ===========================================================================
  Widget _buildBranchBenchmarkQuickWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Branch Performance Benchmark',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              GestureDetector(
                onTap: () => _switchView('view-branches'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEDE9FE)),
                  ),
                  child: const Text(
                    'All 9 Branches →',
                    style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Top 3 branches
          _buildQuickBenchmarkItem(
            name: 'Steel Plant Branch',
            sub: '42 Students · 10 Faculty · ₹38.2 L Rev',
            score: '94.2%',
            rank: 'Rank #1',
            isTop: true,
          ),
          const SizedBox(height: 6),
          _buildQuickBenchmarkItem(
            name: 'Gachibowli Campus',
            sub: '38 Students · 8 Faculty · ₹34.5 L Rev',
            score: '91.8%',
            rank: 'Rank #2',
            isTop: false,
          ),
          const SizedBox(height: 6),
          _buildQuickBenchmarkItem(
            name: 'Kondapur Branch',
            sub: '24 Students · 6 Faculty · ₹22.1 L Rev',
            score: '88.4%',
            rank: 'Rank #3',
            isTop: false,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBenchmarkItem({
    required String name,
    required String sub,
    required String score,
    required String rank,
    required bool isTop,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isTop ? const Color(0x99FAF5FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop ? const Color(0xFFEDE9FE) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                sub,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: TextStyle(
                  color: isTop
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF1E293B),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                rank,
                style: TextStyle(
                  color: isTop
                      ? const Color(0xFF059669)
                      : const Color(0xFF64748B),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 4: Performance Quadrant Card (code.html lines 396-485)
  // Covers Feature: Performance quadrant (branch benchmarking)
  // ===========================================================================
  Widget _buildPerformanceQuadrantCard(List<dynamic> branches) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Performance quadrant',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Collection × attendance · bubble = enrolment',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFEDE9FE)),
                ),
                child: const Text(
                  'Quadrant View',
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Scatter Plot Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Attendance ↑',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'TOP PERFORMERS ▲',
                      style: TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: CustomPaint(painter: PerformanceQuadrantPainter()),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'Fee collection rate →',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Interactive 3-Column Legend
          const Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _QuadrantLegendItem(
                color: Color(0xFF8B5CF6),
                label: 'Gachibowli Campus',
              ),
              _QuadrantLegendItem(color: Color(0xFF059669), label: 'KBHP'),
              _QuadrantLegendItem(
                color: Color(0xFF06B6D4),
                label: 'Kondapur Branch',
              ),
              _QuadrantLegendItem(
                color: Color(0xFFA855F7),
                label: 'Kukatpally Campus',
              ),
              _QuadrantLegendItem(color: Color(0xFFF59E0B), label: 'LB Nagar'),
              _QuadrantLegendItem(
                color: Color(0xFFEF4444),
                label: 'Maddipalem',
              ),
              _QuadrantLegendItem(
                color: Color(0xFFC084FC),
                label: 'Madhapur Branch',
              ),
              _QuadrantLegendItem(
                color: Color(0xFF7C3AED),
                label: 'QA Test Branch',
              ),
              _QuadrantLegendItem(
                color: Color(0xFF10B981),
                label: 'Steel Plant Branch',
              ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'bubble size = enrolment',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 5: Branch Comparison Progress Bars Card (code.html lines 486-588)
  // Covers Feature: Branch comparison (health-weighted)
  // ===========================================================================
  Widget _buildBranchComparisonHealthCard(List<dynamic> branches) {
    final branchesData = [
      {
        'name': 'Steel Plant Branch',
        'pct': 82,
        'rev': '₹25.0 L',
        'color': const Color(0xFF10B981),
      },
      {
        'name': 'Gachibowli Campus',
        'pct': 78,
        'rev': '₹27.3 L',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'name': 'Kondapur Branch',
        'pct': 78,
        'rev': '₹21.4 L',
        'color': const Color(0xFF06B6D4),
      },
      {
        'name': 'Kukatpally Campus',
        'pct': 76,
        'rev': '₹23.4 L',
        'color': const Color(0xFFA855F7),
      },
      {
        'name': 'Maddipalem',
        'pct': 75,
        'rev': '₹22.8 L',
        'color': const Color(0xFFEF4444),
      },
      {
        'name': 'Madhapur Branch',
        'pct': 73,
        'rev': '₹20.2 L',
        'color': const Color(0xFFC084FC),
      },
      {
        'name': 'KBHP',
        'pct': 52,
        'rev': '₹0.0 L',
        'color': const Color(0xFF059669),
      },
      {
        'name': 'LB Nagar',
        'pct': 52,
        'rev': '₹0.0 L',
        'color': const Color(0xFFF59E0B),
      },
      {
        'name': 'QA Test Branch 0708',
        'pct': 52,
        'rev': '₹0.0 L',
        'color': const Color(0xFF7C3AED),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Branch comparison',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Health-weighted · by branch',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Text(
                  'Ranked',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 9 Branch Comparison Bar Items
          ...branchesData.map((b) {
            final name = b['name'] as String;
            final pct = b['pct'] as int;
            final rev = b['rev'] as String;
            final color = b['color'] as Color;

            return Padding(
              padding: const EdgeInsets.only(bottom: 9.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$pct% · ',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: rev,
                              style: TextStyle(
                                color: color,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100.0,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 6: Needs Your Attention Section (code.html lines 589-798)
  // Covers Features: Critical alerts feed, Approvals queue, Admissions pipeline funnel
  // ===========================================================================
  Widget _buildNeedsYourAttentionSection(List<dynamic> alerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Needs your attention',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Exception-first — the platform surfaces what\'s off-trend',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Card 1: Critical Alerts (code.html lines 595-648)
        _buildCriticalAlertsFeedCard(alerts),

        const SizedBox(height: 12),

        // Card 2: Approvals Queue (code.html lines 649-735)
        _buildApprovalsQueueCard(),

        const SizedBox(height: 12),

        // Card 3: Admissions Pipeline (code.html lines 736-798)
        _buildAdmissionsFunnelCard(),
      ],
    );
  }

  // Card 1 Component: Critical alerts
  Widget _buildCriticalAlertsFeedCard(List<dynamic> alerts) {
    final alertItems = [
      {
        'id': 'alt-1',
        'tag': 'FINANCE',
        'time': '2h ago',
        'title': '₹13.2 L outstanding · 48% of billed',
        'branch': 'Gachibowli Campus',
        'isRose': true,
      },
      {
        'id': 'alt-2',
        'tag': 'FINANCE',
        'time': '2h ago',
        'title': '₹10.3 L outstanding · 45% of billed',
        'branch': 'Maddipalem',
        'isRose': true,
      },
      {
        'id': 'alt-3',
        'tag': 'COMPLAINT',
        'time': 'open',
        'title': 'Transport: Bus delay on Route 4',
        'branch': 'Kondapur Branch',
        'isRose': true,
      },
      {
        'id': 'alt-4',
        'tag': 'TRANSPORT',
        'time': 'recent',
        'title': 'Minor Accident: Minor Accident on 2026-05-19',
        'branch': 'Steel Plant Branch',
        'isRose': true,
      },
      {
        'id': 'alt-5',
        'tag': 'ATTENDANCE',
        'time': 'today',
        'title': 'Attendance 90.5% — below 91% target',
        'branch': 'Kondapur Branch',
        'isRose': false,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Critical alerts',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          const Text(
            'Safety, finance & compliance',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),

          const SizedBox(height: 12),

          ...alertItems.map((al) {
            final id = al['id'] as String;
            final isAck = _acknowledgedAlertIds.contains(id);
            final isRose = al['isRose'] as bool;
            final borderColor = isAck
                ? const Color(0xFFCBD5E1)
                : isRose
                ? const Color(0xFFF43F5E)
                : const Color(0xFF94A3B8);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: borderColor, width: 2.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isRose
                              ? const Color(0xFFFFF1F2)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          al['tag'] as String,
                          style: TextStyle(
                            color: isRose
                                ? const Color(0xFFE11D48)
                                : const Color(0xFF475569),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            isAck ? 'acknowledged' : al['time'] as String,
                            style: TextStyle(
                              color: isAck
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF94A3B8),
                              fontSize: 9,
                              fontWeight: isAck
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          if (!isAck) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _acknowledgedAlertIds.add(id));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF5FF),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFEDE9FE),
                                  ),
                                ),
                                child: const Text(
                                  'Acknowledge',
                                  style: TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    al['title'] as String,
                    style: TextStyle(
                      color: isAck
                          ? const Color(0xFF64748B)
                          : const Color(0xFF0F172A),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '↳ ${al['branch']}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Card 2 Component: Approvals queue
  Widget _buildApprovalsQueueCard() {
    final approvals = [
      {
        'id': 'apr-1',
        'title': 'Fee Waiver · Hardship fee waiver — 3 students',
        'meta': 'Gachibowli Campus · 154d waiting',
        'amount': '₹45,000',
      },
      {
        'id': 'apr-2',
        'title': 'Capex · New science lab fit-out',
        'meta': 'Gachibowli Campus · 154d waiting',
        'amount': '₹8.5 L',
      },
      {
        'id': 'apr-3',
        'title': 'Fee Waiver · Hardship fee waiver — 3 students',
        'meta': 'Kondapur Branch · 154d waiting',
        'amount': '₹45,000',
      },
      {
        'id': 'apr-4',
        'title': 'Hiring · 3 teaching posts to approve',
        'meta': 'Kondapur Branch · 154d waiting',
        'amount': '',
      },
      {
        'id': 'apr-5',
        'title': 'Fee Waiver · Hardship fee waiver — 2 students',
        'meta': '₹45,000',
        'amount': '',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Approvals queue',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          const Text(
            'Awaiting owner sign-off',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),

          const SizedBox(height: 12),

          ...approvals.map((ap) {
            final id = ap['id'] as String;
            final isApproved = _approvedItemIds.contains(id);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isApproved
                    ? const Color(0xFFF0FDF4)
                    : const Color(0x80F8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isApproved
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFF1F5F9),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isApproved
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isApproved
                          ? Icons.check_circle_rounded
                          : Icons.description_outlined,
                      color: isApproved
                          ? const Color(0xFF15803D)
                          : const Color(0xFF7C3AED),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ap['title'] as String,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          ap['meta'] as String,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ((ap['amount'] as String).isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      ap['amount'] as String,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (isApproved) {
                          _approvedItemIds.remove(id);
                        } else {
                          _approvedItemIds.add(id);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: isApproved
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isApproved
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFEDE9FE),
                        ),
                      ),
                      child: Text(
                        isApproved ? 'Approved' : 'Review',
                        style: TextStyle(
                          color: isApproved
                              ? const Color(0xFF15803D)
                              : const Color(0xFF7C3AED),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Card 3 Component: Admissions pipeline
  Widget _buildAdmissionsFunnelCard() {
    final stages = [
      {'label': 'Enquiries', 'count': 53, 'pct': 100, 'sub': ''},
      {
        'label': 'Applications',
        'count': 28,
        'pct': 53,
        'sub': '↳ 53% step conversion',
      },
      {
        'label': 'Shortlisted',
        'count': 18,
        'pct': 34,
        'sub': '↳ 64% step conversion',
      },
      {
        'label': 'Admitted',
        'count': 13,
        'pct': 25,
        'sub': '↳ 72% step conversion',
      },
      {
        'label': 'Enrolled',
        'count': 12,
        'pct': 23,
        'sub': '↳ 92% step conversion',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admissions pipeline',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          const Text(
            'Group conversion funnel',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),

          const SizedBox(height: 12),

          ...stages.map((st) {
            final pct = st['pct'] as int;
            final sub = st['sub'] as String;

            return Padding(
              padding: const EdgeInsets.only(bottom: 9.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        st['label'] as String,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${st['count']}',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100.0,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- Sub-Views (Branch Tree, Student 360, Finance, Ops) ---
  Widget _buildBranchTreeView(List<dynamic> branches) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Branch Hierarchy Tree',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Active branches and institutional campus nodes',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 14),
          _buildTreeItem('ABC Educational Trust (HQ)', 'Organisation', 6, true),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: [
                _buildTreeItem('Steel Plant Branch', 'City Campus', 420, false),
                _buildTreeItem('Gachibowli Campus', 'City Campus', 380, false),
                _buildTreeItem(
                  'Kondapur Branch',
                  'Suburban Campus',
                  290,
                  false,
                ),
                _buildTreeItem('Madhapur Branch', 'City Campus', 150, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeItem(String title, String type, int count, bool isRoot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isRoot ? const Color(0xFFF5F3FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRoot ? const Color(0xFFC4B5FD) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isRoot ? Icons.account_balance_rounded : Icons.school_outlined,
                color: const Color(0xFF7C3AED),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isRoot ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            '$count ${isRoot ? 'Branches' : 'Students'}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentLookupView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student 360 Lookup',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by student name or ID...',
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildSampleStudentCard(
            'Jatin Kalidindi',
            'EDU-STU-2026-00012',
            'Class 6-A',
            'Steel Plant Branch',
            94,
            78,
          ),
        ],
      ),
    );
  }

  Widget _buildSampleStudentCard(
    String name,
    String id,
    String klass,
    String branch,
    int att,
    int exam,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '$id · $klass · $branch',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Attendance: $att%',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Exam Avg: $exam/100',
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceFeesView(Map<String, dynamic>? group) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Finance & Fee Management',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            'Double-entry ledgers, Razorpay payment flows, and overdue balances.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Growth & Admissions Pipeline',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            'Marketing campaigns, admission inquiries, conversion funnel and cost-per-admission.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicsView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Academic Operations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            'Timetable approvals, syllabus progress tracking, examination schedules, and merit ranks.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'People & Operations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            'Staff requisitions, HR exits, hostel occupancy, transport tracking and procurement write-offs.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'My Classes & Section Governance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Icon(Icons.menu_book_rounded, color: Color(0xFF3B82F6), size: 20),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Class teacher allocations, section student strengths, active subject periods, and curriculum benchmarks.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 14),
          _buildClassSummaryCard(
            'Grade 10 - Section A',
            '38 Students',
            'Lead: M. S. Sharma',
            'Mathematics (Live: Period 3)',
            const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 10),
          _buildClassSummaryCard(
            'Grade 9 - Section B',
            '42 Students',
            'Lead: Anita Deshmukh',
            'Physics Lab (Room 204)',
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 10),
          _buildClassSummaryCard(
            'Grade 8 - Section C',
            '36 Students',
            'Lead: Raghavendra Rao',
            'English Literature',
            const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSummaryCard(
    String title,
    String count,
    String teacher,
    String status,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$count · $teacher',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatDateShort(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _selectAttendanceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedAttendanceDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7C3AED),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedAttendanceDate) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedAttendanceDate = picked;
      });
    }
  }

  String _getBranchLabel(String id) {
    switch (id) {
      case 'steel-plant':
        return 'Steel Plant Branch';
      case 'gachibowli':
        return 'Gachibowli Campus';
      case 'maddipalem':
        return 'Maddipalem Branch';
      case 'kukatpally':
        return 'Kukatpally Campus';
      case 'kondapur':
        return 'Kondapur Branch';
      case 'madhapur':
        return 'Madhapur Branch';
      default:
        return 'All branches (9)';
    }
  }

  void _showFilterPicker({
    required String title,
    required List<Map<String, String>> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (selectedValue != 'all' && selectedValue != 'general')
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        onSelected('all');
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: options.map((opt) {
                      final isSelected = opt['id'] == selectedValue;
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(ctx);
                          onSelected(opt['id']!);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEDE9FE)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                opt['label']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF7C3AED)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF7C3AED),
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBranchPicker() {
    const options = [
      {'id': 'all', 'label': 'All branches (9)'},
      {'id': 'steel-plant', 'label': 'Steel Plant Branch (36 Roll / 12 Staff)'},
      {'id': 'gachibowli', 'label': 'Gachibowli Campus (21 Roll / 10 Staff)'},
      {'id': 'maddipalem', 'label': 'Maddipalem Branch (18 Roll / 7 Staff)'},
      {'id': 'kukatpally', 'label': 'Kukatpally Campus (17 Roll / 7 Staff)'},
      {'id': 'kondapur', 'label': 'Kondapur Branch (14 Roll / 6 Staff)'},
      {'id': 'madhapur', 'label': 'Madhapur Branch (9 Roll / 4 Staff)'},
    ];
    _showFilterPicker(
      title: 'Filter by Branch',
      options: options,
      selectedValue: _selectedBranchFilter,
      onSelected: (id) {
        setState(() {
          _selectedBranchFilter = id;
          if (id != 'all') _expandedBranchIds.add(id);
        });
      },
    );
  }

  void _showClassPicker() {
    const options = [
      {'id': 'all', 'label': 'All classes'},
      {'id': 'Class 10', 'label': 'Class 10'},
      {'id': 'Class 9', 'label': 'Class 9'},
      {'id': 'Class 8', 'label': 'Class 8'},
      {'id': 'Class 7', 'label': 'Class 7'},
      {'id': 'Class 6', 'label': 'Class 6'},
      {'id': 'Class 5', 'label': 'Class 5'},
      {'id': 'Class 2', 'label': 'Class 2'},
      {'id': 'Class 1', 'label': 'Class 1'},
    ];
    _showFilterPicker(
      title: 'Filter by Class',
      options: options,
      selectedValue: _selectedClassFilter,
      onSelected: (id) {
        setState(() => _selectedClassFilter = id);
      },
    );
  }

  void _showSectionPicker() {
    const options = [
      {'id': 'all', 'label': 'All sections'},
      {'id': 'Sec A', 'label': 'Sec A'},
      {'id': 'Sec B', 'label': 'Sec B'},
    ];
    _showFilterPicker(
      title: 'Filter by Section',
      options: options,
      selectedValue: _selectedSectionFilter,
      onSelected: (id) {
        setState(() => _selectedSectionFilter = id);
      },
    );
  }

  void _showDeptPicker() {
    const options = [
      {'id': 'all', 'label': 'All depts'},
      {'id': 'Physics', 'label': 'Physics'},
      {'id': 'English', 'label': 'English'},
      {'id': 'Transport', 'label': 'Transport'},
      {'id': 'Administration', 'label': 'Administration'},
      {'id': 'Library', 'label': 'Library'},
      {'id': 'Facilities & Security', 'label': 'Facilities & Security'},
    ];
    _showFilterPicker(
      title: 'Filter by Department',
      options: options,
      selectedValue: _selectedDeptFilter,
      onSelected: (id) {
        setState(() => _selectedDeptFilter = id);
      },
    );
  }

  void _showShiftPicker() {
    const options = [
      {'id': 'general', 'label': 'General shift (08:30 - 16:30)'},
      {'id': 'morning', 'label': 'Morning shift (07:00 - 15:00)'},
      {'id': 'evening', 'label': 'Evening shift (12:00 - 20:00)'},
    ];
    _showFilterPicker(
      title: 'Filter by Shift',
      options: options,
      selectedValue: _selectedShiftFilter,
      onSelected: (id) {
        setState(() => _selectedShiftFilter = id);
      },
    );
  }

  bool _hasActiveFilters(bool isStudents) {
    if (_selectedBranchFilter != 'all') return true;
    if (_attendanceSearchQuery.isNotEmpty) return true;
    if (isStudents) {
      if (_studentResidencyFilter != 'all-students') return true;
      if (_selectedClassFilter != 'all') return true;
      if (_selectedSectionFilter != 'all') return true;
      if (_rosterFilterPill != 'all') return true;
    } else {
      if (_staffRoleFilter != 'all-staff') return true;
      if (_staffSubFilter != 'all-nt') return true;
      if (_selectedDeptFilter != 'all') return true;
      if (_selectedShiftFilter != 'general') return true;
      if (_rosterFilterPill != 'all') return true;
    }
    return false;
  }

  void _resetAttendanceFilters(bool isStudents) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedBranchFilter = 'all';
      _attendanceSearchQuery = '';
      if (isStudents) {
        _studentResidencyFilter = 'all-students';
        _selectedClassFilter = 'all';
        _selectedSectionFilter = 'all';
        _rosterFilterPill = 'all';
      } else {
        _staffRoleFilter = 'all-staff';
        _staffSubFilter = 'all-nt';
        _selectedDeptFilter = 'all';
        _selectedShiftFilter = 'general';
        _rosterFilterPill = 'all';
      }
    });
  }

  Map<String, dynamic> _getAttendanceAggregateStats(bool isStudents) {
    if (isStudents) {
      int total = 115;
      int present = 0;
      int absent = 0;
      int leave = 0;
      int pending = 115;

      if (_selectedBranchFilter != 'all') {
        const branchCounts = {
          'steel-plant': 36,
          'gachibowli': 21,
          'maddipalem': 18,
          'kukatpally': 17,
          'kondapur': 14,
          'madhapur': 9,
        };
        const branchHostel = {
          'steel-plant': 4,
          'gachibowli': 2,
          'maddipalem': 2,
          'kukatpally': 2,
          'kondapur': 1,
          'madhapur': 1,
        };
        final bTotal = branchCounts[_selectedBranchFilter] ?? 115;
        final bHostel = branchHostel[_selectedBranchFilter] ?? 2;
        final bDay = bTotal - bHostel;

        if (_studentResidencyFilter == 'hostel-residents') {
          total = bHostel;
        } else if (_studentResidencyFilter == 'day-scholars') {
          total = bDay;
        } else {
          total = bTotal;
        }
        pending = total;
      } else {
        if (_studentResidencyFilter == 'hostel-residents') {
          total = 12;
          pending = 12;
        } else if (_studentResidencyFilter == 'day-scholars') {
          total = 103;
          pending = 103;
        } else {
          total = 115;
          pending = 115;
        }
      }

      if (_selectedClassFilter != 'all') {
        const classCounts = {
          'Class 10': 36,
          'Class 9': 14,
          'Class 8': 8,
          'Class 7': 6,
          'Class 6': 11,
          'Class 5': 8,
          'Class 2': 20,
          'Class 1': 8,
        };
        final cCount = classCounts[_selectedClassFilter] ?? (total ~/ 4);
        total = _selectedBranchFilter == 'all'
            ? cCount
            : (cCount ~/ 3).clamp(4, total);
        pending = total;
      }
      if (_selectedSectionFilter != 'all') {
        total = (total / 2).round().clamp(1, total);
        pending = total;
      }

      final attendancePct = total > 0
          ? (present == 0
                ? '0%'
                : '${((present / total) * 100).toStringAsFixed(1)}%')
          : '0%';
      final presentPct = total > 0
          ? '${((present / total) * 100).toStringAsFixed(0)}%'
          : '0%';
      final absentPct = total > 0
          ? '${((absent / total) * 100).toStringAsFixed(0)}%'
          : '0%';
      final leavePct = total > 0
          ? '${((leave / total) * 100).toStringAsFixed(0)}%'
          : '0%';
      final pendingPct = total > 0
          ? '${((pending / total) * 100).toStringAsFixed(0)}%'
          : '0%';

      return {
        'total': total,
        'present': present,
        'absent': absent,
        'leave': leave,
        'pending': pending,
        'attendancePct': attendancePct,
        'presentPct': presentPct,
        'absentPct': absentPct,
        'leavePct': leavePct,
        'pendingPct': pendingPct,
      };
    } else {
      // Staff
      int total = 46;
      int present = 42;
      int absent = 2;
      int leave = 2;
      int pending = 0;

      if (_selectedBranchFilter != 'all') {
        const branchStaff = {
          'steel-plant': {'total': 12, 'present': 11, 'absent': 1, 'leave': 0},
          'gachibowli': {'total': 10, 'present': 9, 'absent': 0, 'leave': 1},
          'maddipalem': {'total': 7, 'present': 7, 'absent': 0, 'leave': 0},
          'kukatpally': {'total': 7, 'present': 6, 'absent': 1, 'leave': 0},
          'kondapur': {'total': 6, 'present': 5, 'absent': 0, 'leave': 1},
          'madhapur': {'total': 4, 'present': 4, 'absent': 0, 'leave': 0},
        };
        final bData = branchStaff[_selectedBranchFilter];
        if (bData != null) {
          total = bData['total']!;
          present = bData['present']!;
          absent = bData['absent']!;
          leave = bData['leave']!;
        }
      }

      if (_staffRoleFilter == 'teaching') {
        if (_selectedBranchFilter == 'all') {
          total = 21;
          present = 20;
          absent = 1;
          leave = 0;
        } else {
          total = (total * 0.55).round().clamp(2, total);
          present = (total - (absent > 0 ? 1 : 0)).clamp(0, total);
          absent = total - present;
          leave = 0;
        }
      } else if (_staffRoleFilter == 'non-teaching') {
        if (_staffSubFilter == 'all-nt') {
          if (_selectedBranchFilter == 'all') {
            total = 10;
            present = 8;
            absent = 1;
            leave = 1;
          } else {
            total = (total * 0.25).round().clamp(1, total);
            present = (total - (absent > 0 ? 1 : 0)).clamp(0, total);
            absent = total > present ? 1 : 0;
            leave = 0;
          }
        } else {
          const subStats = {
            'librarian': {'total': 5, 'present': 4, 'absent': 0, 'leave': 1},
            'bus-attendant': {
              'total': 1,
              'present': 0,
              'absent': 1,
              'leave': 0,
            },
            'hostel-warden': {
              'total': 1,
              'present': 1,
              'absent': 0,
              'leave': 0,
            },
            'account-mgr': {'total': 1, 'present': 1, 'absent': 0, 'leave': 0},
            'receptionist': {'total': 1, 'present': 1, 'absent': 0, 'leave': 0},
            'transport-mgr': {
              'total': 1,
              'present': 1,
              'absent': 0,
              'leave': 0,
            },
          };
          final sData = subStats[_staffSubFilter];
          if (sData != null) {
            total = sData['total']!;
            present = sData['present']!;
            absent = sData['absent']!;
            leave = sData['leave']!;
          }
        }
      }

      final attendancePct = total > 0
          ? '${((present / total) * 100).toStringAsFixed(1)}%'
          : '0%';
      final presentPct = total > 0
          ? '${((present / total) * 100).toStringAsFixed(0)}%'
          : '0%';
      final absentPct = total > 0
          ? '${((absent / total) * 100).toStringAsFixed(0)}%'
          : '0%';
      final leavePct = total > 0
          ? '${((leave / total) * 100).toStringAsFixed(0)}%'
          : '0%';
      final pendingPct = total > 0
          ? '${((pending / total) * 100).toStringAsFixed(0)}%'
          : '0%';

      return {
        'total': total,
        'present': present,
        'absent': absent,
        'leave': leave,
        'pending': pending,
        'attendancePct': attendancePct,
        'presentPct': presentPct,
        'absentPct': absentPct,
        'leavePct': leavePct,
        'pendingPct': pendingPct,
      };
    }
  }

  List<Map<String, dynamic>> _getFilteredStudents() {
    return _attendanceStudentRecords.where((s) {
      if (_attendanceSearchQuery.isNotEmpty) {
        final q = _attendanceSearchQuery.toLowerCase();
        final name = (s['name'] as String).toLowerCase();
        final meta = (s['meta'] as String).toLowerCase();
        final roll = (s['rollNo'] as String).toLowerCase();
        final branch = (s['branchName'] as String).toLowerCase();
        if (!name.contains(q) &&
            !meta.contains(q) &&
            !roll.contains(q) &&
            !branch.contains(q)) {
          return false;
        }
      }
      if (_selectedBranchFilter != 'all' &&
          s['branchId'] != _selectedBranchFilter) {
        return false;
      }
      if (_selectedClassFilter != 'all' && s['class'] != _selectedClassFilter) {
        return false;
      }
      if (_selectedSectionFilter != 'all' &&
          s['section'] != _selectedSectionFilter) {
        return false;
      }
      if (_studentResidencyFilter != 'all-students' &&
          s['residency'] != _studentResidencyFilter) {
        return false;
      }
      if (_rosterFilterPill == 'absentees' || _rosterFilterPill == 'absent') {
        return s['status'] == 'Absent';
      } else if (_rosterFilterPill == 'not-marked') {
        return s['status'] == 'Not marked';
      } else if (_rosterFilterPill == 'present') {
        return s['status'] == 'Present';
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredStaff() {
    return _attendanceStaffRecords.where((st) {
      if (_attendanceSearchQuery.isNotEmpty) {
        final q = _attendanceSearchQuery.toLowerCase();
        final name = (st['name'] as String).toLowerCase();
        final role = (st['role'] as String).toLowerCase();
        final branch = (st['branchName'] as String).toLowerCase();
        if (!name.contains(q) && !role.contains(q) && !branch.contains(q)) {
          return false;
        }
      }
      if (_selectedBranchFilter != 'all' &&
          st['branchId'] != _selectedBranchFilter) {
        return false;
      }
      if (_selectedDeptFilter != 'all' &&
          st['department'] != _selectedDeptFilter) {
        return false;
      }
      if (_selectedShiftFilter != 'general' &&
          st['shift'] != _selectedShiftFilter) {
        return false;
      }
      if (_staffRoleFilter != 'all-staff' &&
          st['category'] != _staffRoleFilter) {
        return false;
      }
      if ((_staffRoleFilter == 'non-teaching' ||
              _staffRoleFilter == 'all-staff') &&
          _staffSubFilter != 'all-nt' &&
          st['subRole'] != _staffSubFilter) {
        return false;
      }
      if (_rosterFilterPill == 'teaching') {
        return st['category'] == 'teaching';
      } else if (_rosterFilterPill == 'non-teaching') {
        return st['category'] == 'non-teaching';
      } else if (_rosterFilterPill == 'leave') {
        return st['status'] == 'On Leave';
      } else if (_rosterFilterPill == 'absent') {
        return st['status'] == 'Absent';
      } else if (_rosterFilterPill == 'present') {
        return st['status'] == 'Present';
      }
      return true;
    }).toList();
  }

  Widget _buildAttendanceView() {
    final isStudents = _attendancePrimaryTab == 'students';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. Header Context & Quick Actions ---
        _buildAttendanceHeaderContext(isStudents),
        const SizedBox(height: 14),

        // --- 2. Primary Switchable Top Tabs: Students vs Staff ---
        _buildAttendancePrimaryTabs(isStudents),
        const SizedBox(height: 14),

        // --- 3. Unified Modern Executive Filter Bar ---
        _buildAttendanceFilterBar(isStudents),
        const SizedBox(height: 14),

        // --- 4. Audit Pulse Banner ---
        _buildAttendancePulseBanner(isStudents),
        const SizedBox(height: 14),

        // --- 5. Executive KPI Summary (2x3 Grid) ---
        _buildAttendanceKpiGrid(isStudents),
        const SizedBox(height: 20),

        // --- 6. "By Branch" Accordion Section ---
        _buildAttendanceBranchSection(isStudents),
        const SizedBox(height: 20),

        // --- 7. People Section: Roster & Search ---
        _buildAttendanceRosterSection(isStudents),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- Attendance Component 1: Header Context ---
  Widget _buildAttendanceHeaderContext(bool isStudents) {
    final branchName = _getBranchLabel(_selectedBranchFilter);
    final isFiltered = _selectedBranchFilter != 'all';
    final stats = _getAttendanceAggregateStats(isStudents);
    final count = stats['total'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'SAI RAVINDRA',
                    style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    '•',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ),
                const Text(
                  'AUDIT SUITE',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _selectAttendanceDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatDateShort(_selectedAttendanceDate),
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Color(0xFF7C3AED),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance Audit',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isStudents
                        ? (isFiltered
                              ? '$branchName • $count enrolled students'
                              : '9 branches • 115 total enrolled students')
                        : (isFiltered
                              ? '$branchName • $count sanctioned staff'
                              : '9 branches • 46 total sanctioned staff'),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isStudents
                          ? 'Exporting Student Attendance Report...'
                          : 'Exporting Staff Attendance Report...',
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.ios_share_rounded,
                      size: 16,
                      color: Color(0xFF7C3AED),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Export',
                      style: TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Attendance Component 2: Primary Students vs Staff Tabs ---
  Widget _buildAttendancePrimaryTabs(bool isStudents) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isStudents) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _attendancePrimaryTab = 'students';
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isStudents
                      ? const Color(0xFF7C3AED)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isStudents
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF7C3AED,
                            ).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 18,
                      color: isStudents
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Students',
                      style: TextStyle(
                        color: isStudents
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isStudents
                            ? Colors.white.withValues(alpha: 0.22)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '115',
                        style: TextStyle(
                          color: isStudents
                              ? Colors.white
                              : const Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isStudents) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _attendancePrimaryTab = 'staff';
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isStudents
                      ? const Color(0xFF7C3AED)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !isStudents
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF7C3AED,
                            ).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.badge_rounded,
                      size: 18,
                      color: !isStudents
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Staff',
                      style: TextStyle(
                        color: !isStudents
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: !isStudents
                            ? Colors.white.withValues(alpha: 0.22)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '46',
                        style: TextStyle(
                          color: !isStudents
                              ? Colors.white
                              : const Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Attendance Component 3: Unified Executive Filter Bar ---
  Widget _buildAttendanceFilterBar(bool isStudents) {
    final hasActive = _hasActiveFilters(isStudents);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Quick Meta Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _selectAttendanceDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 15,
                        color: Color(0xFF7C3AED),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(_selectedAttendanceDate),
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.expand_more_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7C3AED),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isStudents ? 'Students View' : 'Staff View',
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Sub-filters row (Residency vs Staff Role)
          if (isStudents) ...[
            const Text(
              'RESIDENCY SCOPE',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildScopePill(
                    'All students',
                    '115',
                    _studentResidencyFilter == 'all-students',
                    () {
                      setState(() => _studentResidencyFilter = 'all-students');
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildScopePill(
                    'Hostel residents',
                    '12',
                    _studentResidencyFilter == 'hostel-residents',
                    () {
                      setState(
                        () => _studentResidencyFilter = 'hostel-residents',
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildScopePill(
                    'Day scholars',
                    '103',
                    _studentResidencyFilter == 'day-scholars',
                    () {
                      setState(() => _studentResidencyFilter = 'day-scholars');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildDropdownChip(
                    'BRANCH',
                    _selectedBranchFilter == 'all'
                        ? 'All branches (9)'
                        : _getBranchLabel(_selectedBranchFilter),
                    isActive: _selectedBranchFilter != 'all',
                    onTap: _showBranchPicker,
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownChip(
                    'CLASS',
                    _selectedClassFilter == 'all'
                        ? 'All classes'
                        : _selectedClassFilter,
                    isActive: _selectedClassFilter != 'all',
                    onTap: _showClassPicker,
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownChip(
                    'SECTION',
                    _selectedSectionFilter == 'all'
                        ? 'All sections'
                        : _selectedSectionFilter,
                    isActive: _selectedSectionFilter != 'all',
                    onTap: _showSectionPicker,
                  ),
                  if (hasActive) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _resetAttendanceFilters(isStudents),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.clear_rounded,
                              size: 14,
                              color: Color(0xFFDC2626),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Clear all',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            const Text(
              'STAFF ROLE SCOPE',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildScopePill(
                    'All staff',
                    '46',
                    _staffRoleFilter == 'all-staff',
                    () {
                      setState(() => _staffRoleFilter = 'all-staff');
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildScopePill(
                    'Teaching staff',
                    '21',
                    _staffRoleFilter == 'teaching',
                    () {
                      setState(() => _staffRoleFilter = 'teaching');
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildScopePill(
                    'Non-teaching staff',
                    '10',
                    _staffRoleFilter == 'non-teaching',
                    () {
                      setState(() => _staffRoleFilter = 'non-teaching');
                    },
                  ),
                ],
              ),
            ),
            if (_staffRoleFilter == 'all-staff' ||
                _staffRoleFilter == 'non-teaching') ...[
              const SizedBox(height: 8),
              const Text(
                'NON-TEACHING ROLES',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 5),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildSubRolePill(
                      'All non-teaching',
                      '10',
                      _staffSubFilter == 'all-nt',
                      () {
                        setState(() => _staffSubFilter = 'all-nt');
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildSubRolePill(
                      'Account Manager',
                      '1',
                      _staffSubFilter == 'account-mgr',
                      () {
                        setState(() => _staffSubFilter = 'account-mgr');
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildSubRolePill(
                      'Bus Attendant',
                      '1',
                      _staffSubFilter == 'bus-attendant',
                      () {
                        setState(() => _staffSubFilter = 'bus-attendant');
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildSubRolePill(
                      'Hostel Warden',
                      '1',
                      _staffSubFilter == 'hostel-warden',
                      () {
                        setState(() => _staffSubFilter = 'hostel-warden');
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildSubRolePill(
                      'Librarian',
                      '5',
                      _staffSubFilter == 'librarian',
                      () {
                        setState(() => _staffSubFilter = 'librarian');
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildSubRolePill(
                      'Receptionist',
                      '1',
                      _staffSubFilter == 'receptionist',
                      () {
                        setState(() => _staffSubFilter = 'receptionist');
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildSubRolePill(
                      'Transport Manager',
                      '1',
                      _staffSubFilter == 'transport-mgr',
                      () {
                        setState(() => _staffSubFilter = 'transport-mgr');
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildDropdownChip(
                    'BRANCH',
                    _selectedBranchFilter == 'all'
                        ? 'All branches (9)'
                        : _getBranchLabel(_selectedBranchFilter),
                    isActive: _selectedBranchFilter != 'all',
                    onTap: _showBranchPicker,
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownChip(
                    'DEPARTMENT',
                    _selectedDeptFilter == 'all'
                        ? 'All depts'
                        : _selectedDeptFilter,
                    isActive: _selectedDeptFilter != 'all',
                    onTap: _showDeptPicker,
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownChip(
                    'SHIFT',
                    _selectedShiftFilter == 'general'
                        ? 'General shift'
                        : (_selectedShiftFilter == 'morning'
                              ? 'Morning shift'
                              : 'Evening shift'),
                    isActive: _selectedShiftFilter != 'general',
                    onTap: _showShiftPicker,
                  ),
                  if (hasActive) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _resetAttendanceFilters(isStudents),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.clear_rounded,
                              size: 14,
                              color: Color(0xFFDC2626),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Clear all',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScopePill(
    String label,
    String count,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF7C3AED) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF334155),
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.22)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF475569),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubRolePill(
    String label,
    String count,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF475569),
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownChip(
    String label,
    String value, {
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (onTap != null) onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEDE9FE) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF6D28D9)
                    : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFF0F172A),
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: isActive
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  // --- Attendance Component 4: Audit Pulse Banner ---
  Widget _buildAttendancePulseBanner(bool isStudents) {
    final stats = _getAttendanceAggregateStats(isStudents);

    if (isStudents) {
      final pendingCount = stats['pending'];
      final branchText = _selectedBranchFilter == 'all'
          ? 'across campuses'
          : 'in ${_getBranchLabel(_selectedBranchFilter)}';

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFBEB), Colors.white],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.pending_actions_rounded,
                color: Color(0xFFB45309),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Daily Roll Audit Pending',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF78350F),
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Awaiting Morning Sync',
                          style: TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$pendingCount students pending roll call submission $branchText',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      final present = stats['present'];
      final leave = stats['leave'];
      final absent = stats['absent'];
      final branchText = _selectedBranchFilter == 'all'
          ? 'all campuses'
          : _getBranchLabel(_selectedBranchFilter);

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFECFDF5), Colors.white],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFA7F3D0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.fingerprint_rounded,
                color: Color(0xFF047857),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Staff Biometric Sync Complete',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF064E3B),
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _selectedShiftFilter == 'general'
                              ? '09:30 AM Shift'
                              : (_selectedShiftFilter == 'morning'
                                    ? '07:00 AM Shift'
                                    : '12:00 PM Shift'),
                          style: const TextStyle(
                            color: Color(0xFF065F46),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$present present, $leave on leave, $absent absent across $branchText',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  // --- Attendance Component 5: Executive KPI Summary Card (Live Summary Strip) ---
  Widget _buildAttendanceKpiGrid(bool isStudents) {
    final stats = _getAttendanceAggregateStats(isStudents);
    final total = stats['total'] as int;
    final present = stats['present'] as int;
    final absent = stats['absent'] as int;
    final leave = stats['leave'] as int;
    final pending = stats['pending'] as int;

    final totalCount = total.toString();
    final activeBadge = isStudents ? 'ACTIVE' : 'ON DUTY';
    final subLabel = isStudents
        ? 'Total enrolled students on roll'
        : 'Total sanctioned staff on roll';
    final attendancePct = stats['attendancePct'] as String;

    final presentCount = present.toString();
    final presentPct = stats['presentPct'] as String;

    final absentCount = absent.toString();
    final absentPct = stats['absentPct'] as String;

    final leaveCount = leave.toString();
    final leavePct = stats['leavePct'] as String;

    final pendingCount = pending.toString();
    final pendingPct = stats['pendingPct'] as String;

    final distributionNote = isStudents
        ? (pending > 0
              ? '$pending Pending Morning Roll Call'
              : 'All Students Marked')
        : (total > 0 ? '$presentPct Biometric Logged' : 'No Staff in Scope');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row outside the card
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'EXECUTIVE KPI SUMMARY',
              style: TextStyle(
                color: Color(0xFF1E1B4B),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4.5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Live Summary Strip',
                style: TextStyle(
                  color: Color(0xFF6D28D9),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Main White Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Active Count + Attendance Block
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Color(0xFF7C3AED),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Total & Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              totalCount,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                activeBadge,
                                style: const TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Attendance % Pill Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ATTENDANCE',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              attendancePct,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFA7F3D0),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            size: 14,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Middle Row: Distribution & Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Distribution',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    distributionNote,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Distribution Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 6,
                  width: double.infinity,
                  color: const Color(0xFFF1F5F9),
                  child: total == 0
                      ? Container(color: const Color(0xFFE2E8F0))
                      : Row(
                          children: [
                            if (present > 0)
                              Expanded(
                                flex: present,
                                child: Container(
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            if (absent > 0)
                              Expanded(
                                flex: absent,
                                child: Container(
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            if (leave > 0)
                              Expanded(
                                flex: leave,
                                child: Container(
                                  color: const Color(0xFF4F46E5),
                                ),
                              ),
                            if (pending > 0)
                              Expanded(
                                flex: pending,
                                child: Container(
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Row: 4 Metric Cards (Present, Absent, Leave, Pending)
              Row(
                children: [
                  Expanded(
                    child: _buildStripMetricCard(
                      label: 'PRESENT',
                      value: presentCount,
                      pct: presentPct,
                      dotColor: const Color(0xFF059669),
                      textColor: const Color(0xFF047857),
                      isPending: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStripMetricCard(
                      label: 'ABSENT',
                      value: absentCount,
                      pct: absentPct,
                      dotColor: const Color(0xFFDC2626),
                      textColor: const Color(0xFFB91C1C),
                      isPending: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStripMetricCard(
                      label: 'LEAVE',
                      value: leaveCount,
                      pct: leavePct,
                      dotColor: const Color(0xFF4F46E5),
                      textColor: const Color(0xFF4338CA),
                      isPending: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStripMetricCard(
                      label: 'PENDING',
                      value: pendingCount,
                      pct: pendingPct,
                      dotColor: const Color(0xFFF59E0B),
                      textColor: const Color(0xFF92400E),
                      isPending: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStripMetricCard({
    required String label,
    required String value,
    required String pct,
    required Color dotColor,
    required Color textColor,
    required bool isPending,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: isPending ? const Color(0xFF78350F) : textColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            pct,
            style: TextStyle(
              color: isPending
                  ? const Color(0xFF92400E)
                  : const Color(0xFF64748B),
              fontSize: 11.5,
              fontWeight: isPending ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- Attendance Component 6: "By Branch" Accordion Section ---
  Widget _buildAttendanceBranchSection(bool isStudents) {
    final studentBranches = [
      {
        'id': 'steel-plant',
        'name': 'Steel Plant Branch',
        'total': 36,
        'present': 0,
        'absent': 0,
        'leave': 0,
        'pct': '0%',
        'statusText': '36 Not marked',
        'sections': [
          {
            'name': 'Class 10 • Sec A',
            'count': '10 students',
            'status': 'Not marked',
          },
          {
            'name': 'Class 10 • Sec B',
            'count': '8 students',
            'status': 'Not marked',
          },
          {
            'name': 'Class 9 • Sec A',
            'count': '10 students',
            'status': 'Not marked',
          },
          {
            'name': 'Class 5 • Sec A',
            'count': '8 students',
            'status': 'Not marked',
          },
        ],
      },
      {
        'id': 'gachibowli',
        'name': 'Gachibowli Campus',
        'total': 21,
        'present': 0,
        'absent': 0,
        'leave': 0,
        'pct': '0%',
        'statusText': '21 Not marked',
        'sections': [
          {
            'name': 'Class 6 • Sec A',
            'count': '11 students',
            'status': 'Not marked',
          },
          {
            'name': 'Class 2 • Sec A',
            'count': '10 students',
            'status': 'Not marked',
          },
        ],
      },
      {
        'id': 'maddipalem',
        'name': 'Maddipalem Branch',
        'total': 18,
        'present': 0,
        'absent': 0,
        'leave': 0,
        'pct': '0%',
        'statusText': '18 Not marked',
        'sections': [
          {
            'name': 'Class 2 • Sec A',
            'count': '10 students',
            'status': 'Not marked',
          },
          {
            'name': 'Class 1 • Sec A',
            'count': '8 students',
            'status': 'Not marked',
          },
        ],
      },
      {
        'id': 'kukatpally',
        'name': 'Kukatpally Campus',
        'total': 17,
        'present': 0,
        'absent': 0,
        'leave': 0,
        'pct': '0%',
        'statusText': '17 Not marked',
        'sections': [
          {
            'name': 'Class 10 • Sec A',
            'count': '9 students',
            'status': 'Not marked',
          },
          {
            'name': 'Class 8 • Sec A',
            'count': '8 students',
            'status': 'Not marked',
          },
        ],
      },
      {
        'id': 'kondapur',
        'name': 'Kondapur Branch',
        'total': 14,
        'present': 0,
        'absent': 0,
        'leave': 0,
        'pct': '0%',
        'statusText': '14 Not marked',
        'sections': [
          {
            'name': 'Class 10 • Sec A',
            'count': '8 students',
            'status': 'Not marked',
          },
          {
            'name': 'Class 7 • Sec A',
            'count': '6 students',
            'status': 'Not marked',
          },
        ],
      },
      {
        'id': 'madhapur',
        'name': 'Madhapur Branch',
        'total': 9,
        'present': 0,
        'absent': 0,
        'leave': 0,
        'pct': '0%',
        'statusText': '9 Not marked',
        'sections': [
          {
            'name': 'Class 10 • Sec A',
            'count': '5 students',
            'status': 'Not marked',
          },
          {
            'name': 'Class 9 • Sec A',
            'count': '4 students',
            'status': 'Not marked',
          },
        ],
      },
    ];

    final staffBranches = [
      {
        'id': 'steel-plant',
        'name': 'Steel Plant Branch',
        'total': 12,
        'present': 11,
        'absent': 1,
        'leave': 0,
        'pct': '91.7%',
        'progress': 0.917,
        'statusText': '11 Present • 1 Absent',
        'sections': [
          {
            'name': 'High School Faculty',
            'count': '6 faculty',
            'status': 'Present (6)',
          },
          {
            'name': 'Primary Teachers',
            'count': '3 faculty',
            'status': 'Present (3)',
          },
          {
            'name': 'Campus Operations',
            'count': '3 staff',
            'status': '1 Absent • 2 Present',
          },
        ],
      },
      {
        'id': 'gachibowli',
        'name': 'Gachibowli Campus',
        'total': 10,
        'present': 9,
        'absent': 0,
        'leave': 1,
        'pct': '90.0%',
        'progress': 0.900,
        'statusText': '9 Present • 1 Leave',
        'sections': [
          {
            'name': 'Secondary Faculty',
            'count': '5 faculty',
            'status': 'Present (5)',
          },
          {
            'name': 'Admin & Lab Staff',
            'count': '3 staff',
            'status': '1 On Leave • 2 Present',
          },
          {
            'name': 'Transport Coordinator',
            'count': '2 staff',
            'status': 'Present (2)',
          },
        ],
      },
      {
        'id': 'maddipalem',
        'name': 'Maddipalem Branch',
        'total': 7,
        'present': 7,
        'absent': 0,
        'leave': 0,
        'pct': '100%',
        'progress': 1.0,
        'statusText': '7 Present',
        'sections': [
          {
            'name': 'Primary Staff',
            'count': '4 teachers',
            'status': 'Present (4)',
          },
          {
            'name': 'Support Staff',
            'count': '3 staff',
            'status': 'Present (3)',
          },
        ],
      },
      {
        'id': 'kukatpally',
        'name': 'Kukatpally Campus',
        'total': 7,
        'present': 6,
        'absent': 1,
        'leave': 0,
        'pct': '85.7%',
        'progress': 0.857,
        'statusText': '6 Present • 1 Absent',
        'sections': [
          {
            'name': 'Academic Faculty',
            'count': '4 faculty',
            'status': 'Present (4)',
          },
          {
            'name': 'Facilities & Security',
            'count': '3 staff',
            'status': '1 Absent • 2 Present',
          },
        ],
      },
      {
        'id': 'kondapur',
        'name': 'Kondapur Branch',
        'total': 6,
        'present': 5,
        'absent': 0,
        'leave': 1,
        'pct': '83.3%',
        'progress': 0.833,
        'statusText': '5 Present • 1 Leave',
        'sections': [
          {
            'name': 'Teaching Faculty',
            'count': '4 faculty',
            'status': 'Present (4)',
          },
          {
            'name': 'Admin Office',
            'count': '2 staff',
            'status': '1 On Leave • 1 Present',
          },
        ],
      },
      {
        'id': 'madhapur',
        'name': 'Madhapur Branch',
        'total': 4,
        'present': 4,
        'absent': 0,
        'leave': 0,
        'pct': '100%',
        'progress': 1.0,
        'statusText': '4 Present',
        'sections': [
          {
            'name': 'High School Teachers',
            'count': '2 faculty',
            'status': 'Present (2)',
          },
          {
            'name': 'Front Desk & Admin',
            'count': '2 staff',
            'status': 'Present (2)',
          },
        ],
      },
    ];

    final allBranches = isStudents ? studentBranches : staffBranches;
    final branches = _selectedBranchFilter == 'all'
        ? allBranches
        : allBranches.where((b) => b['id'] == _selectedBranchFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    size: 16,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'By Branch',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_selectedBranchFilter != 'all')
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedBranchFilter = 'all');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC4B5FD)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_getBranchLabel(_selectedBranchFilter)} ✕',
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${branches.length} Branches active',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...branches.map((b) {
          final bId = b['id'] as String;
          final isExpanded = _expandedBranchIds.contains(bId);
          final sections = (b['sections'] as List<Map<String, String>>);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isExpanded
                    ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
                    : const Color(0xFFE2E8F0),
                width: isExpanded ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (isExpanded) {
                        _expandedBranchIds.remove(bId);
                      } else {
                        _expandedBranchIds.add(bId);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isStudents
                                          ? const Color(0xFF7C3AED)
                                          : const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      b['name'] as String,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isStudents
                                        ? const Color(0xFFFFFBEB)
                                        : const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isStudents
                                          ? const Color(0xFFFDE68A)
                                          : const Color(0xFFA7F3D0),
                                    ),
                                  ),
                                  child: Text(
                                    b['statusText'] as String,
                                    style: TextStyle(
                                      color: isStudents
                                          ? const Color(0xFF92400E)
                                          : const Color(0xFF047857),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Icon(
                                    Icons.expand_more_rounded,
                                    size: 20,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                isStudents
                                    ? 'Roll: ${b['total']} • Present: ${b['present']} • Absent: ${b['absent']} • Leave: ${b['leave']}'
                                    : 'Staff: ${b['total']} • Present: ${b['present']} • Absent: ${b['absent']} • Leave: ${b['leave']}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              b['pct'] as String,
                              style: TextStyle(
                                color: isStudents
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF059669),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: isStudents
                                ? 1.0
                                : (b['progress'] as double? ?? 0.0),
                            minHeight: 5,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isStudents
                                  ? const Color(
                                      0xFF7C3AED,
                                    ).withValues(alpha: 0.35)
                                  : const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isStudents
                                  ? 'CLASS ROSTER BREAKDOWN'
                                  : 'DEPARTMENT BREAKDOWN',
                              style: const TextStyle(
                                color: Color(0xFF7C3AED),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              '${sections.length} ${isStudents ? 'Sections' : 'Depts'}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...sections.map((s) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    s['name']!,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${s['count']} • ',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      s['status']!,
                                      style: TextStyle(
                                        color: isStudents
                                            ? const Color(0xFF92400E)
                                            : const Color(0xFF7C3AED),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- Attendance Component 7: People Roster & Search Section ---
  Widget _buildAttendanceRosterSection(bool isStudents) {
    final filteredStudents = _getFilteredStudents();
    final filteredStaff = _getFilteredStaff();

    if (isStudents && _rosterFilterPill == 'absentees') {
      filteredStudents.sort((a, b) {
        if (a['status'] == 'Absent' && b['status'] != 'Absent') return -1;
        if (a['status'] != 'Absent' && b['status'] == 'Absent') return 1;
        return 0;
      });
    }

    final stats = _getAttendanceAggregateStats(isStudents);
    final totalInScope = stats['total'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isStudents ? Icons.group_rounded : Icons.badge_rounded,
                    size: 16,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isStudents ? 'Student Roster' : 'Staff Directory',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: isStudents
                    ? const Color(0xFFFFFBEB)
                    : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isStudents
                      ? const Color(0xFFFDE68A)
                      : const Color(0xFFA7F3D0),
                ),
              ),
              child: Text(
                isStudents
                    ? 'Showing ${filteredStudents.length} of $totalInScope Students'
                    : 'Showing ${filteredStaff.length} of $totalInScope Staff',
                style: TextStyle(
                  color: isStudents
                      ? const Color(0xFF92400E)
                      : const Color(0xFF047857),
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _attendanceSearchQuery = val;
                    });
                  },
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: isStudents
                        ? 'Search student name, roll number, or section...'
                        : 'Search staff name, employee ID, role...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              if (_attendanceSearchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _attendanceSearchQuery = '';
                    });
                  },
                  child: const Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Quick Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: isStudents
                ? [
                    _buildRosterFilterPill(
                      'Absentees first',
                      _rosterFilterPill == 'absentees',
                      () {
                        setState(
                          () => _rosterFilterPill =
                              _rosterFilterPill == 'absentees'
                              ? 'all'
                              : 'absentees',
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildRosterFilterPill(
                      'All ($totalInScope)',
                      _rosterFilterPill == 'all',
                      () {
                        setState(() => _rosterFilterPill = 'all');
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildRosterFilterPill(
                      'Not marked (${stats['pending']})',
                      _rosterFilterPill == 'not-marked',
                      () {
                        setState(
                          () => _rosterFilterPill =
                              _rosterFilterPill == 'not-marked'
                              ? 'all'
                              : 'not-marked',
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildRosterFilterPill(
                      'Present (${stats['present']})',
                      _rosterFilterPill == 'present',
                      () {
                        setState(
                          () =>
                              _rosterFilterPill = _rosterFilterPill == 'present'
                              ? 'all'
                              : 'present',
                        );
                      },
                    ),
                  ]
                : [
                    _buildRosterFilterPill(
                      'All Staff ($totalInScope)',
                      _rosterFilterPill == 'all',
                      () {
                        setState(() => _rosterFilterPill = 'all');
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildRosterFilterPill(
                      'Teaching (${_selectedBranchFilter == 'all' ? 21 : (totalInScope * 0.55).round().clamp(1, totalInScope)})',
                      _rosterFilterPill == 'teaching',
                      () {
                        setState(
                          () => _rosterFilterPill =
                              _rosterFilterPill == 'teaching'
                              ? 'all'
                              : 'teaching',
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildRosterFilterPill(
                      'Non-Teaching (${_selectedBranchFilter == 'all' ? 10 : (totalInScope * 0.25).round().clamp(1, totalInScope)})',
                      _rosterFilterPill == 'non-teaching',
                      () {
                        setState(
                          () => _rosterFilterPill =
                              _rosterFilterPill == 'non-teaching'
                              ? 'all'
                              : 'non-teaching',
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildRosterFilterPill(
                      'On Leave (${stats['leave']})',
                      _rosterFilterPill == 'leave',
                      () {
                        setState(
                          () => _rosterFilterPill = _rosterFilterPill == 'leave'
                              ? 'all'
                              : 'leave',
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildRosterFilterPill(
                      'Absent (${stats['absent']})',
                      _rosterFilterPill == 'absent',
                      () {
                        setState(
                          () => _rosterFilterPill =
                              _rosterFilterPill == 'absent' ? 'all' : 'absent',
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildRosterFilterPill(
                      'Present (${stats['present']})',
                      _rosterFilterPill == 'present',
                      () {
                        setState(
                          () =>
                              _rosterFilterPill = _rosterFilterPill == 'present'
                              ? 'all'
                              : 'present',
                        );
                      },
                    ),
                  ],
          ),
        ),
        const SizedBox(height: 12),

        // Empty state check
        if ((isStudents && filteredStudents.isEmpty) ||
            (!isStudents && filteredStaff.isEmpty)) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Icon(
                    Icons.filter_alt_off_rounded,
                    size: 26,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No matching records found',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Try relaxing your search query or dropdown filter criteria.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _resetAttendanceFilters(isStudents),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 15,
                          color: Color(0xFF7C3AED),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Reset All Filters',
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (isStudents) ...[
          // Student Roster Cards List
          ...filteredStudents.map((s) {
            Color statusBg = const Color(0xFFFFFBEB);
            Color statusBorder = const Color(0xFFFDE68A);
            Color statusText = const Color(0xFF92400E);

            if (s['status'] == 'Present') {
              statusBg = const Color(0xFFECFDF5);
              statusBorder = const Color(0xFFA7F3D0);
              statusText = const Color(0xFF047857);
            } else if (s['status'] == 'Absent') {
              statusBg = const Color(0xFFFEF2F2);
              statusBorder = const Color(0xFFFECACA);
              statusText = const Color(0xFFB91C1C);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF7C3AED,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            s['initials'] as String,
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      s['name'] as String,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      s['rollNo'] as String,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s['meta'] as String,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusBorder),
                    ),
                    child: Text(
                      s['status'] as String,
                      style: TextStyle(
                        color: statusText,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ] else ...[
          // Staff Directory Cards List
          ...filteredStaff.map((st) {
            Color tagBg = const Color(0xFFECFDF5);
            Color tagBorder = const Color(0xFFA7F3D0);
            Color tagText = const Color(0xFF047857);

            if (st['type'] == 'leave') {
              tagBg = const Color(0xFFEEF2FF);
              tagBorder = const Color(0xFFC7D2FE);
              tagText = const Color(0xFF4338CA);
            } else if (st['type'] == 'absent') {
              tagBg = const Color(0xFFFEF2F2);
              tagBorder = const Color(0xFFFECACA);
              tagText = const Color(0xFFB91C1C);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF7C3AED,
                                ).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(
                                    0xFF7C3AED,
                                  ).withValues(alpha: 0.2),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                st['initials'] as String,
                                style: const TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    st['name'] as String,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${st['role']} • ${st['branchName']}',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tagBorder),
                        ),
                        child: Text(
                          st['status'] as String,
                          style: TextStyle(
                            color: tagText,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        st['subStatus'] as String? ?? 'General Shift',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Calling ${st['name']} (${st['phone']})...',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.call_rounded,
                                    size: 14,
                                    color: Color(0xFF7C3AED),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Call',
                                    style: TextStyle(
                                      color: Color(0xFF7C3AED),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Opening chat with ${st['name']}...',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 14,
                                    color: Color(0xFF7C3AED),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Message',
                                    style: TextStyle(
                                      color: Color(0xFF7C3AED),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 4),

        // Load All Button
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _resetAttendanceFilters(isStudents);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: Color(0xFF7C3AED),
                ),
                const SizedBox(width: 6),
                Text(
                  isStudents
                      ? 'Showing ${filteredStudents.length} of $totalInScope students (tap to show all)'
                      : 'Showing ${filteredStaff.length} of $totalInScope staff members (tap to show all)',
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRosterFilterPill(
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF475569),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLessonPlansView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Curriculum & Lesson Plans',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Icon(
                Icons.auto_stories_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Weekly syllabus coverage tracking, submitted teaching plans, and Principal approval queues.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Master Institutional Timetable',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Class-wise schedules, teacher proxy allocation engine, and room vacancy tracker.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightsView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vriyda AI Intelligence Engine',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFA855F7),
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Predictive fee defaulter risk modeling, student retention warnings, and automated teacher feedback summaries.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Fleet & Transport Command',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            'GPS tracking of 18 campus buses, live route ETAs, and student boarding notifications.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBoardView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Notice Board & Circulars',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            'Instant broadcast circulars, SMS parent notifications, and staff advisory bulletins.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildExamsMarksView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Exams, Marksheets & Grading',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            'Summative assessment schedules, GPA distribution, report card generation, and board exam tracking.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Staff & Faculty Directory',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            'Institutional employee directory, department breakdown, biometric punch logs, and role permissions.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.amber, size: 36),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchDashboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTER: Cash Trajectory Area & Dashed Chart (Matching code.html)
// =============================================================================
class CashTrajectoryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid horizontal dashed lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    void drawDashedLine(double y) {
      const dashWidth = 4.0;
      const dashSpace = 4.0;
      double startX = 0;
      while (startX < w) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          gridPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    drawDashedLine(h * 0.20);
    drawDashedLine(h * 0.55);
    drawDashedLine(h * 0.90);

    // Revenue Area Gradient & Curve
    final revPoints = [
      Offset(0, h * 0.78),
      Offset(w * 0.17, h * 0.60),
      Offset(w * 0.34, h * 0.50),
      Offset(w * 0.51, h * 0.40),
      Offset(w * 0.68, h * 0.28),
      Offset(w * 0.85, h * 0.20),
      Offset(w, h * 0.15),
    ];

    final revPath = Path()..moveTo(revPoints[0].dx, revPoints[0].dy);
    for (int i = 1; i < revPoints.length; i++) {
      final p0 = revPoints[i - 1];
      final p1 = revPoints[i];
      final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      revPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(revPath)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF7C3AED).withValues(alpha: 0.30),
          const Color(0xFF7C3AED).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(revPath, linePaint);

    // Points on Revenue line
    final dotPaint = Paint()..color = const Color(0xFF7C3AED);
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(revPoints[3], 3.5, dotPaint);
    canvas.drawCircle(revPoints[3], 3.5, dotBorderPaint);
    canvas.drawCircle(revPoints[6], 3.5, dotPaint);
    canvas.drawCircle(revPoints[6], 3.5, dotBorderPaint);

    // OpEx Dashed Curve
    final opexPoints = [
      Offset(0, h * 0.85),
      Offset(w * 0.17, h * 0.75),
      Offset(w * 0.34, h * 0.65),
      Offset(w * 0.51, h * 0.60),
      Offset(w * 0.68, h * 0.52),
      Offset(w * 0.85, h * 0.47),
      Offset(w, h * 0.42),
    ];
    final opexPaint = Paint()
      ..color = const Color(0xFFF43F5E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < opexPoints.length - 1; i++) {
      final pA = opexPoints[i];
      final pB = opexPoints[i + 1];
      double segDist = (pB - pA).distance;
      int steps = (segDist / 6).floor();
      for (int s = 0; s < steps; s += 2) {
        final t1 = s / steps;
        final t2 = (s + 1) / steps;
        final pt1 = Offset.lerp(pA, pB, t1)!;
        final pt2 = Offset.lerp(pA, pB, t2)!;
        canvas.drawLine(pt1, pt2, opexPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// CUSTOM PAINTER: Fee Realization Multi-color Donut Ring (Matching code.html)
// =============================================================================
class FeeRealizationRingPainter extends CustomPainter {
  final double collectedPct;
  final double duePct;
  final double overduePct;

  FeeRealizationRingPainter({
    required this.collectedPct,
    required this.duePct,
    required this.overduePct,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Start angle: -pi / 2 (top)
    double startAngle = -3.141592653589793 / 2;

    void drawArc(double pct, Color color) {
      if (pct <= 0) return;
      final sweepAngle = (pct / 100.0) * (2 * 3.141592653589793);
      final p = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweepAngle, false, p);
      startAngle += sweepAngle;
    }

    drawArc(collectedPct, const Color(0xFF7C3AED));
    drawArc(duePct, const Color(0xFFF59E0B));
    drawArc(overduePct, const Color(0xFFF43F5E));
  }

  @override
  bool shouldRepaint(covariant FeeRealizationRingPainter oldDelegate) =>
      oldDelegate.collectedPct != collectedPct ||
      oldDelegate.duePct != duePct ||
      oldDelegate.overduePct != overduePct;
}

// =============================================================================
// CUSTOM PAINTER: Performance Quadrant Scatter Plot (Matching code.html)
// =============================================================================
class PerformanceQuadrantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final dashPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final crossX = w * 0.58;
    final crossY = h * 0.48;

    // Vertical dashed line
    double y = 10;
    while (y < h - 10) {
      canvas.drawLine(Offset(crossX, y), Offset(crossX, y + 4), dashPaint);
      y += 8;
    }

    // Horizontal dashed line
    double x = 10;
    while (x < w - 10) {
      canvas.drawLine(Offset(x, crossY), Offset(x + 4, crossY), dashPaint);
      x += 8;
    }

    // Text annotations
    void drawText(
      String text,
      Offset pos, {
      Color color = const Color(0xFF94A3B8),
      double fontSize = 8,
      FontWeight weight = FontWeight.w600,
    }) {
      final span = TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, pos);
    }

    drawText('avg collection 68%', Offset(crossX + 4, 12));
    drawText('avg attendance 92%', Offset(crossX + 4, crossY - 14));
    drawText(
      '▼ NEEDS ATTENTION',
      Offset(12, h - 20),
      color: const Color(0xFF64748B),
      weight: FontWeight.w700,
    );

    // Scatter bubbles from code.html SVG
    final bubbles = [
      {
        'cx': w * 0.84,
        'cy': h * 0.42,
        'r': 14.0,
        'color': const Color(0xFF10B981),
      },
      {
        'cx': w * 0.75,
        'cy': h * 0.30,
        'r': 12.0,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'cx': w * 0.50,
        'cy': h * 0.30,
        'r': 10.0,
        'color': const Color(0xFFA855F7),
      },
      {
        'cx': w * 0.12,
        'cy': h * 0.48,
        'r': 5.0,
        'color': const Color(0xFF059669),
      },
      {
        'cx': w * 0.52,
        'cy': h * 0.59,
        'r': 9.0,
        'color': const Color(0xFFEF4444),
      },
      {
        'cx': w * 0.70,
        'cy': h * 0.67,
        'r': 8.0,
        'color': const Color(0xFF06B6D4),
      },
      {
        'cx': w * 0.68,
        'cy': h * 0.74,
        'r': 8.5,
        'color': const Color(0xFFC084FC),
      },
      {
        'cx': w * 0.69,
        'cy': h * 0.78,
        'r': 6.0,
        'color': const Color(0xFF7C3AED),
      },
      {
        'cx': w * 0.15,
        'cy': h * 0.54,
        'r': 5.0,
        'color': const Color(0xFFF59E0B),
      },
    ];

    for (final b in bubbles) {
      final center = Offset(b['cx'] as double, b['cy'] as double);
      final r = b['r'] as double;
      final c = b['color'] as Color;

      final fillPaint = Paint()
        ..color = c.withValues(alpha: 0.65)
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, r, fillPaint);
      canvas.drawCircle(center, r, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// HELPER WIDGET: Quadrant Legend Item
// =============================================================================
class _QuadrantLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _QuadrantLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
