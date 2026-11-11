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
  State<ChairmanDashboardScreen> createState() => _ChairmanDashboardScreenState();
}

class _ChairmanDashboardScreenState extends State<ChairmanDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;
  String _activeView = 'view-overview';
  bool _isArcMenuOpen = false;

  // Interactive state for Group Overview
  final Set<String> _approvedItemIds = {};
  final Set<String> _acknowledgedAlertIds = {};
  String _selectedQuadrant = 'all';
  String _branchFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
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
    final orgName = _dashboardData?['orgName'] ?? widget.user.organizationName ?? 'Sai Ravindra School';
    final group = _dashboardData?['group'] as Map<String, dynamic>?;
    final branches = _dashboardData?['branches'] as List<dynamic>? ?? [];
    final alerts = _dashboardData?['alerts'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC), // Crisp SaaS Canvas from DESIGN.md
      body: SafeArea(
        child: Stack(
          children: [
            // Main Scrollable Body
            RefreshIndicator(
              onRefresh: _fetchDashboard,
              color: const Color(0xFF7C3AED),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
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
            Row(
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
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
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
                Column(
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
                    ),
                    const Text(
                      'Chairman Portal · Executive View',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                _buildHeaderIconBtn(Icons.refresh_rounded, const Color(0xFFF59E0B), _fetchDashboard),
                const SizedBox(width: 6),
                _buildHeaderIconBtn(Icons.notifications_outlined, const Color(0xFFF43F5E), () {}),
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
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user.email,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Log out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
      {'id': 'view-overview', 'label': 'Overview', 'icon': Icons.dashboard_outlined},
      {'id': 'view-branches', 'label': 'Branch Tree', 'icon': Icons.account_tree_outlined},
      {'id': 'view-users', 'label': 'Users', 'icon': Icons.people_outline},
      {'id': 'view-lookup', 'label': 'Student Lookup', 'icon': Icons.search_rounded},
      {'id': 'view-finance', 'label': 'Finance & Fees', 'icon': Icons.account_balance_wallet_outlined},
      {'id': 'view-growth', 'label': 'Growth & Admissions', 'icon': Icons.trending_up_rounded},
      {'id': 'view-academics', 'label': 'Academics', 'icon': Icons.school_outlined},
      {'id': 'view-operations', 'label': 'Operations', 'icon': Icons.business_center_outlined},
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
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
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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
      Map<String, dynamic>? group, List<dynamic> branches, List<dynamic> alerts) {
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
  Widget _buildOverviewContent(
      Map<String, dynamic>? group, List<dynamic> branches, List<dynamic> alerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
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
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Core performance metrics across all campuses',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // FEATURE 1-7: Executive KPIs (Active Students, YTD Revenue, Fee Collection %, Student Attendance, Capacity Used, Critical Alerts, Staff Attendance)
        _build7ExecutiveKPIs(group),

        const SizedBox(height: 16),

        // FEATURE 8: Revenue vs Operating Expenses (trend)
        _buildRevenueVsOpExTrendCard(group),

        const SizedBox(height: 16),

        // FEATURE 9: Performance quadrant (branch benchmarking)
        _buildPerformanceQuadrantCard(branches),

        const SizedBox(height: 16),

        // FEATURE 10: Branch comparison (health-weighted)
        _buildBranchComparisonHealthCard(branches),

        const SizedBox(height: 16),

        // FEATURE 11: Critical alerts feed
        _buildCriticalAlertsFeedCard(alerts),

        const SizedBox(height: 16),

        // FEATURE 12: Approvals queue
        _buildApprovalsQueueCard(),

        const SizedBox(height: 16),

        // FEATURE 13: Admissions pipeline funnel
        _buildAdmissionsFunnelCard(),
      ],
    );
  }

  // ===========================================================================
  // FEATURE 1-7: The 7 Executive KPIs
  // ===========================================================================
  Widget _build7ExecutiveKPIs(Map<String, dynamic>? group) {
    final students = group?['students'] ?? 1240;
    final capacity = group?['capacity'] ?? 1500;
    final capacityUtil = group?['capacityUtil'] ?? 82.7;
    final revenueYTD = group?['revenueYTD'] ?? 18500000;
    final collectedYTD = group?['collectedYTD'] ?? 14200000;
    final collectionPct = group?['collectionPct'] ?? 76.8;
    final attendance = group?['attendance'] ?? 92.4;
    final criticalAlerts = group?['alertsCritical'] ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary 4 KPIs in a 2x2 Grid
        Row(
          children: [
            // KPI 1: Active Students
            Expanded(
              child: _buildKpiCard(
                title: 'Active Students',
                value: '$students',
                sub: '$capacityUtil% of $capacity Cap',
                badgeText: '+12% YoY',
                icon: Icons.groups_rounded,
                accentColor: const Color(0xFF7C3AED),
                gradient: const [Color(0xFFFAF5FF), Colors.white],
              ),
            ),
            const SizedBox(width: 10),
            // KPI 2: YTD Revenue
            Expanded(
              child: _buildKpiCard(
                title: 'YTD Revenue',
                value: '₹${_formatCurrency(revenueYTD)}',
                sub: '₹${_formatCurrency(collectedYTD)} Coll.',
                badgeText: '89% Target',
                icon: Icons.currency_rupee_rounded,
                accentColor: const Color(0xFF059669),
                gradient: const [Color(0xFFECFDF5), Colors.white],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // KPI 3: Fee Collection %
            Expanded(
              child: _buildKpiCard(
                title: 'Fee Collection %',
                value: '$collectionPct%',
                sub: '₹${_formatCurrency(group?['outstanding'] ?? 4300000)} Pending',
                badgeText: 'Goal: 85%',
                icon: Icons.account_balance_wallet_rounded,
                accentColor: const Color(0xFFD97706),
                gradient: const [Color(0xFFFFFBEB), Colors.white],
              ),
            ),
            const SizedBox(width: 10),
            // KPI 4: Student Attendance
            Expanded(
              child: _buildKpiCard(
                title: 'Student Attendance',
                value: '$attendance%',
                sub: '${(students * (attendance / 100)).round()} Present Today',
                badgeText: 'On-trend',
                icon: Icons.how_to_reg_rounded,
                accentColor: const Color(0xFF0284C7),
                gradient: const [Color(0xFFF0F9FF), Colors.white],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Secondary 3 Operational KPIs (Capacity Used, Critical Alerts, Staff Attendance)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          child: Row(
            children: [
              // KPI 5: Capacity Used
              Expanded(
                child: _buildMiniOperationalKpi(
                  label: 'Capacity Used',
                  val: '$capacityUtil%',
                  sub: '$students / $capacity Seats',
                  icon: Icons.pie_chart_outline_rounded,
                  color: const Color(0xFF6366F1),
                ),
              ),
              Container(width: 1, height: 38, color: const Color(0xFFE2E8F0)),
              // KPI 6: Critical Alerts
              Expanded(
                child: _buildMiniOperationalKpi(
                  label: 'Critical Alerts',
                  val: '$criticalAlerts Critical',
                  sub: '3 Require Action',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFE11D48),
                ),
              ),
              Container(width: 1, height: 38, color: const Color(0xFFE2E8F0)),
              // KPI 7: Staff Attendance
              Expanded(
                child: _buildMiniOperationalKpi(
                  label: 'Staff Attendance',
                  val: '94.2%',
                  sub: '81 / 86 Faculty Active',
                  icon: Icons.badge_outlined,
                  color: const Color(0xFF0D9488),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String sub,
    required String badgeText,
    required IconData icon,
    required Color accentColor,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 8,
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
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            sub,
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniOperationalKpi({
    required String label,
    required String val,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FEATURE 8: Revenue vs Operating Expenses (Trend)
  // ===========================================================================
  Widget _buildRevenueVsOpExTrendCard(Map<String, dynamic>? group) {
    final months = [
      {'m': 'Jun', 'rev': 28.5, 'exp': 20.2},
      {'m': 'Jul', 'rev': 34.2, 'exp': 22.8},
      {'m': 'Aug', 'rev': 31.0, 'exp': 21.5},
      {'m': 'Sep', 'rev': 29.8, 'exp': 22.1},
      {'m': 'Oct', 'rev': 32.4, 'exp': 23.0},
      {'m': 'Nov', 'rev': 29.1, 'exp': 22.4},
    ];

    const maxVal = 38.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  children: const [
                    Text(
                      'Revenue vs Operating Expenses',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Monthly financial trend & operating margin',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '+28.4% EBITDA',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Legend
          Row(
            children: [
              _buildLegendDot(const Color(0xFF7C3AED), 'Revenue YTD: ₹1.85 Cr'),
              const SizedBox(width: 14),
              _buildLegendDot(const Color(0xFFF43F5E), 'OpEx: ₹1.32 Cr'),
              const Spacer(),
              Text(
                'Surplus: +₹53 L',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Monthly Dual Bar Visual Chart
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((item) {
                final rev = item['rev'] as double;
                final exp = item['exp'] as double;
                final m = item['m'] as String;

                final revHeight = (rev / maxVal) * 85;
                final expHeight = (exp / maxVal) * 85;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Revenue Bar
                        Container(
                          width: 14,
                          height: revHeight,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 3),
                        // OpEx Bar
                        Container(
                          width: 14,
                          height: expHeight,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFDA4AF), Color(0xFFF43F5E)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      m,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '₹${rev.toStringAsFixed(1)}L',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // FEATURE 9: Performance Quadrant (Branch Benchmarking)
  // ===========================================================================
  Widget _buildPerformanceQuadrantCard(List<dynamic> branches) {
    final quadrants = [
      {
        'id': 'q1',
        'title': 'Quadrant I · Stars (Leaders)',
        'desc': 'High Collection (>78%) & High Academic Health (>85)',
        'color': const Color(0xFF10B981),
        'branches': [
          {'name': 'Steel Plant Branch (STEE)', 'coll': '82.3%', 'health': '86', 'exam': '84%'},
          {'name': 'Gachibowli Campus (GACH)', 'coll': '78.5%', 'health': '88', 'exam': '86%'},
        ],
      },
      {
        'id': 'q2',
        'title': 'Quadrant II · Growth Potential',
        'desc': 'High Academic Health (>80) with Collection Follow-up',
        'color': const Color(0xFF3B82F6),
        'branches': [
          {'name': 'Kondapur Branch (KOND)', 'coll': '72.1%', 'health': '84', 'exam': '82%'},
        ],
      },
      {
        'id': 'q3',
        'title': 'Quadrant III · Cash Engines',
        'desc': 'High Fee Collection (>78%) & Moderate Academic Health',
        'color': const Color(0xFFF59E0B),
        'branches': [
          {'name': 'Madhapur Campus (MADH)', 'coll': '80.2%', 'health': '76', 'exam': '75%'},
        ],
      },
      {
        'id': 'q4',
        'title': 'Quadrant IV · Watchlist (Focus)',
        'desc': 'Requires Chairman Intervention (Fees <75% & Health <75)',
        'color': const Color(0xFFEF4444),
        'branches': [
          {'name': 'Kukatpally Campus (KUKT)', 'coll': '71.0%', 'health': '75', 'exam': '74%'},
          {'name': 'Maddipalem Branch (MADD)', 'coll': '69.4%', 'health': '74', 'exam': '72%'},
        ],
      },
    ];

    final filtered = _selectedQuadrant == 'all'
        ? quadrants
        : quadrants.where((q) => q['id'] == _selectedQuadrant).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  children: const [
                    Text(
                      'Performance Quadrant',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Branch benchmarking: Collection vs Academic Health',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '6 Campuses',
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quadrant Selector Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All Quadrants'),
                _buildFilterChip('q1', 'Stars (2)'),
                _buildFilterChip('q2', 'Growth (1)'),
                _buildFilterChip('q3', 'Cash (1)'),
                _buildFilterChip('q4', 'Watchlist (2)'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Quadrant Cards
          ...filtered.map((quad) {
            final quadColor = quad['color'] as Color;
            final quadBranches = quad['branches'] as List<Map<String, String>>;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: quadColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: quadColor.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: quadColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        quad['title'] as String,
                        style: TextStyle(
                          color: quadColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    quad['desc'] as String,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5),
                  ),
                  const SizedBox(height: 8),
                  ...quadBranches.map((b) {
                    return Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              b['name']!,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Coll: ${b['coll']}',
                                style: TextStyle(
                                  color: quadColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Health ${b['health']}',
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
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
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final isSel = _selectedQuadrant == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedQuadrant = id);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF7C3AED) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.white : const Color(0xFF475569),
            fontSize: 10,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // FEATURE 10: Branch Comparison (Health-Weighted)
  // ===========================================================================
  Widget _buildBranchComparisonHealthCard(List<dynamic> branches) {
    final list = [
      {
        'rank': 1,
        'code': 'GACH',
        'name': 'Gachibowli Campus',
        'health': 88,
        'status': 'Excellent',
        'statusColor': const Color(0xFF059669),
        'students': 380,
        'capacity': 420,
        'revenue': '₹58.5 L',
        'due': '₹9.2 L',
        'collectionPct': 86.4,
        'attendance': 94.8,
        'staffAttendance': 95.0,
        'examIndex': 86,
        'teachers': 24,
      },
      {
        'rank': 2,
        'code': 'STEE',
        'name': 'Steel Plant Branch',
        'health': 86,
        'status': 'Good',
        'statusColor': const Color(0xFF10B981),
        'students': 420,
        'capacity': 500,
        'revenue': '₹62.0 L',
        'due': '₹11.0 L',
        'collectionPct': 82.3,
        'attendance': 93.1,
        'staffAttendance': 93.3,
        'examIndex': 84,
        'teachers': 28,
      },
      {
        'rank': 3,
        'code': 'KOND',
        'name': 'Kondapur Branch',
        'health': 84,
        'status': 'Good',
        'statusColor': const Color(0xFF10B981),
        'students': 210,
        'capacity': 250,
        'revenue': '₹29.5 L',
        'due': '₹11.2 L',
        'collectionPct': 72.1,
        'attendance': 92.0,
        'staffAttendance': 94.0,
        'examIndex': 82,
        'teachers': 16,
      },
      {
        'rank': 4,
        'code': 'MADH',
        'name': 'Madhapur Campus',
        'health': 76,
        'status': 'Good',
        'statusColor': const Color(0xFF3B82F6),
        'students': 190,
        'capacity': 240,
        'revenue': '₹24.0 L',
        'due': '₹5.5 L',
        'collectionPct': 80.2,
        'attendance': 91.5,
        'staffAttendance': 92.5,
        'examIndex': 75,
        'teachers': 14,
      },
      {
        'rank': 5,
        'code': 'KUKT',
        'name': 'Kukatpally Campus',
        'health': 75,
        'status': 'Watch',
        'statusColor': const Color(0xFFF59E0B),
        'students': 160,
        'capacity': 210,
        'revenue': '₹21.0 L',
        'due': '₹6.2 L',
        'collectionPct': 71.0,
        'attendance': 90.2,
        'staffAttendance': 91.0,
        'examIndex': 74,
        'teachers': 12,
      },
      {
        'rank': 6,
        'code': 'MADD',
        'name': 'Maddipalem Branch',
        'health': 74,
        'status': 'Watch',
        'statusColor': const Color(0xFFEF4444),
        'students': 180,
        'capacity': 230,
        'revenue': '₹22.8 L',
        'due': '₹10.3 L',
        'collectionPct': 69.4,
        'attendance': 89.4,
        'staffAttendance': 90.0,
        'examIndex': 72,
        'teachers': 13,
      },
    ];

    final filtered = _branchFilter == 'all'
        ? list
        : _branchFilter == 'high'
            ? list.where((b) => (b['health'] as int) >= 80).toList()
            : list.where((b) => (b['health'] as int) < 80).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  children: const [
                    Text(
                      'Branch Comparison',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Health-weighted benchmarking across campuses',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Ranked 1-6',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Filter Row
          Row(
            children: [
              _buildBranchFilterPill('all', 'All Branches (6)'),
              const SizedBox(width: 6),
              _buildBranchFilterPill('high', 'High Health (3)'),
              const SizedBox(width: 6),
              _buildBranchFilterPill('action', 'Action Needed (3)'),
            ],
          ),

          const SizedBox(height: 12),

          // Ranked Branch Cards
          ...filtered.map((b) {
            final health = b['health'] as int;
            final statusColor = b['statusColor'] as Color;
            final coll = b['collectionPct'] as double;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  // Top Line: Rank, Name, Health Badge
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '#${b['rank']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b['name'] as String,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Code: ${b['code']} · ${b['teachers']} Faculty',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, color: statusColor, size: 10),
                            const SizedBox(width: 3),
                            Text(
                              'Score $health · ${b['status']}',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Metrics Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBranchMetricItem('Students', '${b['students']}/${b['capacity']}'),
                      _buildBranchMetricItem('Revenue', '${b['revenue']}'),
                      _buildBranchMetricItem('Pending', '${b['due']}'),
                      _buildBranchMetricItem('Attendance', '${b['attendance']}%'),
                      _buildBranchMetricItem('Exam Idx', '${b['examIndex']}%'),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Fee Collection Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Fee Collection Pace',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '$coll%',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: coll / 100,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
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
    );
  }

  Widget _buildBranchFilterPill(String id, String label) {
    final isSel = _branchFilter == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _branchFilter = id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.white : const Color(0xFF475569),
            fontSize: 9.5,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBranchMetricItem(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5, fontWeight: FontWeight.w600),
        ),
        Text(
          val,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 10.5, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  // ===========================================================================
  // FEATURE 11: Critical Alerts Feed
  // ===========================================================================
  Widget _buildCriticalAlertsFeedCard(List<dynamic> alerts) {
    final items = [
      {
        'id': 'alt-1',
        'level': 'CRITICAL',
        'type': 'Finance',
        'icon': Icons.payments_outlined,
        'title': '₹11.2 L Outstanding Overdue (>60 Days)',
        'meta': 'Kondapur Branch · 38% of billed overdue · 2h ago',
        'tagColor': const Color(0xFFE11D48),
      },
      {
        'id': 'alt-2',
        'level': 'URGENT',
        'type': 'Transport',
        'icon': Icons.directions_bus_outlined,
        'title': 'Bus Delay on Route 4 (GPS Telemetry Lag)',
        'meta': 'Kondapur Branch · 25 mins delay · 35m ago',
        'tagColor': const Color(0xFFD97706),
      },
      {
        'id': 'alt-3',
        'level': 'URGENT',
        'type': 'Facility',
        'icon': Icons.apartment_outlined,
        'title': 'Hostel Room A101 Plumbing Maintenance',
        'meta': 'Steel Plant Branch · Team Dispatched · 3h ago',
        'tagColor': const Color(0xFFD97706),
      },
      {
        'id': 'alt-4',
        'level': 'COMPLIANCE',
        'type': 'Regulatory',
        'icon': Icons.verified_user_outlined,
        'title': 'Annual Fire Safety Certificate Renewal Due',
        'meta': 'Gachibowli Campus · Expiry in 7 days · 1d ago',
        'tagColor': const Color(0xFF7C3AED),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECDD3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  children: const [
                    Text(
                      'Critical Alerts Feed',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Exception-first alerts requiring Chairman attention',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '1 Critical · 3 Urgent',
                  style: TextStyle(
                    color: Color(0xFFBE123C),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Alerts list
          ...items.map((al) {
            final id = al['id'] as String;
            final isAck = _acknowledgedAlertIds.contains(id);
            final tagColor = al['tagColor'] as Color;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isAck ? const Color(0xFFF8FAFC) : const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAck ? const Color(0xFFE2E8F0) : const Color(0xFFFECDD3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isAck ? const Color(0xFFE2E8F0) : tagColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      al['icon'] as IconData,
                      color: isAck ? const Color(0xFF64748B) : tagColor,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isAck ? const Color(0xFF64748B) : tagColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isAck ? 'ACKNOWLEDGED' : al['level'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              al['type'] as String,
                              style: TextStyle(
                                color: isAck ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          al['title'] as String,
                          style: TextStyle(
                            color: isAck ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          al['meta'] as String,
                          style: TextStyle(
                            color: isAck ? const Color(0xFF94A3B8) : const Color(0xFFBE123C),
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isAck)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _acknowledgedAlertIds.add(id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Alert acknowledged: ${al['title']}'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: const Color(0xFF0F172A),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tagColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Acknowledge',
                          style: TextStyle(
                            color: tagColor,
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

  // ===========================================================================
  // FEATURE 12: Approvals Queue
  // ===========================================================================
  Widget _buildApprovalsQueueCard() {
    final approvals = [
      {
        'id': 'apr-1',
        'type': 'Timetable Publication',
        'title': 'Class 6 & 7 Revised Term 2 Schedule',
        'branch': 'Steel Plant Branch',
        'submitter': 'Principal K. Rao',
        'age': '2d ago',
        'impact': 'Academic Publish',
        'icon': Icons.calendar_today_rounded,
        'color': const Color(0xFF7C3AED),
      },
      {
        'id': 'apr-2',
        'type': 'Fee Concession',
        'title': '25% Merit Discount · Roll #2041 (A. Sharma)',
        'branch': 'Kondapur Branch',
        'submitter': 'Accounts Officer',
        'age': '1d ago',
        'impact': '₹18,000 Waiver',
        'icon': Icons.discount_outlined,
        'color': const Color(0xFFD97706),
      },
      {
        'id': 'apr-3',
        'type': 'Store / Capex',
        'title': 'Physics & Chemistry Lab Apparatus Order',
        'branch': 'Gachibowli Campus',
        'submitter': 'Admin Dept.',
        'age': '3h ago',
        'impact': '₹45,000 Capex',
        'icon': Icons.science_outlined,
        'color': const Color(0xFF0284C7),
      },
      {
        'id': 'apr-4',
        'type': 'HR / Leave',
        'title': 'Senior Math Teacher Maternity Leave (6 Mos)',
        'branch': 'Maddipalem Branch',
        'submitter': 'HR Coordinator',
        'age': '4d ago',
        'impact': 'Staff Coverage',
        'icon': Icons.person_off_outlined,
        'color': const Color(0xFF059669),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  children: const [
                    Text(
                      'Approvals Queue',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pending Chairman sign-offs across campuses',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${approvals.length - _approvedItemIds.length} Pending Actions',
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Approval items
          ...approvals.map((ap) {
            final id = ap['id'] as String;
            final isApproved = _approvedItemIds.contains(id);
            final col = ap['color'] as Color;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isApproved ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isApproved ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: col.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(ap['icon'] as IconData, color: col, size: 15),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  ap['type'] as String,
                                  style: TextStyle(
                                    color: col,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    ap['impact'] as String,
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ap['title'] as String,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${ap['branch']} · ${ap['submitter']} · ${ap['age']}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Actions row
                  if (isApproved)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Approved by Chairman',
                            style: TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              setState(() => _approvedItemIds.add(id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Approved: ${ap['title']}'),
                                  backgroundColor: const Color(0xFF059669),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'Approve',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Opening detailed review for ${ap['title']}'),
                                  backgroundColor: const Color(0xFF0F172A),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: const Center(
                                child: Text(
                                  'Review',
                                  style: TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
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
    );
  }

  // ===========================================================================
  // FEATURE 13: Admissions Pipeline Funnel
  // ===========================================================================
  Widget _buildAdmissionsFunnelCard() {
    final stages = [
      {'stage': '1. Inquiries & Leads', 'count': 480, 'pct': 100.0, 'sub': 'Baseline inquiries', 'color': const Color(0xFF7C3AED)},
      {'stage': '2. Applications Submitted', 'count': 310, 'pct': 64.5, 'sub': '64.5% conversion', 'color': const Color(0xFF6366F1)},
      {'stage': '3. Tests & Interviews', 'count': 240, 'pct': 50.0, 'sub': '77.4% pass & interview', 'color': const Color(0xFF3B82F6)},
      {'stage': '4. Admissions Offered', 'count': 185, 'pct': 38.5, 'sub': '77.1% offer issued', 'color': const Color(0xFF0284C7)},
      {'stage': '5. Final Enrolled (Paid)', 'count': 142, 'pct': 29.6, 'sub': '76.8% yield (AY 26-27)', 'color': const Color(0xFF10B981)},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  children: const [
                    Text(
                      'Admissions Pipeline Funnel',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'AY 2026-27 intake conversion & pipeline health',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '29.6% Net Yield',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Funnel Target Tracker
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Target Intake: 150 Seats',
                      style: TextStyle(color: Color(0xFF334155), fontSize: 10.5, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '142 Enrolled · 94.7% Filled',
                      style: TextStyle(color: Color(0xFF059669), fontSize: 10.5, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 142 / 150,
                    minHeight: 6,
                    backgroundColor: Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Funnel Stages List with horizontal proportional bars
          ...stages.map((st) {
            final pct = st['pct'] as double;
            final color = st['color'] as Color;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        st['stage'] as String,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${st['count']} · $pct%',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    st['sub'] as String,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5),
                  ),
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
                _buildTreeItem('Kondapur Branch', 'Suburban Campus', 290, false),
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
        border: Border.all(color: isRoot ? const Color(0xFFC4B5FD) : const Color(0xFFE2E8F0)),
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
          const Text('Student 360 Lookup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by student name or ID...',
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildSampleStudentCard('Jatin Kalidindi', 'EDU-STU-2026-00012', 'Class 6-A', 'Steel Plant Branch', 94, 78),
        ],
      ),
    );
  }

  Widget _buildSampleStudentCard(String name, String id, String klass, String branch, int att, int exam) {
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
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Active', style: TextStyle(color: Color(0xFF065F46), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Text('$id · $klass · $branch', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Attendance: $att%', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 14),
              Text('Exam Avg: $exam/100', style: const TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold)),
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
          Text('Finance & Fee Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          SizedBox(height: 8),
          Text('Double-entry ledgers, Razorpay payment flows, and overdue balances.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
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
          Text('Growth & Admissions Pipeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          SizedBox(height: 8),
          Text('Marketing campaigns, admission inquiries, conversion funnel and cost-per-admission.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
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
          Text('Academic Operations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          SizedBox(height: 8),
          Text('Timetable approvals, syllabus progress tracking, examination schedules, and merit ranks.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
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
          Text('People & Operations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          SizedBox(height: 8),
          Text('Staff requisitions, HR exits, hostel occupancy, transport tracking and procurement write-offs.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
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
              Text('My Classes & Section Governance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Icon(Icons.menu_book_rounded, color: Color(0xFF3B82F6), size: 20),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Class teacher allocations, section student strengths, active subject periods, and curriculum benchmarks.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          const SizedBox(height: 14),
          _buildClassSummaryCard('Grade 10 - Section A', '38 Students', 'Lead: M. S. Sharma', 'Mathematics (Live: Period 3)', const Color(0xFF3B82F6)),
          const SizedBox(height: 10),
          _buildClassSummaryCard('Grade 9 - Section B', '42 Students', 'Lead: Anita Deshmukh', 'Physics Lab (Room 204)', const Color(0xFF10B981)),
          const SizedBox(height: 10),
          _buildClassSummaryCard('Grade 8 - Section C', '36 Students', 'Lead: Raghavendra Rao', 'English Literature', const Color(0xFF7C3AED)),
        ],
      ),
    );
  }

  Widget _buildClassSummaryCard(String title, String count, String teacher, String status, Color color) {
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              const SizedBox(height: 3),
              Text('$count · $teacher', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
              const SizedBox(height: 3),
              Text(status, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w600)),
            ],
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }

  Widget _buildAttendanceView() {
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
              Text('Campus Attendance Command', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Icon(Icons.fact_check_rounded, color: Color(0xFF06B6D4), size: 20),
            ],
          ),
          SizedBox(height: 8),
          Text('Real-time biometric sync across all branches. Overall student attendance: 92.4%, Staff: 94.2%.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        ],
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
              Text('Curriculum & Lesson Plans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Icon(Icons.auto_stories_rounded, color: Color(0xFF10B981), size: 20),
            ],
          ),
          SizedBox(height: 8),
          Text('Weekly syllabus coverage tracking, submitted teaching plans, and Principal approval queues.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
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
              Text('Master Institutional Timetable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Icon(Icons.calendar_month_rounded, color: Color(0xFF6366F1), size: 20),
            ],
          ),
          SizedBox(height: 8),
          Text('Class-wise schedules, teacher proxy allocation engine, and room vacancy tracker.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
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
              Text('Vriyda AI Intelligence Engine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Icon(Icons.auto_awesome_rounded, color: Color(0xFFA855F7), size: 20),
            ],
          ),
          SizedBox(height: 8),
          Text('Predictive fee defaulter risk modeling, student retention warnings, and automated teacher feedback summaries.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
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
          Text('Fleet & Transport Command', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          SizedBox(height: 8),
          Text('GPS tracking of 18 campus buses, live route ETAs, and student boarding notifications.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
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
          Text('Notice Board & Circulars', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          SizedBox(height: 8),
          Text('Instant broadcast circulars, SMS parent notifications, and staff advisory bulletins.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
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
          Text('Exams, Marksheets & Grading', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          SizedBox(height: 8),
          Text('Summative assessment schedules, GPA distribution, report card generation, and board exam tracking.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
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
          Text('Staff & Faculty Directory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          SizedBox(height: 8),
          Text('Institutional employee directory, department breakdown, biometric punch logs, and role permissions.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
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
          Text(_errorMessage!, style: const TextStyle(color: Color(0xFF475569))),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchDashboard,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    final val = double.tryParse(amount.toString()) ?? 0;
    if (val >= 10000000) {
      return '${(val / 10000000).toStringAsFixed(2)} Cr';
    } else if (val >= 100000) {
      return '${(val / 100000).toStringAsFixed(2)} L';
    }
    return val.toStringAsFixed(0);
  }
}
