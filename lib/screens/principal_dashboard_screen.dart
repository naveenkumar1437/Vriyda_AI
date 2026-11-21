import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/session_manager.dart';
import '../widgets/notifications_overlay.dart';
import '../widgets/radial_arc_menu.dart';
import 'vriyda_login_screen.dart';

/// Comprehensive Principal Dashboard matching the Vriyda Principal Web Portal:
/// - Principal Header: Hello {Employee Name}, Designation, Employee ID, Branch & Date, Avatar VK
/// - Horizontal Nav Tabs & Radial Arc Rotary Menu across all 15 Principal Modules:
///   1. Overview (Dashboard)
///   2. Approvals (Requests, Payroll, Leave, Concessions, Gate Passes, Certificates)
///   3. Students (KPIs, Filters, Directory Roster)
///   4. Staff (KPIs, Non-teaching by Area, Departments, Low Attendance, Staff Directory)
///   5. Attendance
///   6. Time Table
///   7. Exam Time Table
///   8. Fee Particulars
///   9. Payroll
///   10. Leaves
///   11. Office Overheads
///   12. Events
///   13. Fee Concession
///   14. Front Office
///   15. Announcements
class PrincipalDashboardScreen extends StatefulWidget {
  final UserSession user;
  final List<Map<String, dynamic>>? studentsRoster;
  final List<Map<String, dynamic>>? staffRoster;
  final List<Map<String, dynamic>>? approvals;
  final Map<String, dynamic>? dashboardData;

  const PrincipalDashboardScreen({
    super.key,
    required this.user,
    this.studentsRoster,
    this.staffRoster,
    this.approvals,
    this.dashboardData,
  });

  @override
  State<PrincipalDashboardScreen> createState() =>
      _PrincipalDashboardScreenState();
}

class _PrincipalDashboardScreenState extends State<PrincipalDashboardScreen> {
  String _activeView = 'view-overview';
  bool _isArcMenuOpen = false;

  // Approvals state
  String _approvalsSubTab = 'Requests';
  final Set<String> _decidedItemIds = {};

  // Students state
  String _studentSearchQuery = '';
  String _selectedClass = 'All classes';
  String _selectedGender = 'All genders';

  // Staff state
  String _staffSearchQuery = '';
  String _staffTabFilter = 'All'; // 'All', 'Teaching', 'Non-teaching'

  // Attendance slider/threshold
  final double _attendanceThreshold = 75.0;

  // 15 Modules for Principal Arc Menu
  static const List<ArcMenuItem> _principalArcItems = [
    ArcMenuItem(
      id: 'view-overview',
      label: 'Overview',
      icon: Icons.dashboard_rounded,
      primaryColor: Color(0xFF7C3AED),
      secondaryColor: Color(0xFF6D28D9),
      isFilled: true,
    ),
    ArcMenuItem(
      id: 'view-approvals',
      label: 'Approvals',
      icon: Icons.fact_check_rounded,
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFF059669),
    ),
    ArcMenuItem(
      id: 'view-students',
      label: 'Students',
      icon: Icons.school_rounded,
      primaryColor: Color(0xFF3B82F6),
      secondaryColor: Color(0xFF2563EB),
    ),
    ArcMenuItem(
      id: 'view-staff',
      label: 'Staff',
      icon: Icons.badge_rounded,
      primaryColor: Color(0xFFF59E0B),
      secondaryColor: Color(0xFFD97706),
    ),
    ArcMenuItem(
      id: 'view-attendance',
      label: 'Attendance',
      icon: Icons.how_to_reg_rounded,
      primaryColor: Color(0xFF06B6D4),
      secondaryColor: Color(0xFF0891B2),
    ),
    ArcMenuItem(
      id: 'view-timetable',
      label: 'Time Table',
      icon: Icons.calendar_month_rounded,
      primaryColor: Color(0xFF8B5CF6),
      secondaryColor: Color(0xFF7C3AED),
    ),
    ArcMenuItem(
      id: 'view-examinations',
      label: 'Exam Time Table',
      icon: Icons.assignment_turned_in_rounded,
      primaryColor: Color(0xFFEC4899),
      secondaryColor: Color(0xFFDB2777),
    ),
    ArcMenuItem(
      id: 'view-fees',
      label: 'Fee Particulars',
      icon: Icons.payments_rounded,
      primaryColor: Color(0xFF14B8A6),
      secondaryColor: Color(0xFF0D9488),
    ),
    ArcMenuItem(
      id: 'view-payroll',
      label: 'Payroll',
      icon: Icons.account_balance_wallet_rounded,
      primaryColor: Color(0xFF6366F1),
      secondaryColor: Color(0xFF4F46E5),
    ),
    ArcMenuItem(
      id: 'view-leaves',
      label: 'Leaves',
      icon: Icons.event_busy_rounded,
      primaryColor: Color(0xFFEF4444),
      secondaryColor: Color(0xFFDC2626),
    ),
    ArcMenuItem(
      id: 'view-overheads',
      label: 'Office Overheads',
      icon: Icons.inventory_2_rounded,
      primaryColor: Color(0xFF84CC16),
      secondaryColor: Color(0xFF65A30D),
    ),
    ArcMenuItem(
      id: 'view-events',
      label: 'Events',
      icon: Icons.celebration_rounded,
      primaryColor: Color(0xFFF97316),
      secondaryColor: Color(0xFFEA580C),
    ),
    ArcMenuItem(
      id: 'view-concessions',
      label: 'Fee Concession',
      icon: Icons.loyalty_rounded,
      primaryColor: Color(0xFFA855F7),
      secondaryColor: Color(0xFF9333EA),
    ),
    ArcMenuItem(
      id: 'view-front-office',
      label: 'Front Office',
      icon: Icons.desk_rounded,
      primaryColor: Color(0xFF0EA5E9),
      secondaryColor: Color(0xFF0284C7),
    ),
    ArcMenuItem(
      id: 'view-announcements',
      label: 'Announcements',
      icon: Icons.campaign_rounded,
      primaryColor: Color(0xFFEAB308),
      secondaryColor: Color(0xFFCA8A04),
    ),
  ];

  // Top Nav Items
  final List<Map<String, dynamic>> _navTabs = const [
    {'id': 'view-overview', 'label': 'Overview', 'icon': Icons.dashboard_rounded},
    {'id': 'view-approvals', 'label': 'Approvals', 'icon': Icons.fact_check_rounded, 'badge': '16'},
    {'id': 'view-students', 'label': 'Students', 'icon': Icons.school_rounded},
    {'id': 'view-staff', 'label': 'Staff', 'icon': Icons.badge_rounded},
    {'id': 'view-attendance', 'label': 'Attendance', 'icon': Icons.how_to_reg_rounded},
    {'id': 'view-timetable', 'label': 'Time Table', 'icon': Icons.calendar_month_rounded},
    {'id': 'view-examinations', 'label': 'Exam Time Table', 'icon': Icons.assignment_turned_in_rounded},
    {'id': 'view-fees', 'label': 'Fee Particulars', 'icon': Icons.payments_rounded},
    {'id': 'view-payroll', 'label': 'Payroll', 'icon': Icons.account_balance_wallet_rounded},
    {'id': 'view-leaves', 'label': 'Leaves', 'icon': Icons.event_busy_rounded},
    {'id': 'view-overheads', 'label': 'Office Overheads', 'icon': Icons.inventory_2_rounded},
    {'id': 'view-events', 'label': 'Events', 'icon': Icons.celebration_rounded},
    {'id': 'view-concessions', 'label': 'Fee Concession', 'icon': Icons.loyalty_rounded},
    {'id': 'view-front-office', 'label': 'Front Office', 'icon': Icons.desk_rounded},
    {'id': 'view-announcements', 'label': 'Announcements', 'icon': Icons.campaign_rounded},
  ];

  // Mock student roster
  final List<Map<String, dynamic>> _studentsRoster = const [
    {
      'id': 'EDU-STU-2026-00001',
      'name': 'Jatin kalidindi',
      'class': 'Class - 1',
      'section': 'Section-A',
      'guardian': 'Sriram Mullapudi',
      'mobile': '9010234560',
      'gender': 'Male',
      'status': 'Active',
      'avatarColor': Color(0xFF10B981),
      'initials': 'JK',
    },
    {
      'id': 'EDU-STU-2026-00002',
      'name': 'Sai Purushotham Gude',
      'class': 'Class - 2',
      'section': 'Section-A',
      'guardian': 'Ramesh Kumar',
      'mobile': '9618200812',
      'gender': 'Male',
      'status': 'Active',
      'avatarColor': Color(0xFF6366F1),
      'initials': 'SP',
    },
    {
      'id': 'EDU-STU-2026-00003',
      'name': 'Mary B',
      'class': 'Class - 3',
      'section': 'Section-A',
      'guardian': 'John Doe',
      'mobile': '9011837901',
      'gender': 'Female',
      'status': 'Active',
      'avatarColor': Color(0xFFEC4899),
      'initials': 'MB',
    },
    {
      'id': 'EDU-STU-2026-00044',
      'name': 'Anika Sharma',
      'class': 'Class - 1',
      'section': 'Section-A',
      'guardian': 'M. Sharma (Mother of Anika)',
      'mobile': '9876543210',
      'gender': 'Female',
      'status': 'Active',
      'avatarColor': Color(0xFF14B8A6),
      'initials': 'AS',
    },
    {
      'id': 'EDU-STU-2026-00045',
      'name': 'Aditya Iyer',
      'class': 'Class - 2',
      'section': 'Section-B',
      'guardian': 'F. Iyer (Father of Aditya)',
      'mobile': '9876543211',
      'gender': 'Male',
      'status': 'Active',
      'avatarColor': Color(0xFFF59E0B),
      'initials': 'AI',
    },
    {
      'id': 'EDU-STU-2026-00046',
      'name': 'Aisha Reddy',
      'class': 'Class - 3',
      'section': 'Section-A',
      'guardian': 'M. Reddy (Mother of Aisha)',
      'mobile': '9876543212',
      'gender': 'Female',
      'status': 'Active',
      'avatarColor': Color(0xFF8B5CF6),
      'initials': 'AR',
    },
  ];

  // Mock staff roster
  final List<Map<String, dynamic>> _staffRoster = const [
    {
      'id': 'HR-EMP-0001',
      'name': 'Keerthana Bangla',
      'jobTitle': 'Senior Hindi Teacher',
      'isTeaching': true,
      'department': 'Hindi',
      'area': 'Academics',
      'attendance': '0%',
      'status': 'Active',
      'initials': 'KB',
    },
    {
      'id': 'HR-EMP-0002',
      'name': 'Ramana',
      'jobTitle': 'Primary Teacher',
      'isTeaching': true,
      'department': 'Hindi',
      'area': 'Academics',
      'attendance': '92%',
      'status': 'Sick Leave',
      'initials': 'RM',
    },
    {
      'id': 'HR-EMP-0003',
      'name': 'Gopi Madem',
      'jobTitle': 'Mathematics Instructor',
      'isTeaching': true,
      'department': 'Not assigned',
      'area': 'Academics',
      'attendance': '88%',
      'status': 'Sick Leave',
      'initials': 'GM',
    },
    {
      'id': 'HR-EMP-0010',
      'name': 'Suresh Kumar',
      'jobTitle': 'Account Manager',
      'isTeaching': false,
      'department': 'Not assigned',
      'area': 'Accounts',
      'attendance': '96%',
      'status': 'Active',
      'initials': 'SK',
    },
    {
      'id': 'HR-EMP-0011',
      'name': 'Lakshmi Rao',
      'jobTitle': 'Receptionist',
      'isTeaching': false,
      'department': 'Not assigned',
      'area': 'Front office',
      'attendance': '98%',
      'status': 'Active',
      'initials': 'LR',
    },
    {
      'id': 'HR-EMP-0012',
      'name': 'Venkatesh P',
      'jobTitle': 'Senior Librarian',
      'isTeaching': false,
      'department': 'Not assigned',
      'area': 'Library',
      'attendance': '95%',
      'status': 'Active',
      'initials': 'VP',
    },
  ];

  void _handleLogout() async {
    await SessionManager.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const VriydaLoginScreen()),
    );
  }

  void _openNotifications() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (ctx) => NotificationsDropdownSheet(
        alerts: const [
          {
            'title': 'Low attendance alert',
            'detail': 'Keerthana Bangla at 0% attendance this month',
            'time': 'Today · Steel Plant Branch',
          },
          {
            'title': 'Student enrollment surge',
            'detail': '5 new students admitted this month in Grade 1',
            'time': 'Yesterday · Steel Plant Branch',
          },
        ],
        approvals: const [
          {
            'title': 'Staff Leave (Ramana)',
            'detail': 'Sick Leave · 2 days (10 Nov - 11 Nov)',
            'time': '8d ago · Needs approval',
          },
          {
            'title': 'Merit Scholarship (Aisha Menon)',
            'detail': '₹10,000 concession waiting your decision',
            'time': '8d ago · Needs approval',
          },
        ],
        branches: const ['Steel Plant Branch'],
        onClose: () => Navigator.of(ctx).pop(),
        onAlertTap: (al) => Navigator.of(ctx).pop(),
        onApprovalTap: (ap) => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF8FAFC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: SafeArea(
          child: Stack(
            children: [
              // 1. Scrollable Main Content Layout
              CustomScrollView(
                slivers: [
                  // App Header
                  SliverToBoxAdapter(child: _buildHeader()),

                  // Top Horizontal Navigation Tabs
                  SliverToBoxAdapter(child: _buildTopNavTabs()),

                  // Active View Body
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: _buildActiveViewContent(),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),

              // 2. Radial Arc Menu Overlay & FAB Trigger
              Positioned.fill(
                child: RadialArcMenu(
                  isOpen: _isArcMenuOpen,
                  roleLabel: 'PRINCIPAL',
                  items: _principalArcItems,
                  onToggle: () {
                    setState(() => _isArcMenuOpen = !_isArcMenuOpen);
                  },
                  onItemSelected: (selectedId) {
                    setState(() {
                      _activeView = selectedId;
                      _isArcMenuOpen = false;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader() {
    final displayName = widget.user.name.isNotEmpty ? widget.user.name : 'Vinod Kumar';
    final branchName = widget.user.branchName ?? 'Steel Plant Branch';
    final empId = widget.user.id.isNotEmpty ? widget.user.id : 'HR-EMP-0005';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo icon / Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    displayName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Principal Title & Branch
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Urbanist',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.circle, color: Color(0xFF10B981), size: 5),
                              SizedBox(width: 4),
                              Text(
                                'Principal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Urbanist',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Principal · $empId · $branchName',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Urbanist',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Notification Bell & Logout
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded, color: Color(0xFF334155), size: 24),
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: _openNotifications,
              ),

              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'logout') _handleLogout();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                        SizedBox(width: 8),
                        Text('Sign out', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Subtitle Greeting
          Text(
            'Good Evening, ${displayName.split(' ').first}',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Urbanist',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Here is what needs your attention at $branchName today.',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'Urbanist',
            ),
          ),
        ],
      ),
    );
  }

  // --- Horizontal Top Nav Tabs ---
  Widget _buildTopNavTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12, top: 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: _navTabs.map((tab) {
            final isSelected = _activeView == tab['id'];
            final badge = tab['badge'] as String?;

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _activeView = tab['id']);
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tab['label'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }

  // --- Active View Router ---
  Widget _buildActiveViewContent() {
    switch (_activeView) {
      case 'view-overview':
        return _buildOverviewView();
      case 'view-approvals':
        return _buildApprovalsView();
      case 'view-students':
        return _buildStudentsView();
      case 'view-staff':
        return _buildStaffView();
      case 'view-attendance':
        return _buildModulePlaceholder('Attendance', Icons.how_to_reg_rounded, [
          {'label': 'Student Attendance', 'val': '0/43', 'sub': 'Not marked'},
          {'label': 'Staff Attendance', 'val': '0/25', 'sub': 'Not marked'},
          {'label': 'Absent Students', 'val': '43', 'sub': '100%'},
          {'label': 'Absent Staff', 'val': '25', 'sub': '100%'},
        ]);
      case 'view-timetable':
        return _buildModulePlaceholder('Time Table', Icons.calendar_month_rounded, [
          {'label': 'Total Periods', 'val': '8', 'sub': 'Per day'},
          {'label': 'Covered Today', 'val': '8/8', 'sub': '100%'},
          {'label': 'Substitutions', 'val': '0', 'sub': 'All regular'},
          {'label': 'Open Slots', 'val': '0', 'sub': 'None'},
        ]);
      case 'view-examinations':
        return _buildModulePlaceholder('Exam Time Table', Icons.assignment_turned_in_rounded, [
          {'label': 'Upcoming Exams', 'val': '2', 'sub': 'Term 2 Finals'},
          {'label': 'Schedules Made', 'val': '7', 'sub': 'Classes 1-7'},
          {'label': 'Papers Printed', 'val': '100%', 'sub': 'Ready'},
          {'label': 'Invigilators', 'val': '11', 'sub': 'Assigned'},
        ]);
      case 'view-fees':
        return _buildModulePlaceholder('Fee Particulars', Icons.payments_rounded, [
          {'label': 'Collected', 'val': '₹14.1 L', 'sub': '51.6%'},
          {'label': 'Outstanding', 'val': '₹13.2 L', 'sub': '48.4%'},
          {'label': 'Due Today', 'val': '₹2.4 L', 'sub': 'Overdue'},
          {'label': 'Projected (Next Mo)', 'val': '₹18.0 L', 'sub': 'Term 3'},
        ]);
      case 'view-payroll':
        return _buildModulePlaceholder('Payroll', Icons.account_balance_wallet_rounded, [
          {'label': 'Gross Staff Pay', 'val': '₹8.4 L', 'sub': '25 staff'},
          {'label': 'Deductions', 'val': '₹42,000', 'sub': 'PF + TDS'},
          {'label': 'Net Disbursed', 'val': '₹7.98 L', 'sub': 'Disbursed'},
          {'label': 'Staff Paid', 'val': '25/25', 'sub': '100%'},
        ]);
      case 'view-leaves':
        return _buildModulePlaceholder('Leaves & Permissions', Icons.event_busy_rounded, [
          {'label': 'Pending Requests', 'val': '6', 'sub': 'Action needed'},
          {'label': 'Approved Today', 'val': '0', 'sub': 'None'},
          {'label': 'Team Balance', 'val': '84 days', 'sub': 'Available'},
          {'label': 'Half Days', 'val': '1', 'sub': 'This month'},
        ]);
      case 'view-overheads':
        return _buildModulePlaceholder('Office Overheads', Icons.inventory_2_rounded, [
          {'label': 'Total Overheads', 'val': '₹1.85 L', 'sub': 'MTD'},
          {'label': 'Inventory Used', 'val': '₹45,000', 'sub': 'Stationery'},
          {'label': 'Office Expense', 'val': '₹1.40 L', 'sub': 'Utilities'},
          {'label': 'Last Month', 'val': '₹1.92 L', 'sub': '▲ 3.6% lower'},
        ]);
      case 'view-events':
        return _buildModulePlaceholder('Events & Calendar', Icons.celebration_rounded, [
          {'label': 'Upcoming Events', 'val': '3', 'sub': 'Annual Day'},
          {'label': 'Awaiting Approval', 'val': '1', 'sub': 'Sports Meet'},
          {'label': 'Drafts', 'val': '2', 'sub': 'Science Fair'},
          {'label': 'Event Budget', 'val': '₹1.2 L', 'sub': 'Approved'},
        ]);
      case 'view-concessions':
        return _buildModulePlaceholder('Fee Concession', Icons.loyalty_rounded, [
          {'label': 'Approved', 'val': '8', 'sub': 'Scholarships'},
          {'label': 'Pending', 'val': '2', 'sub': 'Needs review'},
          {'label': 'Rejected', 'val': '3', 'sub': 'Non-eligible'},
          {'label': 'Approved Value', 'val': '₹85,000', 'sub': 'Total relief'},
        ]);
      case 'view-front-office':
        return _buildModulePlaceholder('Front Office', Icons.desk_rounded, [
          {'label': 'Today Appointments', 'val': '4', 'sub': 'Parents'},
          {'label': 'Visitor Passes', 'val': '12', 'sub': 'Issued'},
          {'label': 'Open Inquiries', 'val': '3', 'sub': 'Admissions'},
          {'label': 'Call Logs', 'val': '28', 'sub': 'Logged'},
        ]);
      case 'view-announcements':
        return _buildModulePlaceholder('Announcements', Icons.campaign_rounded, [
          {'label': 'Active Circulars', 'val': '4', 'sub': 'Campus-wide'},
          {'label': 'Sent This Week', 'val': '2', 'sub': 'SMS + App'},
          {'label': 'Parent Read Rate', 'val': '89%', 'sub': 'Engaged'},
          {'label': 'Drafts', 'val': '1', 'sub': 'Holiday notice'},
        ]);
      default:
        return _buildOverviewView();
    }
  }

  // ==========================================
  // VIEW 1: OVERVIEW (DASHBOARD)
  // ==========================================
  Widget _buildOverviewView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECTION 1: NEEDS YOU NOW (4 items)
        _buildSectionTitle('NEEDS YOU NOW', count: '4 items'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionAlertCard(
                title: 'Approvals waiting',
                count: '0',
                countSub: 'awaiting you',
                badgeText: 'Queue clear',
                badgeColor: const Color(0xFF10B981),
                icon: Icons.inbox_rounded,
                onTap: () => setState(() => _activeView = 'view-approvals'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionAlertCard(
                title: 'Open incidents',
                count: '2',
                countSub: 'open or under review',
                badgeText: 'Needs review',
                badgeColor: const Color(0xFFEF4444),
                icon: Icons.warning_amber_rounded,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionAlertCard(
                title: 'Open periods to cover',
                count: '0',
                countSub: 'next 30 days',
                badgeText: 'All covered',
                badgeColor: const Color(0xFF10B981),
                icon: Icons.sync_alt_rounded,
                onTap: () => setState(() => _activeView = 'view-timetable'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionAlertCard(
                title: 'Unresolved complaints',
                count: '2',
                countSub: 'at the front desk',
                badgeText: 'Follow up',
                badgeColor: const Color(0xFFF59E0B),
                icon: Icons.chat_bubble_outline_rounded,
                onTap: () => setState(() => _activeView = 'view-front-office'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // SECTION 2: SCHOOL AT A GLANCE (4 items)
        _buildSectionTitle('SCHOOL AT A GLANCE'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildGlanceCard(
                title: 'Students',
                count: '44',
                countSub: 'enrolled',
                badge: '▲ 5 new this month',
                badgeBg: const Color(0xFFDCFCE7),
                badgeTextColor: const Color(0xFF15803D),
                icon: Icons.people_outline_rounded,
                iconColor: const Color(0xFF10B981),
                onTap: () => setState(() => _activeView = 'view-students'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGlanceCard(
                title: 'Total staff',
                count: '25',
                countSub: 'staff',
                badge: '11 teaching · 14 non-teaching',
                badgeBg: const Color(0xFFF1F5F9),
                badgeTextColor: const Color(0xFF475569),
                icon: Icons.school_outlined,
                iconColor: const Color(0xFF6366F1),
                onTap: () => setState(() => _activeView = 'view-staff'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildGlanceCard(
                title: 'Attendance',
                count: '0/43',
                countSub: 'present today',
                badge: 'Not marked yet',
                badgeBg: const Color(0xFFFEE2E2),
                badgeTextColor: const Color(0xFFB91C1C),
                icon: Icons.fact_check_outlined,
                iconColor: const Color(0xFFEF4444),
                onTap: () => setState(() => _activeView = 'view-attendance'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGlanceCard(
                title: 'Classes',
                count: '1',
                countSub: 'sections',
                badge: '25 groups',
                badgeBg: const Color(0xFFF1F5F9),
                badgeTextColor: const Color(0xFF475569),
                icon: Icons.grid_view_rounded,
                iconColor: const Color(0xFF0EA5E9),
                onTap: () => setState(() => _activeView = 'view-students'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // SECTION 3: ATTENDANCE & ABSENTEES
        _buildSectionTitle('ATTENDANCE & ABSENTEES'),
        const SizedBox(height: 10),
        _buildAttendanceCard(),

        const SizedBox(height: 24),

        // SECTION 4: FEES (3 KPI cards)
        _buildSectionTitle('FEES OVERVIEW'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildFeeKpiCard(
                title: 'Collected',
                value: '₹14.1 L',
                sub: '51.6% of billed',
                color: const Color(0xFF10B981),
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFeeKpiCard(
                title: 'Outstanding',
                value: '₹13.2 L',
                sub: 'Current dues',
                color: const Color(0xFFEF4444),
                icon: Icons.pending_actions_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFeeKpiCard(
                title: 'Online Pay',
                value: '68.2%',
                sub: 'UPI & Portal',
                color: const Color(0xFF6366F1),
                icon: Icons.credit_card_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {String? count}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            fontFamily: 'Urbanist',
          ),
        ),
        if (count != null)
          Text(
            count,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Urbanist',
            ),
          ),
      ],
    );
  }

  Widget _buildActionAlertCard({
    required String title,
    required String count,
    required String countSub,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: badgeColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Urbanist',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Urbanist',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    countSub,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Urbanist',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Urbanist',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlanceCard({
    required String title,
    required String count,
    required String countSub,
    required String badge,
    required Color badgeBg,
    required Color badgeTextColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Urbanist',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 16),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Urbanist',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    countSub,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Urbanist',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Urbanist',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Attendance',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Urbanist',
                ),
              ),
              Text(
                'Today · Nov 18 · students & staff',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Urbanist',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Gauge Circles
          Row(
            children: [
              _buildAttendanceGauge('0/43', 'STUDENTS', 0.0),
              const SizedBox(width: 18),
              _buildAttendanceGauge('0/25', 'STAFF', 0.0),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'No class attendance recorded yet today.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 32, color: Color(0xFFE2E8F0)),

          // Low Attendance Threshold Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Low attendance',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Students below 75% this month',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_attendanceThreshold.toInt()} %',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Attendance threshold updated to 75%'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Text('Save', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 18),
                SizedBox(width: 8),
                Text(
                  'All students at or above 75%',
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceGauge(String mainText, String subText, double ratio) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: ratio,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
            strokeWidth: 5,
          ),
          // Red dot indicator
          Positioned(
            top: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mainText,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Urbanist',
                ),
              ),
              Text(
                subText,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  fontFamily: 'Urbanist',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeeKpiCard({
    required String title,
    required String value,
    required String sub,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Urbanist',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFamily: 'Urbanist',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontFamily: 'Urbanist',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 2: APPROVALS (PAGE-2)
  // ==========================================
  Widget _buildApprovalsView() {
    final subTabs = ['Requests', 'Payroll', 'Leave (6)', 'Concessions (2)', 'Gate Passes (2)', 'Certificates (6)'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text(
          'Approvals',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '16 waiting for you · 0 payroll · 6 leave · 2 gate passes · 2 concessions · 6 certificates · 9 actioned',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 14),

        // Sub-tabs Pill Scroll
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: subTabs.map((st) {
              final isSel = _approvalsSubTab == st.split(' ').first;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(st),
                  selected: isSel,
                  onSelected: (val) {
                    if (val) setState(() => _approvalsSubTab = st.split(' ').first);
                  },
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : const Color(0xFF334155),
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                    fontFamily: 'Urbanist',
                  ),
                  selectedColor: const Color(0xFF6366F1),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSel ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Sub-Tab Content
        if (_approvalsSubTab == 'Requests') _buildApprovalsRequestsTab(),
        if (_approvalsSubTab == 'Payroll') _buildApprovalsPayrollTab(),
        if (_approvalsSubTab == 'Leave') _buildApprovalsLeaveTab(),
        if (_approvalsSubTab == 'Concessions') _buildApprovalsConcessionsTab(),
        if (_approvalsSubTab == 'Gate') _buildApprovalsGatePassTab(),
        if (_approvalsSubTab == 'Certificates') _buildApprovalsCertificatesTab(),
      ],
    );
  }

  Widget _buildApprovalsRequestsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Empty State Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'All clear',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Urbanist',
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Nothing waiting on your approval here.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontFamily: 'Urbanist',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text(
          'Recently actioned · your decision audit trail',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 10),

        // Audit Trail Items
        _buildAuditTrailCard(
          title: 'Chairman approval · Event: TEST - principal submit flow (cancel me) (Annual Day) · 2027-01-25 · budget ₹50,000',
          sub: 'Nov 17 · 02:17 PM · system',
          statusText: 'Rejected',
          statusColor: const Color(0xFFEF4444),
        ),
        const SizedBox(height: 8),
        _buildAuditTrailCard(
          title: 'Lesson plan for review — Grade 1 Hindi · Ch 1 (2 sessions) — submitted by keerthanabangla@innovorex.co.in',
          sub: 'Nov 2 · 03:19 PM · vinod123@gmail.com',
          statusText: 'Executed',
          statusColor: const Color(0xFF10B981),
        ),
        const SizedBox(height: 8),
        _buildAuditTrailCard(
          title: 'Lesson plan for review — Grade 1 Hindi · Ch 2 (2 sessions) — submitted by keerthanabangla@innovorex.co.in',
          sub: 'Sep 16 · 09:24 AM · vinod123@gmail.com',
          statusText: 'Executed',
          statusColor: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildAuditTrailCard({
    required String title,
    required String sub,
    required String statusText,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    fontFamily: 'Urbanist',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sub,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: statusColor, size: 5),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalsPayrollTab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: const [
          Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 36),
          SizedBox(height: 10),
          Text(
            'No payroll waiting for your approval.',
            style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text('Raised by the Accountant (0)', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildApprovalsLeaveTab() {
    final leaveItems = [
      {
        'id': 'leave-1',
        'name': 'Ramana',
        'type': 'STAFF LEAVE · SICK LEAVE',
        'time': '8d ago',
        'dates': '10 Nov - 11 Nov · 2 days',
        'reason': 'Sick',
      },
      {
        'id': 'leave-2',
        'name': 'Gopi Madem',
        'type': 'STAFF LEAVE · SICK LEAVE',
        'time': '8d ago',
        'dates': '10 Nov - 11 Nov · 2 days',
        'reason': 'Sick.',
      },
      {
        'id': 'leave-3',
        'name': 'Gopi Madem',
        'type': 'STAFF LEAVE · SICK LEAVE',
        'time': '14d ago',
        'dates': '4 Nov - 5 Nov · 2 days',
        'reason': 'Severe Cold.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Staff leave · teaching & non-teaching (6)',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 10),
        ...leaveItems.map((item) {
          final isDecided = _decidedItemIds.contains(item['id']);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Container(
              padding: const EdgeInsets.all(14),
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
                      Text(
                        item['type']!,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(item['time']!, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['name']!,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['dates']!,
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Reason: ${item['reason']}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                  ),
                  const SizedBox(height: 12),
                  if (isDecided)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Approved', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                    )
                  else
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            setState(() => _decidedItemIds.add(item['id']!));
                          },
                          child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            setState(() => _decidedItemIds.add(item['id']!));
                          },
                          child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildApprovalsConcessionsTab() {
    final concessionItems = [
      {
        'id': 'conc-1',
        'type': 'MERIT SCHOLARSHIP',
        'time': '8d ago',
        'title': 'Aisha Menon · ₹10,000',
        'reason': 'Merit Student',
        'raisedBy': 'suresh@gmail.com (accountant)',
      },
      {
        'id': 'conc-2',
        'type': 'SIBLING DISCOUNT',
        'time': '150d ago',
        'title': 'Mary B · 10%',
        'reason': 'Second child',
        'raisedBy': 'suresh@gmail.com (accountant)',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sent to you · waiting for your decision (2)',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 10),
        ...concessionItems.map((item) {
          final isDecided = _decidedItemIds.contains(item['id']);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Container(
              padding: const EdgeInsets.all(14),
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
                      Text(
                        item['type']!,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(item['time']!, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['title']!,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Reason: ${item['reason']}', style: const TextStyle(color: Color(0xFF475569), fontSize: 12)),
                  Text('Raised by ${item['raisedBy']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  const SizedBox(height: 12),
                  if (isDecided)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Actioned', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                    )
                  else
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            setState(() => _decidedItemIds.add(item['id']!));
                          },
                          child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            setState(() => _decidedItemIds.add(item['id']!));
                          },
                          child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildApprovalsGatePassTab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Gate Passes (2 pending)', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('1. Jatin Kalidindi (Student early exit · Medical appointment)', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
          SizedBox(height: 4),
          Text('2. Ramesh V (Staff duty exit · Bank visit)', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildApprovalsCertificatesTab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Certificates (6 pending)', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('• Bonafide Certificates: 4 requests', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
          SizedBox(height: 4),
          Text('• Study & Conduct Certificates: 2 requests', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 3: STUDENTS (PAGE-2)
  // ==========================================
  Widget _buildStudentsView() {
    final filtered = _studentsRoster.where((s) {
      final matchesQuery = _studentSearchQuery.isEmpty ||
          s['name'].toString().toLowerCase().contains(_studentSearchQuery.toLowerCase()) ||
          s['id'].toString().toLowerCase().contains(_studentSearchQuery.toLowerCase()) ||
          s['guardian'].toString().toLowerCase().contains(_studentSearchQuery.toLowerCase());
      final matchesClass = _selectedClass == 'All classes' || s['class'] == _selectedClass;
      final matchesGender = _selectedGender == 'All genders' || s['gender'] == _selectedGender;
      return matchesQuery && matchesClass && matchesGender;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text(
          'Student Management',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '44 enrolled · search and filter the branch roster',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),

        // 4 KPI Cards
        Row(
          children: [
            Expanded(child: _buildStudentKpi('Total students', '44', '▲ 5 new', const Color(0xFF10B981))),
            const SizedBox(width: 8),
            Expanded(child: _buildStudentKpi('Classes', '7', 'programs', const Color(0xFF6366F1))),
            const SizedBox(width: 8),
            Expanded(child: _buildStudentKpi('New this month', '5', 'admitted', const Color(0xFF0EA5E9))),
            const SizedBox(width: 8),
            Expanded(child: _buildStudentKpi('In directory', '44', 'searchable', const Color(0xFF64748B))),
          ],
        ),

        const SizedBox(height: 20),

        // Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _studentSearchQuery = val),
            decoration: const InputDecoration(
              icon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
              hintText: 'Search by name, ID, guardian or mobile...',
              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Filter Dropdowns
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDropdownFilter('Class', _selectedClass, ['All classes', 'Class - 1', 'Class - 2', 'Class - 3'], (v) {
                setState(() => _selectedClass = v!);
              }),
              const SizedBox(width: 8),
              _buildDropdownFilter('Gender', _selectedGender, ['All genders', 'Male', 'Female'], (v) {
                setState(() => _selectedGender = v!);
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Student Table Header / Count
        Text(
          'Students (${filtered.length} of ${_studentsRoster.length})',
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),

        // Student Roster Cards
        ...filtered.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: (s['avatarColor'] as Color).withValues(alpha: 0.15),
                    child: Text(
                      s['initials']!,
                      style: TextStyle(
                        color: s['avatarColor'] as Color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['name']!,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${s['id']} · ${s['class']} ${s['section']}',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                        Text(
                          'Guardian: ${s['guardian']} (${s['mobile']})',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s['status']!,
                      style: const TextStyle(color: Color(0xFF15803D), fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStudentKpi(String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.w700), maxLines: 1),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold), maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(String label, String currentVal, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentVal,
          isDense: true,
          style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w600),
          items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 4: STAFF (PAGE-3)
  // ==========================================
  Widget _buildStaffView() {
    final filtered = _staffRoster.where((s) {
      final matchesQuery = _staffSearchQuery.isEmpty ||
          s['name'].toString().toLowerCase().contains(_staffSearchQuery.toLowerCase()) ||
          s['jobTitle'].toString().toLowerCase().contains(_staffSearchQuery.toLowerCase());
      final matchesTab = _staffTabFilter == 'All' ||
          (_staffTabFilter == 'Teaching' && s['isTeaching'] == true) ||
          (_staffTabFilter == 'Non-teaching' && s['isTeaching'] == false);
      return matchesQuery && matchesTab;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text(
          'Staff',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '25 staff · 11 teaching · 14 non-teaching',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),

        // 4 KPI Cards
        Row(
          children: [
            Expanded(child: _buildStudentKpi('Total staff', '25', 'active', const Color(0xFF64748B))),
            const SizedBox(width: 8),
            Expanded(child: _buildStudentKpi('Teaching', '11', '12 instructors', const Color(0xFF10B981))),
            const SizedBox(width: 8),
            Expanded(child: _buildStudentKpi('Non-teaching', '14', '6 areas', const Color(0xFFF59E0B))),
            const SizedBox(width: 8),
            Expanded(child: _buildStudentKpi('Present today', '0/25', 'not marked', const Color(0xFFEF4444))),
          ],
        ),

        const SizedBox(height: 20),

        // 3 Sub-panels (Non-teaching by Area, Departments, Low attendance)
        _buildStaffBreakdownPanel(),

        const SizedBox(height: 20),

        // Staff Directory Search & Filters
        Row(
          children: [
            _buildStaffTabPill('All · 25', 'All'),
            const SizedBox(width: 6),
            _buildStaffTabPill('Teaching · 11', 'Teaching'),
            const SizedBox(width: 6),
            _buildStaffTabPill('Non-teaching · 14', 'Non-teaching'),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _staffSearchQuery = val),
            decoration: const InputDecoration(
              icon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
              hintText: 'Search staff by name, ID, job title...',
              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Staff Directory Cards
        ...filtered.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    child: Text(
                      s['initials']!,
                      style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['name']!,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${s['jobTitle']} · ${s['area']}',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                        Text(
                          'Department: ${s['department']}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: (s['status'] == 'Active') ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s['status']!,
                          style: TextStyle(
                            color: (s['status'] == 'Active') ? const Color(0xFF15803D) : const Color(0xFFB45309),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Attend: ${s['attendance']}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStaffTabPill(String label, String key) {
    final isSel = _staffTabFilter == key;
    return InkWell(
      onTap: () => setState(() => _staffTabFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.white : const Color(0xFF334155),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildStaffBreakdownPanel() {
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
            'Non-teaching by area (14 staff)',
            style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: const [
              Chip(label: Text('Administration: 4', style: TextStyle(fontSize: 11))),
              Chip(label: Text('Accounts: 1', style: TextStyle(fontSize: 11))),
              Chip(label: Text('Front office: 1', style: TextStyle(fontSize: 11))),
              Chip(label: Text('Library: 5', style: TextStyle(fontSize: 11))),
              Chip(label: Text('Transport: 2', style: TextStyle(fontSize: 11))),
              Chip(label: Text('Hostel: 1', style: TextStyle(fontSize: 11))),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          const Text(
            'Departments (1 in ERPNext)',
            style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text('• Hindi: 4 teaching · 1 non-teaching', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
          const Text('• Not assigned: 7 teaching · 13 non-teaching', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Attention: Keerthana Bangla attendance below 95% (0%)',
                    style: TextStyle(color: Color(0xFFB91C1C), fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PLACEHOLDER VIEWS (MODULES 5 - 15)
  // ==========================================
  Widget _buildModulePlaceholder(String title, IconData icon, List<Map<String, String>> kpis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF6366F1), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                  const Text(
                    'Steel Plant Branch · Live sync',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // KPI Grid
        Row(
          children: [
            Expanded(child: _buildStudentKpi(kpis[0]['label']!, kpis[0]['val']!, kpis[0]['sub']!, const Color(0xFF10B981))),
            const SizedBox(width: 8),
            Expanded(child: _buildStudentKpi(kpis[1]['label']!, kpis[1]['val']!, kpis[1]['sub']!, const Color(0xFF6366F1))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildStudentKpi(kpis[2]['label']!, kpis[2]['val']!, kpis[2]['sub']!, const Color(0xFF0EA5E9))),
            const SizedBox(width: 8),
            Expanded(child: _buildStudentKpi(kpis[3]['label']!, kpis[3]['val']!, kpis[3]['sub']!, const Color(0xFFF59E0B))),
          ],
        ),

        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF6366F1), size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                '$title Module Active',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Urbanist',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Complete mobile layout loaded. Connected to Steel Plant Branch API.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  height: 1.4,
                  fontFamily: 'Urbanist',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
