import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
import '../services/auth_service.dart';
import '../services/branch_service.dart';
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
  String _activeView = 'view-branches';
  bool _isArcMenuOpen = false;

  // Interactive state for Group Overview
  int _activeKpiSet = 0;
  Timer? _kpiTimer;
  late final PageController _kpiPageController;
  final Set<String> _approvedItemIds = {};
  final Set<String> _acknowledgedAlertIds = {};

  // Interactive state for Finance & Fees
  String _financePeriod = 'YTD';
  String _financeBranch = 'All branches';

  // Interactive state for Branch Tree
  BranchGroupNode? _branchTreeData;
  bool _isBranchTreeLoading = false;
  final TextEditingController _branchSearchController = TextEditingController();
  String _branchSearchQuery = '';
  bool _isOrgTreeExpanded = true;
  String _branchPeriod = 'YTD';
  String _branchSelectedFilter = 'All branches';

  @override
  void initState() {
    super.initState();
    _kpiPageController = PageController(initialPage: _activeKpiSet);
    _branchSearchController.addListener(() {
      if (mounted) {
        setState(() {
          _branchSearchQuery = _branchSearchController.text.trim();
        });
      }
    });
    _fetchDashboard();
    _fetchBranchTree();
    _startKpiTimer();
  }

  @override
  void dispose() {
    _kpiTimer?.cancel();
    _kpiPageController.dispose();
    _branchSearchController.dispose();
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

    _fetchBranchTree();

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

  Future<void> _fetchBranchTree() async {
    setState(() => _isBranchTreeLoading = true);
    try {
      final tree = await BranchService.fetchBranchTree(
        orgName: _dashboardData?['orgName'] ?? widget.user.organizationName,
      );
      if (mounted) {
        setState(() {
          _branchTreeData = tree;
          _isBranchTreeLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _branchTreeData = BranchGroupNode.defaultTree();
          _isBranchTreeLoading = false;
        });
      }
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
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
                          fontSize: 19,
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
                          orgName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const Text(
                          'Chairman Portal · Executive View',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Row(
              children: [
                _buildHeaderIconBtn(
                  Icons.settings_outlined,
                  const Color(0xFFF59E0B),
                  _fetchDashboard,
                ),
                const SizedBox(width: 4),
                _buildHeaderIconBtn(
                  Icons.notifications_outlined,
                  const Color(0xFFF43F5E),
                  () {},
                ),
                const SizedBox(width: 4),
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
        width: 32,
        height: 32,
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
        child: Icon(icon, color: color, size: 16),
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
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
        'icon': Icons.alt_route_rounded,
      },
      {'id': 'view-users', 'label': 'Users', 'icon': Icons.people_outline},
      {'id': 'view-attendance', 'label': 'Attendance', 'icon': Icons.fact_check_outlined},
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
  Widget _buildBranchTreeView([List<dynamic>? branches]) {
    final treeData = _branchTreeData ?? BranchGroupNode.defaultTree();
    final query = _branchSearchQuery.toLowerCase();
    final filteredBranches = treeData.branches.where((b) {
      final matchesQuery =
          query.isEmpty ||
          b.name.toLowerCase().contains(query) ||
          b.code.toLowerCase().contains(query) ||
          b.city.toLowerCase().contains(query);
      final matchesDropdown =
          _branchSelectedFilter == 'All branches' ||
          b.name == _branchSelectedFilter;
      return matchesQuery && matchesDropdown;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            const Text(
              'Branch Hierarchy',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            if (_isBranchTreeLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),

        // Control bar: [MTD QTD YTD FY] [All branches v] [^ Export]
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Time Period Pill Toggle
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(2.5),
              child: Row(
                children: ['MTD', 'QTD', 'YTD', 'FY'].map((p) {
                  final isSelected = _branchPeriod == p;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _branchPeriod = p);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF7C3AED)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 4),

            // Dropdown for branches
            Flexible(
              child: PopupMenuButton<String>(
                color: Colors.white,
                elevation: 4,
                initialValue: _branchSelectedFilter,
                onSelected: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _branchSelectedFilter = val);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                itemBuilder: (ctx) {
                  final options = [
                    'All branches',
                    ...treeData.branches.map((b) => b.name),
                  ];
                  return options.map((opt) {
                    final isSel = opt == _branchSelectedFilter;
                    return PopupMenuItem(
                      value: opt,
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? const Color(0xFF7C3AED) : const Color(0xFF0F172A),
                        ),
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _branchSelectedFilter,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 15,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Export Button - always visible on screen
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Exporting ${treeData.totalBranches} branches hierarchy data...',
                    ),
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.file_upload_outlined,
                      size: 14,
                      color: Color(0xFF0F172A),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Export',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Subtitle with purple "click a row to drill down"
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 11.5, height: 1.4),
            children: [
              TextSpan(
                text: 'Branch hierarchy ',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text:
                    'Group → region → branch · roll-ups aggregate every child · ',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: 'click a row to drill down',
                style: TextStyle(
                  color: Color(0xFF7C3AED),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Organization tree Card
        Container(
          padding: const EdgeInsets.all(14),
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
              // Tree Card Header
              const Text(
                'Organization tree',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${treeData.totalBranches} branches across ${treeData.totalRegions} region',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Search Bar & Expand/Collapse Buttons Row
              Row(
                children: [
                  // Search field
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _branchSearchController,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Search branch or city...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          suffixIcon: _branchSearchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () => _branchSearchController.clear(),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Color(0xFF94A3B8),
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),

                  // EXPAND ALL button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isOrgTreeExpanded = true);
                    },
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'EXPAND ALL',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // COLLAPSE ALL button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isOrgTreeExpanded = false);
                    },
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'COLLAPSE ALL',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),

              // Scrollable Table Area
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: 420,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Table Columns Header
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: const [
                            SizedBox(
                              width: 175,
                              child: Text(
                                'BRANCH',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 65,
                              child: Text(
                                'STUDENTS',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 75,
                              child: Text(
                                'CAPACITY',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 95,
                              child: Text(
                                'COLLECTION %',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(
                        color: Color(0xFFF1F5F9),
                        height: 1,
                        thickness: 1,
                      ),

                      // Root Node (Sai Ravindra School)
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(
                            () => _isOrgTreeExpanded = !_isOrgTreeExpanded,
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 175,
                                child: Row(
                                  children: [
                                    Icon(
                                      _isOrgTreeExpanded
                                          ? Icons.keyboard_arrow_down_rounded
                                          : Icons.keyboard_arrow_right_rounded,
                                      size: 20,
                                      color: const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C3AED),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: Text(
                                          treeData.initial,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            treeData.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF0F172A),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            '${treeData.totalBranches} branches',
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 65,
                                child: Text(
                                  '${treeData.students}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 75,
                                child: Text(
                                  '${treeData.capacityPct.toStringAsFixed(treeData.capacityPct % 1 == 0 ? 0 : 1)}%',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 95,
                                child: Text(
                                  '${treeData.collectionPct.toStringAsFixed(treeData.collectionPct % 1 == 0 ? 0 : 1)}%',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Child Branch Rows
                      if (_isOrgTreeExpanded) ...[
                        if (filteredBranches.isEmpty)
                          Container(
                            width: 420,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.search_off_rounded,
                                    size: 28,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'No branches match "$_branchSearchQuery"',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () =>
                                        _branchSearchController.clear(),
                                    child: const Text(
                                      'Clear search',
                                      style: TextStyle(
                                        color: Color(0xFF7C3AED),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...filteredBranches.map((branch) {
                            return InkWell(
                              onTap: () => _showBranchDrillDown(branch),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 175,
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 24),
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: branch.dotColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  branch.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFF0F172A),
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 1),
                                                Text(
                                                  branch.subtitle,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFF94A3B8),
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 65,
                                      child: Text(
                                        '${branch.students}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 75,
                                      child: Text(
                                        '${branch.capacityPct.toStringAsFixed(branch.capacityPct % 1 == 0 ? 0 : 1)}%',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: Color(0xFF334155),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 95,
                                      child: Text(
                                        '${branch.collectionPct.toStringAsFixed(branch.collectionPct % 1 == 0 ? 0 : 1)}%',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: Color(0xFF334155),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBranchDrillDown(BranchItem branch) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: branch.dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${branch.code} · ${branch.city} · ${branch.region}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: branch.status == 'good'
                          ? const Color(0xFFDCFCE7)
                          : (branch.status == 'warning'
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      branch.status == 'good'
                          ? 'Good'
                          : (branch.status == 'warning'
                                ? 'Attention'
                                : 'Active'),
                      style: TextStyle(
                        color: branch.status == 'good'
                            ? const Color(0xFF166534)
                            : (branch.status == 'warning'
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFF334155)),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // KPI Cards Grid
              Row(
                children: [
                  Expanded(
                    child: _buildDrillCard(
                      'STUDENTS',
                      '${branch.students}',
                      '${branch.capacityPct}% of ${branch.capacity} capacity',
                      const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDrillCard(
                      'COLLECTION',
                      '${branch.collectionPct}%',
                      'Billed fees collected',
                      const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDrillCard(
                      'ATTENDANCE',
                      '${branch.attendancePct}%',
                      'Present today',
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDrillCard(
                      'FACULTY',
                      '${branch.teachers}',
                      'Exam Index: ${branch.examIndex}',
                      const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7C3AED),
                        side: const BorderSide(color: Color(0xFFDDD6FE)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _switchView('view-lookup');
                      },
                      child: const Text(
                        'View Students',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _switchView('view-finance');
                      },
                      child: const Text(
                        'View Finance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrillCard(
    String label,
    String value,
    String subtitle,
    Color accentColor,
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
          Text(
            label,
            style: TextStyle(
              color: accentColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
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
    final Map<String, dynamic> data = _getFinanceDataForPeriod(_financePeriod);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Title & Filter Bar
        const Text(
          'Finance & Fees',
          style: TextStyle(
            color: Color.fromARGB(255, 231, 231, 231),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),

        // Filter / Action Row (MTD/QTD/YTD/FY, Branch dropdown, Export)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // Period Segmented Buttons: MTD, QTD, YTD, FY
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(2.5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['MTD', 'QTD', 'YTD', 'FY'].map((p) {
                    final isSel = _financePeriod == p;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _financePeriod = p);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFFEDE9FE)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p,
                          style: TextStyle(
                            color: isSel
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: isSel
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),

              // Branch Dropdown
              PopupMenuButton<String>(
                onSelected: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _financeBranch = val);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (ctx) =>
                    [
                          'All branches',
                          'Gachibowli Campus',
                          'Maddipalem',
                          'Vizag Main',
                        ]
                        .map(
                          (b) => PopupMenuItem(
                            value: b,
                            child: Text(
                              b,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _financeBranch == b
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _financeBranch == b
                                    ? const Color.fromARGB(255, 255, 255, 255)
                                    : const Color.fromARGB(255, 5, 5, 5),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _financeBranch,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Export Button
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Exporting $_financePeriod report for $_financeBranch...',
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF7C3AED),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.file_upload_outlined,
                        size: 14,
                        color: Color(0xFF334155),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Export',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Subtitle: Finance & fees Group P&L, unit economics, collection & receivables
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            children: [
              TextSpan(
                text: 'Finance & fees ',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              TextSpan(
                text: 'Group P&L, unit economics, collection & receivables',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Primary 6-Card Metrics Grid (3 columns x 2 rows)
        Row(
          children: [
            Expanded(
              child: _buildFinanceCard(
                label: 'REVENUE · $_financePeriod',
                value: data['revenue'],
                bottomWidget: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3.5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_drop_up_rounded,
                            size: 12,
                            color: Color(0xFF16A34A),
                          ),
                          Text(
                            data['revChange'],
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        'vs target ${data['targetPct']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 8.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFinanceCard(
                label: 'COLLECTED',
                value: data['collected'],
                bottomWidget: Row(
                  children: [
                    const Icon(
                      Icons.arrow_drop_up_rounded,
                      size: 13,
                      color: Color(0xFF16A34A),
                    ),
                    Text(
                      data['collectedPct'],
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Flexible(
                      child: Text(
                        'of billed',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 8.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFinanceCard(
                label: 'OUTSTANDING',
                value: data['outstanding'],
                bottomWidget: Row(
                  children: [
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 13,
                      color: Color(0xFFDC2626),
                    ),
                    Text(
                      data['outstandingPct'],
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Flexible(
                      child: Text(
                        'receivables',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 8.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFinanceCard(
                label: 'EBITDA MARGIN',
                value: data['ebitdaMargin'],
                subtext: 'group blended',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFinanceCard(
                label: 'PAYROLL COST',
                value: data['payrollCost'],
                subtext: 'of revenue',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFinanceCard(
                label: 'ONLINE PAYMENTS',
                value: data['onlinePayments'],
                subtext: 'Razorpay share',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 3. Section Divider: EXPENSES · ACADEMIC YEAR TO DATE
        const Text(
          'EXPENSES · ACADEMIC YEAR TO DATE',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),

        // 4. Expenses 6-Card Grid (3 columns x 2 rows)
        Row(
          children: [
            Expanded(
              child: _buildFinanceCard(
                label: 'TOTAL SPEND · $_financePeriod',
                value: data['totalSpend'],
                subtext: 'all expense lines',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFinanceCard(
                label: 'PAYROLL · $_financePeriod',
                value: data['expensePayroll'],
                subtext: 'submitted salary slips',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFinanceCard(
                label: 'RENT · MONTHLY',
                value: '—',
                subtext: 'committed, not posted',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFinanceCard(
                label: 'FUEL & FLEET · $_financePeriod',
                value: data['fuelFleet'],
                subtext: 'no fuel logged yet',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFinanceCard(
                label: 'PURCHASES · $_financePeriod',
                value: data['purchases'],
                subtext: '4 line items',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFinanceCard(
                label: 'STAFF CLAIMS · $_financePeriod',
                value: data['staffClaims'],
                subtext: 'approved reimbursements',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 5. Chart Card: Revenue vs operating expenses
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Legend
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Revenue vs operating expenses',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Trailing 12 months · ₹ crore',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7C3AED),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Revenue',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 2,
                            decoration: BoxDecoration(
                              color: const Color(0xFF64748B),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Expenses',
                            style: TextStyle(
                              color: Color(0xFF64748B),
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
              const SizedBox(height: 16),

              // Trailing 12 Chart Canvas
              SizedBox(
                height: 130,
                width: double.infinity,
                child: CustomPaint(painter: FinanceTrailing12Painter()),
              ),
              const SizedBox(height: 6),

              // Monthly X-Axis labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Apr',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'May',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Jun',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Jul',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Aug',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Sep',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Oct',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Nov',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Dec',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Jan',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Feb',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Mar',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceCard({
    required String label,
    required String value,
    Widget? bottomWidget,
    String? subtext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (bottomWidget != null)
            bottomWidget
          else if (subtext != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                subtext,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getFinanceDataForPeriod(String period) {
    switch (period) {
      case 'MTD':
        return {
          'revenue': '₹18.5 L',
          'revChange': '+5.2%',
          'targetPct': '95%',
          'collected': '₹14.2 L',
          'collectedPct': '76.8%',
          'outstanding': '₹4.3 L',
          'outstandingPct': '23.2%',
          'ebitdaMargin': '38.2%',
          'payrollCost': '42.0%',
          'onlinePayments': '78.5%',
          'totalSpend': '₹42,000',
          'expensePayroll': '₹50,000',
          'fuelFleet': '₹1,200',
          'purchases': '₹3,400',
          'staffClaims': '₹18,500',
        };
      case 'QTD':
        return {
          'revenue': '₹48.2 L',
          'revChange': '+6.4%',
          'targetPct': '90%',
          'collected': '₹36.5 L',
          'collectedPct': '75.7%',
          'outstanding': '₹11.7 L',
          'outstandingPct': '24.3%',
          'ebitdaMargin': '36.4%',
          'payrollCost': '44.2%',
          'onlinePayments': '72.1%',
          'totalSpend': '₹1.1 L',
          'expensePayroll': '₹50,000',
          'fuelFleet': '₹2,800',
          'purchases': '₹7,500',
          'staffClaims': '₹85,000',
        };
      case 'FY':
        return {
          'revenue': '₹1.8 Cr',
          'revChange': '+8.0%',
          'targetPct': '94%',
          'collected': '₹1.2 Cr',
          'collectedPct': '66.7%',
          'outstanding': '₹60.0 L',
          'outstandingPct': '33.3%',
          'ebitdaMargin': '34.5%',
          'payrollCost': '46.0%',
          'onlinePayments': '69.5%',
          'totalSpend': '₹4.1 L',
          'expensePayroll': '₹50,000',
          'fuelFleet': '₹6,500',
          'purchases': '₹15,800',
          'staffClaims': '₹3.2 L',
        };
      case 'YTD':
      default:
        return {
          'revenue': '₹1.4 Cr',
          'revChange': '+7.1%',
          'targetPct': '92%',
          'collected': '₹95.0 L',
          'collectedPct': '67.8%',
          'outstanding': '₹45.1 L',
          'outstandingPct': '32.2%',
          'ebitdaMargin': '35.8%',
          'payrollCost': '45.1%',
          'onlinePayments': '70.3%',
          'totalSpend': '₹3.2 L',
          'expensePayroll': '₹50,000',
          'fuelFleet': '₹5,000',
          'purchases': '₹12,200',
          'staffClaims': '₹2.6 L',
        };
    }
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

  Widget _buildAttendanceView() {
    final dummyBranches = [
      {
        'name': 'Steel Plant Branch',
        'studentPct': 93.1,
        'studentPresent': 391,
        'studentRoster': 420,
        'studentAbsent': 22,
        'studentLeave': 7,
        'staffPct': 93.3,
        'staffPresent': 42,
        'staffRoster': 45,
      },
      {
        'name': 'Gachibowli Campus',
        'studentPct': 94.8,
        'studentPresent': 360,
        'studentRoster': 380,
        'studentAbsent': 14,
        'studentLeave': 6,
        'staffPct': 95.2,
        'staffPresent': 40,
        'staffRoster': 42,
      },
      {
        'name': 'Kondapur Branch',
        'studentPct': 89.6,
        'studentPresent': 278,
        'studentRoster': 310,
        'studentAbsent': 24,
        'studentLeave': 8,
        'staffPct': 91.4,
        'staffPresent': 32,
        'staffRoster': 35,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                children: [
                  const Expanded(
                    child: Text(
                      'Campus Attendance',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFEFF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA5F3FC)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fact_check_rounded, color: Color(0xFF0891B2), size: 13),
                        SizedBox(width: 4),
                        Text(
                          'DUMMY PREVIEW',
                          style: TextStyle(
                            color: Color(0xFF0891B2),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Group-wide student & staff daily attendance snapshot across branches.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildAttendanceStatTile(
                      label: 'Students Present',
                      value: '92.4%',
                      subtext: '1,029 / 1,110',
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAttendanceStatTile(
                      label: 'Staff Present',
                      value: '93.4%',
                      subtext: '114 / 122',
                      color: const Color(0xFF7C3AED),
                      bgColor: const Color(0xFFF5F3FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildAttendanceStatTile(
                      label: 'Absent Today',
                      value: '60',
                      subtext: 'Students across 3 branches',
                      color: const Color(0xFFEF4444),
                      bgColor: const Color(0xFFFEF2F2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAttendanceStatTile(
                      label: 'On Leave',
                      value: '21',
                      subtext: 'Approved leaves',
                      color: const Color(0xFFF59E0B),
                      bgColor: const Color(0xFFFFFBEB),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
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
                'Branch Breakdown',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              ...dummyBranches.map((branch) {
                final studentPct = branch['studentPct'] as double;
                final staffPct = branch['staffPct'] as double;
                final isLow = studentPct < 90.0;
                final barColor = isLow ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
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
                          Expanded(
                            child: Text(
                              branch['name'] as String,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '${studentPct.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: barColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (studentPct / 100).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Students: ${branch['studentPresent']}/${branch['studentRoster']}',
                            style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                          ),
                          Text(
                            'Absent: ${branch['studentAbsent']}',
                            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
                          ),
                          Text(
                            'Leave: ${branch['studentLeave']}',
                            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11),
                          ),
                          Text(
                            'Staff: ${branch['staffPresent']}/${branch['staffRoster']} (${staffPct.toStringAsFixed(1)}%)',
                            style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 11),
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
    );
  }

  Widget _buildAttendanceStatTile({
    required String label,
    required String value,
    required String subtext,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
            ),
          ),
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

// =============================================================================
// CUSTOM PAINTER: Finance Trailing 12 Months Revenue vs Expenses
// =============================================================================
class FinanceTrailing12Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Horizontal dashed grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
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

    drawDashedLine(h * 0.15);
    drawDashedLine(h * 0.45);
    drawDashedLine(h * 0.75);

    // 12 Normalized monthly points (Apr to Mar)
    final revNorms = [
      0.75,
      0.68,
      0.62,
      0.58,
      0.50,
      0.45,
      0.42,
      0.35,
      0.30,
      0.25,
      0.20,
      0.14,
    ];
    final expNorms = [
      0.82,
      0.79,
      0.75,
      0.72,
      0.68,
      0.65,
      0.62,
      0.58,
      0.55,
      0.52,
      0.48,
      0.45,
    ];

    final revPoints = <Offset>[];
    final expPoints = <Offset>[];

    for (int i = 0; i < 12; i++) {
      final x = (i / 11.0) * w;
      revPoints.add(Offset(x, revNorms[i] * h));
      expPoints.add(Offset(x, expNorms[i] * h));
    }

    // Revenue Area Gradient
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
          const Color(0xFF7C3AED).withValues(alpha: 0.18),
          const Color(0xFF7C3AED).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, fillPaint);

    // Revenue Stroke
    final revStrokePaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(revPath, revStrokePaint);

    // Expenses Curve
    final expPath = Path()..moveTo(expPoints[0].dx, expPoints[0].dy);
    for (int i = 1; i < expPoints.length; i++) {
      final p0 = expPoints[i - 1];
      final p1 = expPoints[i];
      final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      expPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    final expStrokePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(expPath, expStrokePaint);

    // Endpoint Glowing Dots
    final dotFill = Paint()..color = Colors.white;
    final dotStroke = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final lastRev = revPoints.last;
    canvas.drawCircle(lastRev, 4.5, dotFill);
    canvas.drawCircle(lastRev, 4.5, dotStroke);

    final expDotStroke = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final lastExp = expPoints.last;
    canvas.drawCircle(lastExp, 3.5, dotFill);
    canvas.drawCircle(lastExp, 3.5, expDotStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
