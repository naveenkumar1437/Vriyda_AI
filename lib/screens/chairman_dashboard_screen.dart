import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
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
  int _activeKpiSet = 0;
  bool _isArcMenuOpen = false;

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
    if (token == null) {
      _handleLogout();
      return;
    }

    try {
      final res = await http.get(
        Uri.parse(ApiConfig.ownerDashboard),
        headers: ApiConfig.authHeaders(token),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _dashboardData = body is Map<String, dynamic> ? body : null;
          _isLoading = false;
        });
      } else if (res.statusCode == 401) {
        _handleLogout();
      } else {
        setState(() {
          _errorMessage = 'Failed to load dashboard (${res.statusCode})';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Network connection issue. Pull down to retry.';
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
            RadialArcMenu(
              isOpen: _isArcMenuOpen,
              onToggle: () {
                setState(() => _isArcMenuOpen = !_isArcMenuOpen);
              },
              onItemSelected: (selectedId) {
                _switchView(selectedId);
              },
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
    return Container(
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
        // Section Title
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Core performance metrics across all campuses',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Icon(Icons.circle, color: Color(0xFF34D399), size: 6),
                  SizedBox(width: 5),
                  Text(
                    'Chairman',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 4-Card Circular Carousel Stage
        _build4CardCarousel(group),

        const SizedBox(height: 16),

        // Critical Alerts & Needs Attention Section
        _buildCriticalAlertsSection(alerts),

        const SizedBox(height: 16),

        // Branch Fee Collection Rankings
        _buildBranchRankingsCard(branches),
      ],
    );
  }

  // --- 4 Circular Cards Stage from code.html ---
  Widget _build4CardCarousel(Map<String, dynamic>? group) {
    final sets = [
      {
        'title': 'Core Performance',
        'cards': [
          {'label': 'STUDENTS', 'val': '${group?['students'] ?? 1240}', 'sub': '+12%', 'subColor': const Color(0xFF10B981)},
          {'label': 'REVENUE', 'val': '₹${_formatCurrency(group?['revenueYTD'] ?? 18500000)}', 'sub': '89%', 'subColor': const Color(0xFF7C3AED)},
          {'label': 'FEES', 'val': '${group?['collectionPct'] ?? 76.8}%', 'sub': '₹1.4 Cr', 'subColor': const Color(0xFF64748B)},
          {'label': 'ATTEND', 'val': '${group?['attendance'] ?? 92.4}%', 'sub': '94.2% Staff', 'subColor': const Color(0xFF059669)},
        ]
      },
      {
        'title': 'Academic & Ops',
        'cards': [
          {'label': 'EXAM IDX', 'val': '${group?['examIndex'] ?? 81.2}%', 'sub': 'Pass: 98%', 'subColor': const Color(0xFF10B981)},
          {'label': 'TEACHERS', 'val': '${group?['teachers'] ?? 86}', 'sub': 'Ratio 1:14', 'subColor': const Color(0xFF3B82F6)},
          {'label': 'BRANCHES', 'val': '${group?['branchesActive'] ?? 6}', 'sub': 'All Active', 'subColor': const Color(0xFF7C3AED)},
          {'label': 'CAPACITY', 'val': '${group?['capacityUtil'] ?? 82.7}%', 'sub': '1500 Max', 'subColor': const Color(0xFFF59E0B)},
        ]
      },
      {
        'title': 'Financial Summary',
        'cards': [
          {'label': 'COLLECTED', 'val': '₹${_formatCurrency(group?['collectedYTD'] ?? 14200000)}', 'sub': 'YTD', 'subColor': const Color(0xFF10B981)},
          {'label': 'OUTSTANDING', 'val': '₹${_formatCurrency(group?['outstanding'] ?? 4300000)}', 'sub': 'Overdue', 'subColor': const Color(0xFFEF4444)},
          {'label': 'PAYROLL', 'val': '₹48.2 L', 'sub': 'Disbursed', 'subColor': const Color(0xFF6366F1)},
          {'label': 'SURPLUS', 'val': '+24.5%', 'sub': 'Net Margin', 'subColor': const Color(0xFF059669)},
        ]
      },
    ];

    final currentSet = sets[_activeKpiSet % sets.length];
    final cards = currentSet['cards'] as List<Map<String, dynamic>>;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFAF5FF), Colors.white, Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9D5FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header & Dot indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currentSet['title'] as String,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: Row(
                  children: [
                    ...List.generate(sets.length, (idx) {
                      final isActive = idx == _activeKpiSet;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _activeKpiSet = idx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: isActive ? 10 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF7C3AED) : const Color(0xFFDDD6FE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 6),
                    Text(
                      '${_activeKpiSet + 1} / ${sets.length}',
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 4 Compact Circular Cards in one row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: cards.map((c) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEDE9FE)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c['label'] as String,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c['val'] as String,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: (c['subColor'] as Color).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          c['sub'] as String,
                          style: TextStyle(
                            color: c['subColor'] as Color,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Critical Alerts / Exception Section ---
  Widget _buildCriticalAlertsSection(List<dynamic> alerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Needs your attention',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Text(
          'Exception-first — the platform surfaces what is off-trend',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFEE2E2)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Critical Alerts',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Safety, finance & compliance',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Sample or Real Alerts
              if (alerts.isEmpty)
                _buildAlertRow('₹11.2 L outstanding · 38% of billed', 'Kondapur Branch · 2h ago', true)
              else
                ...alerts.map((al) => _buildAlertRow(al['text'] ?? '', '${al['branch']} · ${al['time']}', true)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertRow(String text, String meta, bool isUrgent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF43F5E), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF9F1239),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  meta,
                  style: const TextStyle(
                    color: Color(0xFFE11D48),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF43F5E),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'URGENT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Branch Performance Rankings ---
  Widget _buildBranchRankingsCard(List<dynamic> branches) {
    final sampleBranches = [
      {'name': 'Steel Plant Branch', 'pct': 82, 'amount': '₹25.0 L', 'color': const Color(0xFF10B981)},
      {'name': 'Gachibowli Campus', 'pct': 78, 'amount': '₹27.3 L', 'color': const Color(0xFF8B5CF6)},
      {'name': 'Kondapur Branch', 'pct': 78, 'amount': '₹21.4 L', 'color': const Color(0xFF06B6D4)},
      {'name': 'Kukatpally Campus', 'pct': 76, 'amount': '₹23.4 L', 'color': const Color(0xFFA855F7)},
      {'name': 'Maddipalem Branch', 'pct': 75, 'amount': '₹22.8 L', 'color': const Color(0xFFEF4444)},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Branch Fee Collections',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            'Real-time collection percentage vs target by branch',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),
          const SizedBox(height: 12),
          ...sampleBranches.map((b) => _buildBranchProgressBar(b)),
        ],
      ),
    );
  }

  Widget _buildBranchProgressBar(Map<String, dynamic> b) {
    final pct = b['pct'] as int;
    final color = b['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                b['name'] as String,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$pct% · ${b['amount']}',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
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
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
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
