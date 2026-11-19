import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../data/live_dashboard_payload.dart';
import '../data/users_directory_data.dart';
import '../services/api_config.dart';
import '../services/auth_service.dart';
import '../services/branch_service.dart';
import 'people_ops_view.dart';
import 'student_lookup_view.dart';
import '../widgets/notifications_overlay.dart';
import '../services/session_manager.dart';
import '../widgets/radial_arc_menu.dart';
import 'academics/academics_view.dart';
import 'views/finance_fees_view.dart';
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
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData =
      jsonDecode(jsonEncode(kDefaultLiveDashboardData));
  String _activeView = 'view-overview';
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
  final String _branchPeriod = 'YTD';
  String _branchSelectedFilter = 'All branches';
  final GlobalKey _branchDropdownKey = GlobalKey();
  // Interactive state for Attendance Audit
  String _attendancePrimaryTab = 'students'; // 'students' | 'staff'
  DateTime _selectedAttendanceDate = DateTime(2026, 11, 14);
  bool _isAttendanceLoading = false;
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

  bool _showAllAttendanceStudents = false;
  bool _showAllAttendanceStaff = false;

  // Interactive state for Users Directory
  String _usersRoleFilter = 'all'; // 'all' | 'students' | 'teaching' | 'non-teaching' | 'admins' | 'principals' | 'parents'
  String _usersBranchFilter = 'all'; // 'all' or branch slug ('steel-plant', 'gachibowli', etc.)
  String _usersSearchQuery = '';
  final TextEditingController _usersSearchController = TextEditingController();
  bool _showAllUsers = false;

  static List<Map<String, dynamic>>? _cachedAllStudentsList;
  static List<Map<String, dynamic>> _getAllStudentRecords() {
    if (_cachedAllStudentsList != null) return _cachedAllStudentsList!;
    _cachedAllStudentsList = [
    {
      'initials': 'AS',
      'name': 'Aarav S.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'hostel-residents',
      'status': 'Not marked',
      'rollNo': 'GB-10-01',
      'meta': 'Class 10 • Sec A • Gachibowli',
    },
    {
      'initials': 'AV',
      'name': 'Aadhya V.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 9',
      'section': 'Sec B',
      'residency': 'hostel-residents',
      'status': 'Not marked',
      'rollNo': 'GB-9-02',
      'meta': 'Class 9 • Sec B • Gachibowli',
    },
    {
      'initials': 'VP',
      'name': 'Vihaan P.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 8',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-8-03',
      'meta': 'Class 8 • Sec A • Gachibowli',
    },
    {
      'initials': 'AR',
      'name': 'Ananya R.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 7',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-7-04',
      'meta': 'Class 7 • Sec B • Gachibowli',
    },
    {
      'initials': 'RR',
      'name': 'Reyansh R.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 6',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-6-05',
      'meta': 'Class 6 • Sec A • Gachibowli',
    },
    {
      'initials': 'DN',
      'name': 'Diya N.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 5',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-5-06',
      'meta': 'Class 5 • Sec B • Gachibowli',
    },
    {
      'initials': 'AK',
      'name': 'Advik K.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 4',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-4-07',
      'meta': 'Class 4 • Sec A • Gachibowli',
    },
    {
      'initials': 'IS',
      'name': 'Isha S.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 3',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-3-08',
      'meta': 'Class 3 • Sec B • Gachibowli',
    },
    {
      'initials': 'KG',
      'name': 'Kabir G.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 2',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-2-09',
      'meta': 'Class 2 • Sec A • Gachibowli',
    },
    {
      'initials': 'MJ',
      'name': 'Meera J.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 1',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-1-10',
      'meta': 'Class 1 • Sec B • Gachibowli',
    },
    {
      'initials': 'DB',
      'name': 'Dhruv B.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-10-11',
      'meta': 'Class 10 • Sec A • Gachibowli',
    },
    {
      'initials': 'RP',
      'name': 'Riya P.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 9',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-9-12',
      'meta': 'Class 9 • Sec B • Gachibowli',
    },
    {
      'initials': 'AN',
      'name': 'Atharv N.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 8',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-8-13',
      'meta': 'Class 8 • Sec A • Gachibowli',
    },
    {
      'initials': 'SC',
      'name': 'Saanvi C.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 7',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-7-14',
      'meta': 'Class 7 • Sec B • Gachibowli',
    },
    {
      'initials': 'IM',
      'name': 'Ishaan M.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 6',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-6-15',
      'meta': 'Class 6 • Sec A • Gachibowli',
    },
    {
      'initials': 'PP',
      'name': 'Pooja P.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 5',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-5-16',
      'meta': 'Class 5 • Sec B • Gachibowli',
    },
    {
      'initials': 'SS',
      'name': 'Sai S.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 4',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-4-17',
      'meta': 'Class 4 • Sec A • Gachibowli',
    },
    {
      'initials': 'TV',
      'name': 'Tanvi V.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 3',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-3-18',
      'meta': 'Class 3 • Sec B • Gachibowli',
    },
    {
      'initials': 'AP',
      'name': 'Arjun P.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 2',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-2-19',
      'meta': 'Class 2 • Sec A • Gachibowli',
    },
    {
      'initials': 'KR',
      'name': 'Kavya R.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 1',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-1-20',
      'meta': 'Class 1 • Sec B • Gachibowli',
    },
    {
      'initials': 'AR',
      'name': 'Aditya R.',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'GB-10-21',
      'meta': 'Class 10 • Sec A • Gachibowli',
    },
    {
      'initials': 'AN',
      'name': 'Ananya N.',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'hostel-residents',
      'status': 'Not marked',
      'rollNo': 'KD-10-01',
      'meta': 'Class 10 • Sec A • Kondapur',
    },
    {
      'initials': 'RK',
      'name': 'Reyansh K.',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'class': 'Class 9',
      'section': 'Sec B',
      'residency': 'hostel-residents',
      'status': 'Not marked',
      'rollNo': 'KD-9-02',
      'meta': 'Class 9 • Sec B • Kondapur',
    },
    {
      'initials': 'DS',
      'name': 'Diya S.',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'class': 'Class 8',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KD-8-03',
      'meta': 'Class 8 • Sec A • Kondapur',
    },
    {
      'initials': 'AG',
      'name': 'Advik G.',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'class': 'Class 7',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KD-7-04',
      'meta': 'Class 7 • Sec B • Kondapur',
    },
    {
      'initials': 'IJ',
      'name': 'Isha J.',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'class': 'Class 6',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KD-6-05',
      'meta': 'Class 6 • Sec A • Kondapur',
    },
    {
      'initials': 'KB',
      'name': 'Kabir B.',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'class': 'Class 5',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KD-5-06',
      'meta': 'Class 5 • Sec B • Kondapur',
    },
    {
      'initials': 'MP',
      'name': 'Meera P.',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'class': 'Class 4',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KD-4-07',
      'meta': 'Class 4 • Sec A • Kondapur',
    },
    {
      'initials': 'DN',
      'name': 'Dhruv N.',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'class': 'Class 3',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KD-3-08',
      'meta': 'Class 3 • Sec B • Kondapur',
    },
    {
      'initials': 'RC',
      'name': 'Riya C.',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'class': 'Class 2',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KD-2-09',
      'meta': 'Class 2 • Sec A • Kondapur',
    },
    {
      'initials': 'AM',
      'name': 'Atharv M.',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'class': 'Class 1',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KD-1-10',
      'meta': 'Class 1 • Sec B • Kondapur',
    },
    {
      'initials': 'SP',
      'name': 'Saanvi P.',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KD-10-11',
      'meta': 'Class 10 • Sec A • Kondapur',
    },
    {
      'initials': 'IS',
      'name': 'Ishaan S.',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'class': 'Class 9',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KD-9-12',
      'meta': 'Class 9 • Sec B • Kondapur',
    },
    {
      'initials': 'PV',
      'name': 'Pooja V.',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'class': 'Class 8',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KD-8-13',
      'meta': 'Class 8 • Sec A • Kondapur',
    },
    {
      'initials': 'SP',
      'name': 'Sai P.',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'class': 'Class 7',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KD-7-14',
      'meta': 'Class 7 • Sec B • Kondapur',
    },
    {
      'initials': 'AB',
      'name': 'Advik B.',
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
      'initials': 'IP',
      'name': 'Isha P.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 9',
      'section': 'Sec B',
      'residency': 'hostel-residents',
      'status': 'Not marked',
      'rollNo': 'KP-9-02',
      'meta': 'Class 9 • Sec B • Kukatpally',
    },
    {
      'initials': 'KN',
      'name': 'Kabir N.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 8',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KP-8-03',
      'meta': 'Class 8 • Sec A • Kukatpally',
    },
    {
      'initials': 'MC',
      'name': 'Meera C.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 7',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KP-7-04',
      'meta': 'Class 7 • Sec B • Kukatpally',
    },
    {
      'initials': 'DM',
      'name': 'Dhruv M.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 6',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KP-6-05',
      'meta': 'Class 6 • Sec A • Kukatpally',
    },
    {
      'initials': 'RP',
      'name': 'Riya P.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 5',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KP-5-06',
      'meta': 'Class 5 • Sec B • Kukatpally',
    },
    {
      'initials': 'AS',
      'name': 'Atharv S.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 4',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KP-4-07',
      'meta': 'Class 4 • Sec A • Kukatpally',
    },
    {
      'initials': 'SV',
      'name': 'Saanvi V.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 3',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KP-3-08',
      'meta': 'Class 3 • Sec B • Kukatpally',
    },
    {
      'initials': 'IP',
      'name': 'Ishaan P.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 2',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KP-2-09',
      'meta': 'Class 2 • Sec A • Kukatpally',
    },
    {
      'initials': 'PR',
      'name': 'Pooja R.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 1',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KP-1-10',
      'meta': 'Class 1 • Sec B • Kukatpally',
    },
    {
      'initials': 'SR',
      'name': 'Sai R.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KP-10-11',
      'meta': 'Class 10 • Sec A • Kukatpally',
    },
    {
      'initials': 'TN',
      'name': 'Tanvi N.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 9',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KP-9-12',
      'meta': 'Class 9 • Sec B • Kukatpally',
    },
    {
      'initials': 'AK',
      'name': 'Arjun K.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 8',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KP-8-13',
      'meta': 'Class 8 • Sec A • Kukatpally',
    },
    {
      'initials': 'KS',
      'name': 'Kavya S.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 7',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KP-7-14',
      'meta': 'Class 7 • Sec B • Kukatpally',
    },
    {
      'initials': 'AG',
      'name': 'Aditya G.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 6',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KP-6-15',
      'meta': 'Class 6 • Sec A • Kukatpally',
    },
    {
      'initials': 'NJ',
      'name': 'Neha J.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 5',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KP-5-16',
      'meta': 'Class 5 • Sec B • Kukatpally',
    },
    {
      'initials': 'RB',
      'name': 'Rohan B.',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'class': 'Class 4',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'KP-4-17',
      'meta': 'Class 4 • Sec A • Kukatpally',
    },
    {
      'initials': 'MP',
      'name': 'Meera P.',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'hostel-residents',
      'status': 'Not marked',
      'rollNo': 'MD-10-01',
      'meta': 'Class 10 • Sec A • Maddipalem',
    },
    {
      'initials': 'DS',
      'name': 'Dhruv S.',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'class': 'Class 9',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MD-9-02',
      'meta': 'Class 9 • Sec B • Maddipalem',
    },
    {
      'initials': 'RV',
      'name': 'Riya V.',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'class': 'Class 8',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MD-8-03',
      'meta': 'Class 8 • Sec A • Maddipalem',
    },
    {
      'initials': 'AP',
      'name': 'Atharv P.',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'class': 'Class 7',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MD-7-04',
      'meta': 'Class 7 • Sec B • Maddipalem',
    },
    {
      'initials': 'SR',
      'name': 'Saanvi R.',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'class': 'Class 6',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MD-6-05',
      'meta': 'Class 6 • Sec A • Maddipalem',
    },
    {
      'initials': 'IR',
      'name': 'Ishaan R.',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'class': 'Class 5',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MD-5-06',
      'meta': 'Class 5 • Sec B • Maddipalem',
    },
    {
      'initials': 'PN',
      'name': 'Pooja N.',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'class': 'Class 4',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MD-4-07',
      'meta': 'Class 4 • Sec A • Maddipalem',
    },
    {
      'initials': 'SK',
      'name': 'Sai K.',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'class': 'Class 3',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MD-3-08',
      'meta': 'Class 3 • Sec B • Maddipalem',
    },
    {
      'initials': 'TS',
      'name': 'Tanvi S.',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'class': 'Class 2',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MD-2-09',
      'meta': 'Class 2 • Sec A • Maddipalem',
    },
    {
      'initials': 'AR',
      'name': 'Atharv R.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'hostel-residents',
      'status': 'Not marked',
      'rollNo': 'MP-10-01',
      'meta': 'Class 10 • Sec A • Madhapur',
    },
    {
      'initials': 'SN',
      'name': 'Saanvi N.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 9',
      'section': 'Sec B',
      'residency': 'hostel-residents',
      'status': 'Not marked',
      'rollNo': 'MP-9-02',
      'meta': 'Class 9 • Sec B • Madhapur',
    },
    {
      'initials': 'IK',
      'name': 'Ishaan K.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 8',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-8-03',
      'meta': 'Class 8 • Sec A • Madhapur',
    },
    {
      'initials': 'PS',
      'name': 'Pooja S.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 7',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-7-04',
      'meta': 'Class 7 • Sec B • Madhapur',
    },
    {
      'initials': 'SG',
      'name': 'Sai G.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 6',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-6-05',
      'meta': 'Class 6 • Sec A • Madhapur',
    },
    {
      'initials': 'TJ',
      'name': 'Tanvi J.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 5',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-5-06',
      'meta': 'Class 5 • Sec B • Madhapur',
    },
    {
      'initials': 'AB',
      'name': 'Arjun B.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 4',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-4-07',
      'meta': 'Class 4 • Sec A • Madhapur',
    },
    {
      'initials': 'KP',
      'name': 'Kavya P.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 3',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-3-08',
      'meta': 'Class 3 • Sec B • Madhapur',
    },
    {
      'initials': 'AN',
      'name': 'Aditya N.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 2',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-2-09',
      'meta': 'Class 2 • Sec A • Madhapur',
    },
    {
      'initials': 'NC',
      'name': 'Neha C.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 1',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-1-10',
      'meta': 'Class 1 • Sec B • Madhapur',
    },
    {
      'initials': 'RM',
      'name': 'Rohan M.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-10-11',
      'meta': 'Class 10 • Sec A • Madhapur',
    },
    {
      'initials': 'AP',
      'name': 'Anika P.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 9',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-9-12',
      'meta': 'Class 9 • Sec B • Madhapur',
    },
    {
      'initials': 'KS',
      'name': 'Krishna S.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 8',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-8-13',
      'meta': 'Class 8 • Sec A • Madhapur',
    },
    {
      'initials': 'SV',
      'name': 'Sneha V.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 7',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-7-14',
      'meta': 'Class 7 • Sec B • Madhapur',
    },
    {
      'initials': 'RP',
      'name': 'Rahul P.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 6',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-6-15',
      'meta': 'Class 6 • Sec A • Madhapur',
    },
    {
      'initials': 'PR',
      'name': 'Priya R.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 5',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-5-16',
      'meta': 'Class 5 • Sec B • Madhapur',
    },
    {
      'initials': 'MR',
      'name': 'Manish R.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 4',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-4-17',
      'meta': 'Class 4 • Sec A • Madhapur',
    },
    {
      'initials': 'DN',
      'name': 'Divya N.',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'class': 'Class 3',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'MP-3-18',
      'meta': 'Class 3 • Sec B • Madhapur',
    },
    {
      'initials': 'PJ',
      'name': 'Pooja J.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'hostel-residents',
      'status': 'Present',
      'rollNo': 'SP-10-01',
      'meta': 'Class 10 • Sec A • Steel',
    },
    {
      'initials': 'SB',
      'name': 'Sai B.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 9',
      'section': 'Sec B',
      'residency': 'hostel-residents',
      'status': 'Present',
      'rollNo': 'SP-9-02',
      'meta': 'Class 9 • Sec B • Steel',
    },
    {
      'initials': 'TP',
      'name': 'Tanvi P.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 8',
      'section': 'Sec A',
      'residency': 'hostel-residents',
      'status': 'Present',
      'rollNo': 'SP-8-03',
      'meta': 'Class 8 • Sec A • Steel',
    },
    {
      'initials': 'AN',
      'name': 'Arjun N.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 7',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-7-04',
      'meta': 'Class 7 • Sec B • Steel',
    },
    {
      'initials': 'KC',
      'name': 'Kavya C.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 6',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-6-05',
      'meta': 'Class 6 • Sec A • Steel',
    },
    {
      'initials': 'AM',
      'name': 'Aditya M.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 5',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-5-06',
      'meta': 'Class 5 • Sec B • Steel',
    },
    {
      'initials': 'NP',
      'name': 'Neha P.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 4',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-4-07',
      'meta': 'Class 4 • Sec A • Steel',
    },
    {
      'initials': 'RS',
      'name': 'Rohan S.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 3',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-3-08',
      'meta': 'Class 3 • Sec B • Steel',
    },
    {
      'initials': 'AV',
      'name': 'Anika V.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 2',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-2-09',
      'meta': 'Class 2 • Sec A • Steel',
    },
    {
      'initials': 'KP',
      'name': 'Krishna P.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 1',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-1-10',
      'meta': 'Class 1 • Sec B • Steel',
    },
    {
      'initials': 'SR',
      'name': 'Sneha R.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-10-11',
      'meta': 'Class 10 • Sec A • Steel',
    },
    {
      'initials': 'RR',
      'name': 'Rahul R.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 9',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-9-12',
      'meta': 'Class 9 • Sec B • Steel',
    },
    {
      'initials': 'PN',
      'name': 'Priya N.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 8',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-8-13',
      'meta': 'Class 8 • Sec A • Steel',
    },
    {
      'initials': 'MK',
      'name': 'Manish K.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 7',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-7-14',
      'meta': 'Class 7 • Sec B • Steel',
    },
    {
      'initials': 'DS',
      'name': 'Divya S.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 6',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-6-15',
      'meta': 'Class 6 • Sec A • Steel',
    },
    {
      'initials': 'VG',
      'name': 'Varun G.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 5',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-5-16',
      'meta': 'Class 5 • Sec B • Steel',
    },
    {
      'initials': 'SJ',
      'name': 'Swati J.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 4',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-4-17',
      'meta': 'Class 4 • Sec A • Steel',
    },
    {
      'initials': 'NB',
      'name': 'Nikhil B.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 3',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-3-18',
      'meta': 'Class 3 • Sec B • Steel',
    },
    {
      'initials': 'SP',
      'name': 'Shreya P.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 2',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-2-19',
      'meta': 'Class 2 • Sec A • Steel',
    },
    {
      'initials': 'KN',
      'name': 'Kiran N.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 1',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-1-20',
      'meta': 'Class 1 • Sec B • Steel',
    },
    {
      'initials': 'MC',
      'name': 'Megha C.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-10-21',
      'meta': 'Class 10 • Sec A • Steel',
    },
    {
      'initials': 'VM',
      'name': 'Vikram M.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 9',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Present',
      'rollNo': 'SP-9-22',
      'meta': 'Class 9 • Sec B • Steel',
    },
    {
      'initials': 'AP',
      'name': 'Anjali P.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 8',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Absent',
      'rollNo': 'SP-8-23',
      'meta': 'Class 8 • Sec A • Steel',
    },
    {
      'initials': 'SS',
      'name': 'Siddharth S.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 7',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Absent',
      'rollNo': 'SP-7-24',
      'meta': 'Class 7 • Sec B • Steel',
    },
    {
      'initials': 'PV',
      'name': 'Preeti V.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 6',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Absent',
      'rollNo': 'SP-6-25',
      'meta': 'Class 6 • Sec A • Steel',
    },
    {
      'initials': 'HP',
      'name': 'Harsh P.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 5',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Absent',
      'rollNo': 'SP-5-26',
      'meta': 'Class 5 • Sec B • Steel',
    },
    {
      'initials': 'DR',
      'name': 'Deepika R.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 4',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Absent',
      'rollNo': 'SP-4-27',
      'meta': 'Class 4 • Sec A • Steel',
    },
    {
      'initials': 'KR',
      'name': 'Karthik R.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 3',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-3-28',
      'meta': 'Class 3 • Sec B • Steel',
    },
    {
      'initials': 'BN',
      'name': 'Bhavana N.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 2',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-2-29',
      'meta': 'Class 2 • Sec A • Steel',
    },
    {
      'initials': 'PK',
      'name': 'Pranav K.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 1',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-1-30',
      'meta': 'Class 1 • Sec B • Steel',
    },
    {
      'initials': 'HS',
      'name': 'Harini S.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-10-31',
      'meta': 'Class 10 • Sec A • Steel',
    },
    {
      'initials': 'TG',
      'name': 'Tarun G.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 9',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-9-32',
      'meta': 'Class 9 • Sec B • Steel',
    },
    {
      'initials': 'KJ',
      'name': 'Keerthi J.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 8',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-8-33',
      'meta': 'Class 8 • Sec A • Steel',
    },
    {
      'initials': 'AB',
      'name': 'Aarav B.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 7',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-7-34',
      'meta': 'Class 7 • Sec B • Steel',
    },
    {
      'initials': 'AP',
      'name': 'Aadhya P.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 6',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-6-35',
      'meta': 'Class 6 • Sec A • Steel',
    },
    {
      'initials': 'VN',
      'name': 'Vihaan N.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 5',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-5-36',
      'meta': 'Class 5 • Sec B • Steel',
    },
    {
      'initials': 'AC',
      'name': 'Ananya C.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 4',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-4-37',
      'meta': 'Class 4 • Sec A • Steel',
    },
    {
      'initials': 'RM',
      'name': 'Reyansh M.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 3',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-3-38',
      'meta': 'Class 3 • Sec B • Steel',
    },
    {
      'initials': 'DP',
      'name': 'Diya P.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 2',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-2-39',
      'meta': 'Class 2 • Sec A • Steel',
    },
    {
      'initials': 'AS',
      'name': 'Advik S.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 1',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-1-40',
      'meta': 'Class 1 • Sec B • Steel',
    },
    {
      'initials': 'IV',
      'name': 'Isha V.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 10',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-10-41',
      'meta': 'Class 10 • Sec A • Steel',
    },
    {
      'initials': 'KP',
      'name': 'Kabir P.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 9',
      'section': 'Sec B',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-9-42',
      'meta': 'Class 9 • Sec B • Steel',
    },
    {
      'initials': 'MR',
      'name': 'Meera R.',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'class': 'Class 8',
      'section': 'Sec A',
      'residency': 'day-scholars',
      'status': 'Not marked',
      'rollNo': 'SP-8-43',
      'meta': 'Class 8 • Sec A • Steel',
    },
    ];
    return _cachedAllStudentsList!;
  }


  static List<Map<String, dynamic>>? _cachedAllStaffList;
  static List<Map<String, dynamic>> _getAllStaffRecords() {
    if (_cachedAllStaffList != null) return _cachedAllStaffList!;
    _cachedAllStaffList = [
    {
      'initials': 'MA',
      'name': 'M. Ananya',
      'role': 'TGT English • Gachibowli Campus',
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
      'initials': 'RV',
      'name': 'R. Verma',
      'role': 'PGT Physics • Gachibowli Campus',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'department': 'Physics',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:35 AM',
      'phone': '+91 98491 23456',
    },
    {
      'initials': 'BP',
      'name': 'B. Prabhakar',
      'role': 'Administrative Officer • Gachibowli Campus',
      'category': 'non-teaching',
      'subRole': 'admin-officer',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:35 AM',
      'phone': '+91 97011 55667',
    },
    {
      'initials': 'MS',
      'name': 'Mrs. Meenakshi S.',
      'role': 'Principal • Gachibowli Campus',
      'category': 'non-teaching',
      'subRole': 'principal',
      'branchId': 'gachibowli',
      'branchName': 'Gachibowli Campus',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:10 AM',
      'phone': '+91 98492 33445',
    },
    {
      'initials': 'KS',
      'name': 'K. Sneha',
      'role': 'PRT Science • Kondapur Branch',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'department': 'Science',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:30 AM',
      'phone': '+91 97766 55443',
    },
    {
      'initials': 'VN',
      'name': 'V. Nair',
      'role': 'TGT Social • Kondapur Branch',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'department': 'Social Studies',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:40 AM',
      'phone': '+91 98855 12345',
    },
    {
      'initials': 'SS',
      'name': 'S. Sharma',
      'role': 'Administrative Officer • Kondapur Branch',
      'category': 'non-teaching',
      'subRole': 'admin-officer',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:25 AM',
      'phone': '+91 97000 88214',
    },
    {
      'initials': 'KS',
      'name': 'Dr. K. Srinivas',
      'role': 'Principal • Kondapur Branch',
      'category': 'non-teaching',
      'subRole': 'principal',
      'branchId': 'kondapur',
      'branchName': 'Kondapur Branch',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:05 AM',
      'phone': '+91 98480 11223',
    },
    {
      'initials': 'PD',
      'name': 'P. Deepika',
      'role': 'TGT Telugu • Kukatpally Campus',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'department': 'Telugu',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:25 AM',
      'phone': '+91 94411 22334',
    },
    {
      'initials': 'AK',
      'name': 'A. Karthik',
      'role': 'TGT Hindi • Kukatpally Campus',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'department': 'Hindi',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:35 AM',
      'phone': '+91 93910 33412',
    },
    {
      'initials': 'NR',
      'name': 'N. Rao',
      'role': 'Administrative Officer • Kukatpally Campus',
      'category': 'non-teaching',
      'subRole': 'admin-officer',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:30 AM',
      'phone': '+91 91210 44556',
    },
    {
      'initials': 'RV',
      'name': 'Mrs. Radhika V.',
      'role': 'Principal • Kukatpally Campus',
      'category': 'non-teaching',
      'subRole': 'principal',
      'branchId': 'kukatpally',
      'branchName': 'Kukatpally Campus',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:00 AM',
      'phone': '+91 98844 55667',
    },
    {
      'initials': 'GS',
      'name': 'G. Srinivas',
      'role': 'TGT Maths • Maddipalem Branch',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'department': 'Mathematics',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:30 AM',
      'phone': '+91 98844 55667',
    },
    {
      'initials': 'LB',
      'name': 'L. Bhavani',
      'role': 'PRT English • Maddipalem Branch',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'department': 'English',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:45 AM',
      'phone': '+91 99887 66554',
    },
    {
      'initials': 'SV',
      'name': 'S. Venkat',
      'role': 'Administrative Officer • Maddipalem Branch',
      'category': 'non-teaching',
      'subRole': 'admin-officer',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:35 AM',
      'phone': '+91 91212 99011',
    },
    {
      'initials': 'TA',
      'name': 'T. Anand',
      'role': 'Administrative Officer • Maddipalem Branch',
      'category': 'non-teaching',
      'subRole': 'admin-officer',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:40 AM',
      'phone': '+91 97011 22334',
    },
    {
      'initials': 'VP',
      'name': 'Dr. V. Prasad',
      'role': 'Principal • Maddipalem Branch',
      'category': 'non-teaching',
      'subRole': 'principal',
      'branchId': 'maddipalem',
      'branchName': 'Maddipalem Branch',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:15 AM',
      'phone': '+91 98450 66778',
    },
    {
      'initials': 'DS',
      'name': 'D. Sandeep',
      'role': 'TGT Computers • Madhapur Branch',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'department': 'Computers',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:40 AM',
      'phone': '+91 94401 22334',
    },
    {
      'initials': 'BP',
      'name': 'B. Priya',
      'role': 'PRT Art • Madhapur Branch',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'department': 'Arts & Crafts',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:50 AM',
      'phone': '+91 98490 33445',
    },
    {
      'initials': 'MV',
      'name': 'M. V. Reddy',
      'role': 'Administrative Officer • Madhapur Branch',
      'category': 'non-teaching',
      'subRole': 'admin-officer',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:30 AM',
      'phone': '+91 91234 56780',
    },
    {
      'initials': 'SD',
      'name': 'Mrs. Sunita D.',
      'role': 'Principal • Madhapur Branch',
      'category': 'non-teaching',
      'subRole': 'principal',
      'branchId': 'madhapur',
      'branchName': 'Madhapur Branch',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:10 AM',
      'phone': '+91 97766 11223',
    },
    {
      'initials': 'KS',
      'name': 'Dr. K. S. Rao',
      'role': 'Teacher • Steel Plant Branch',
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
      'initials': 'MS',
      'name': 'M. Suresh',
      'role': 'Teacher • Steel Plant Branch',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Chemistry',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:35 AM',
      'phone': '+91 94401 67890',
    },
    {
      'initials': 'CL',
      'name': 'Ch. Lakshmi',
      'role': 'Teacher • Steel Plant Branch',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Biology',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:40 AM',
      'phone': '+91 98492 45678',
    },
    {
      'initials': 'BN',
      'name': 'B. Naidu',
      'role': 'Teacher • Steel Plant Branch',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'English',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:30 AM',
      'phone': '+91 97011 34567',
    },
    {
      'initials': 'SR',
      'name': 'S. Ramana',
      'role': 'Teacher • Steel Plant Branch',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Telugu',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:45 AM',
      'phone': '+91 91210 56789',
    },
    {
      'initials': 'KA',
      'name': 'K. Appalaraju',
      'role': 'Teacher • Steel Plant Branch',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Social',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:25 AM',
      'phone': '+91 93910 67890',
    },
    {
      'initials': 'PS',
      'name': 'P. Satyavathi',
      'role': 'Teacher • Steel Plant Branch',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Hindi',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:38 AM',
      'phone': '+91 98852 78901',
    },
    {
      'initials': 'DJ',
      'name': 'D. Jagadeesh',
      'role': 'Teacher • Steel Plant Branch',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Computers',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:50 AM',
      'phone': '+91 98450 89012',
    },
    {
      'initials': 'TU',
      'name': 'T. Uma',
      'role': 'Teacher • Steel Plant Branch',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Mathematics',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:32 AM',
      'phone': '+91 97766 90123',
    },
    {
      'initials': 'KV',
      'name': 'K. V. Subbarao',
      'role': 'Senior Teacher • Steel Plant Branch',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Academics',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:20 AM',
      'phone': '+91 94411 01234',
    },
    {
      'initials': 'VG',
      'name': 'V. Govinda Rao',
      'role': 'Maths Teacher • Steel Plant Branch',
      'category': 'teaching',
      'subRole': 'teaching',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Mathematics',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:28 AM',
      'phone': '+91 99887 12345',
    },
    {
      'initials': 'LV',
      'name': 'L. Varalakshmi',
      'role': 'Librarian • Steel Plant Branch',
      'category': 'non-teaching',
      'subRole': 'librarian',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Library',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:50 AM',
      'phone': '+91 98855 66778',
    },
    {
      'initials': 'BS',
      'name': 'B. Simhachalam',
      'role': 'Librarian • Steel Plant Branch',
      'category': 'non-teaching',
      'subRole': 'librarian',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Library',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:45 AM',
      'phone': '+91 97000 77889',
    },
    {
      'initials': 'GD',
      'name': 'G. Dhanalakshmi',
      'role': 'Librarian • Steel Plant Branch',
      'category': 'non-teaching',
      'subRole': 'librarian',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Library',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:40 AM',
      'phone': '+91 91212 88990',
    },
    {
      'initials': 'PR',
      'name': 'P. Rambabu',
      'role': 'Librarian • Steel Plant Branch',
      'category': 'non-teaching',
      'subRole': 'librarian',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Library',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:55 AM',
      'phone': '+91 98491 99001',
    },
    {
      'initials': 'MA',
      'name': 'M. Apparao',
      'role': 'Librarian • Steel Plant Branch',
      'category': 'non-teaching',
      'subRole': 'librarian',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Library',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:35 AM',
      'phone': '+91 94401 00112',
    },
    {
      'initials': 'KR',
      'name': 'K. Ramesh',
      'role': 'Administrative Officer • Steel Plant Branch',
      'category': 'non-teaching',
      'subRole': 'admin-officer',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:30 AM',
      'phone': '+91 91210 44556',
    },
    {
      'initials': 'PS',
      'name': 'P. S. Murthy',
      'role': 'Administrative Officer • Steel Plant Branch',
      'category': 'non-teaching',
      'subRole': 'admin-officer',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:40 AM',
      'phone': '+91 97011 11223',
    },
    {
      'initials': 'AV',
      'name': 'Dr. A. V. Rao',
      'role': 'Principal • Steel Plant Branch',
      'category': 'non-teaching',
      'subRole': 'principal',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:00 AM',
      'phone': '+91 94401 22334',
    },
    {
      'initials': 'KS',
      'name': 'K. Swamy',
      'role': 'Principal • Steel Plant Branch',
      'category': 'non-teaching',
      'subRole': 'principal',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:15 AM',
      'phone': '+91 98492 22334',
    },
    {
      'initials': 'VR',
      'name': 'V. R. Sharma',
      'role': 'Account Manager • Steel Plant Branch',
      'category': 'non-teaching',
      'subRole': 'account-mgr',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Accounts',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:45 AM',
      'phone': '+91 98450 11223',
    },
    {
      'initials': 'GA',
      'name': 'G. Appa Rao',
      'role': 'Bus Attendant • Steel Plant Branch',
      'category': 'non-teaching',
      'subRole': 'bus-attendant',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Transport',
      'shift': 'morning',
      'status': 'Absent',
      'subStatus': '08:10 AM',
      'phone': '+91 93910 11223',
    },
    {
      'initials': 'DS',
      'name': 'D. Somulu',
      'role': 'Hostel Warden • Steel Plant Branch',
      'category': 'non-teaching',
      'subRole': 'hostel-warden',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Hostel',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '07:45 AM',
      'phone': '+91 98852 11223',
    },
    {
      'initials': 'KP',
      'name': 'K. Padmavati',
      'role': 'Receptionist • Steel Plant Branch',
      'category': 'non-teaching',
      'subRole': 'receptionist',
      'branchId': 'steel-plant',
      'branchName': 'Steel Plant Branch',
      'department': 'Administration',
      'shift': 'general',
      'status': 'Present',
      'subStatus': '08:25 AM',
      'phone': '+91 97766 22334',
    },
    {
      'initials': 'RK',
      'name': 'Rajesh Kumar',
      'role': 'Transport Manager • Steel Plant Branch',
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
    ];
    return _cachedAllStaffList!;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF6F8FC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _kpiPageController = PageController(initialPage: _activeKpiSet);
    _branchSearchController.addListener(() {
      if (mounted) {
        setState(() {
          _branchSearchQuery = _branchSearchController.text.trim();
          if (_branchSearchQuery.isNotEmpty) {
            _isOrgTreeExpanded = true;
          }
        });
      }
    });
    _fetchDashboard();
    _fetchBranchTree();
    _fetchAttendanceForDate(_selectedAttendanceDate);
    _startKpiTimer();
  }

  @override
  void dispose() {
    _kpiTimer?.cancel();
    _kpiPageController.dispose();
    _usersSearchController.dispose();
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
    if (_dashboardData == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    _fetchBranchTree();

    final token = await SessionManager.getToken();

    if (token != null && token.isNotEmpty) {
      try {
        final res = await http.get(
          Uri.parse(ApiConfig.ownerDashboard),
          headers: ApiConfig.authHeaders(token),
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (mounted && body is Map<String, dynamic>) {
            setState(() {
              _dashboardData = body;
              _branchTreeData = BranchService.parseFromDashboard(
                body,
                orgName: body['orgName'] ?? widget.user.organizationName,
              );
              _isLoading = false;
            });
            _fetchAttendanceForDate(_selectedAttendanceDate);
            return;
          }
        } else if (res.statusCode == 401) {
          final refreshed = await AuthService.refreshToken();
          if (refreshed) {
            final newToken = await SessionManager.getToken();
            if (newToken != null && newToken.isNotEmpty) {
              final retryRes = await http.get(
                Uri.parse(ApiConfig.ownerDashboard),
                headers: ApiConfig.authHeaders(newToken),
              );
              if (retryRes.statusCode == 200) {
                final body = jsonDecode(retryRes.body);
                if (mounted && body is Map<String, dynamic>) {
                  setState(() {
                    _dashboardData = body;
                    _branchTreeData = BranchService.parseFromDashboard(
                      body,
                      orgName: body['orgName'] ?? widget.user.organizationName,
                    );
                    _isLoading = false;
                  });
                  return;
                }
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

  Future<void> _fetchBranchTree({String? period}) async {
    final activePeriod = period ?? _branchPeriod;
    setState(() => _isBranchTreeLoading = true);
    try {
      final tree = await BranchService.fetchBranchTree(
        orgName: _dashboardData?['orgName'] ?? widget.user.organizationName,
        period: activePeriod,
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
          _branchTreeData = BranchGroupNode.empty(
            orgName: _dashboardData?['orgName'] ?? widget.user.organizationName,
          );
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
    if (viewId == 'view-attendance') {
      _fetchAttendanceForDate(_selectedAttendanceDate);
    }
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
    final approvals = _dashboardData?['approvals'] as List<dynamic>? ?? [];

    final systemOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          _isArcMenuOpen ? Brightness.light : Brightness.dark,
      statusBarBrightness:
          _isArcMenuOpen ? Brightness.dark : Brightness.light,
      systemNavigationBarColor:
          _isArcMenuOpen ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC),
      systemNavigationBarIconBrightness:
          _isArcMenuOpen ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: Scaffold(
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
                    _buildHeader(orgName, alerts, approvals, branches),

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
      ),
    );
  }

  // --- Header Component ---
  Widget _buildHeader(
    String orgName,
    List<dynamic> alerts,
    List<dynamic> approvals,
    List<dynamic> branches,
  ) {
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
                  Icons.settings_outlined,
                  const Color(0xFFF59E0B),
                  _fetchDashboard,
                ),
                const SizedBox(width: 6),
                _buildNotificationBell(alerts, approvals, branches),
                const SizedBox(width: 6),
                _buildUserAvatar(),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationBell(
    List<dynamic> alerts,
    List<dynamic> approvals,
    List<dynamic> branches,
  ) {
    final alertCount = alerts.isNotEmpty ? alerts.length : 4;
    final approvalCount = approvals.isNotEmpty ? approvals.length : 10;
    final totalCount = alertCount + approvalCount;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        _openNotificationsSheet(alerts, approvals, branches);
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
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
              child: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFFF43F5E),
                size: 16,
              ),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$totalCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNotificationsSheet(
    List<dynamic> alerts,
    List<dynamic> approvals,
    List<dynamic> branches,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (ctx) {
        return NotificationsDropdownSheet(
          alerts: alerts,
          approvals: approvals,
          branches: branches,
          onClose: () => Navigator.of(ctx).pop(),
          onAlertTap: (al) =>
              Navigator.of(ctx).pop({'action': 'alert', 'data': al}),
          onApprovalTap: (ap) =>
              Navigator.of(ctx).pop({'action': 'approval', 'data': ap}),
        );
      },
    );

    if (!mounted || result == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (result['action'] == 'alert') {
        final al = result['data'] as Map<String, dynamic>;
        final branchName = al['branch']?.toString() ?? 'Gachibowli Campus';
        Map<String, dynamic>? matchedBranch;
        for (final b in branches) {
          if (b is Map && b['name']?.toString() == branchName) {
            matchedBranch = Map<String, dynamic>.from(b);
            break;
          }
        }
        _openBranchDetailsDialog(
          branchName,
          matchedBranch,
        );
      } else if (result['action'] == 'approval') {
        final ap = result['data'] as Map<String, dynamic>;
        _openApprovalDialog(ap);
      }
    });
  }

  void _openBranchDetailsDialog(
    String branchName,
    Map<String, dynamic>? branchData,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (ctx) {
        return BranchNotificationDetailsDialog(
          branchName: branchName,
          branchData: branchData,
          onClose: () => Navigator.of(ctx).pop(),
        );
      },
    );
  }

  void _openApprovalDialog(Map<String, dynamic> ap) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (ctx) {
        return ApprovalDecisionDialog(
          approvalItem: ap,
          onClose: () => Navigator.of(ctx).pop(),
          onDecision: (decision, note) {
            final id = ap['id']?.toString() ?? '';
            setState(() {
              if (decision == 'approved') {
                _approvedItemIds.add(id);
              } else {
                _approvedItemIds.remove(id);
              }
            });
            _fetchDashboard();
          },
        );
      },
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
        'id': 'view-academics',
        'label': 'Academics',
        'icon': Icons.school_outlined,
      },
      {
        'id': 'view-operations',
        'label': 'People & Ops',
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
        return _buildOperationsView(branches);
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
    // Dynamic values from backend
    final students = group?['students'] ?? 122;
    final studentsDelta = group?['studentsDelta'] != null ? '+${group!['studentsDelta']}%' : '+11.9%';

    final rawRev = group?['revenueYTD'] ?? group?['revenue'];
    final ytdRevenue = rawRev is num
        ? '₹${(rawRev / 10000000).toStringAsFixed(1)} Cr'
        : (rawRev?.toString() ?? '₹1.4 Cr');
    final revenueDelta = group?['revenueDelta'] != null ? '+${group!['revenueDelta']}%' : '+0%';

    final collectionPct = (group?['collectionPct'] as num?)?.toDouble() ?? 68.2;

    final attStudents = _dashboardData?['attendance']?['students'] as Map<String, dynamic>?;
    final stuPres = (attStudents?['present'] as num?)?.toInt() ?? 22;
    final stuRoster = (attStudents?['roster'] as num?)?.toInt() ?? (students is int ? students : 122);
    final studentAttendance = '$stuPres/$stuRoster';
    final stuPct = (attStudents?['attendancePct'] as num?)?.toDouble() ?? (stuRoster > 0 ? (stuPres / stuRoster * 100) : 0.0);
    final stuBadge = '${stuPct.toStringAsFixed(1)}%';

    final rawCash = group?['cashToday'] ?? group?['cashCollectedToday'];
    final cashToday = rawCash is num
        ? '₹${(rawCash / 100000).toStringAsFixed(1)} L'
        : (rawCash?.toString() ?? '₹0.2 L');

    final newAdmissions = group?['newAdmissionsMTD'] ?? group?['newAdmissions'] ?? 25;
    final staffFilled = group?['staffFilled'] ?? group?['staffCount'] ?? 46;
    final staffVacant = group?['staffVacant'] ?? 23;
    final studentAttrition = (group?['attritionPct'] ?? group?['attrition'] as num?)?.toDouble() ?? 4.9;
    final operatingMargin = (group?['ebitdaMargin'] as num?)?.toDouble() ?? 35.9;

    final attStaff = _dashboardData?['attendance']?['staff'] as Map<String, dynamic>?;
    final staffPres = (attStaff?['present'] as num?)?.toInt() ?? 0;
    final staffRoster = (attStaff?['roster'] as num?)?.toInt() ?? (staffFilled is int ? staffFilled : 46);
    final staffAttendance = '$staffPres/$staffRoster';
    final staffAbsent = (attStaff?['absent'] as num?)?.toInt() ?? 1;

    final rawOut = group?['outstanding'] ?? group?['outstandingFees'];
    final outstanding = rawOut is num
        ? '₹${(rawOut / 100000).toStringAsFixed(1)} L'
        : (rawOut?.toString() ?? '₹45.0 L');

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
          'badge': studentsDelta,
          'badgeColor': const Color(0xFF059669),
          'badgeBg': const Color(0xFFECFDF5),
          'valColor': const Color(0xFF0F172A),
        },
        {
          'label': 'YTD Revenue',
          'value': ytdRevenue,
          'badge': revenueDelta,
          'badgeColor': const Color(0xFF7C3AED),
          'badgeBg': const Color(0xFFFAF5FF),
          'valColor': const Color(0xFF7C3AED),
        },
        {
          'label': 'Fees Collected',
          'value': '${collectionPct.toStringAsFixed(1)}%',
          'badge': '-19.8 pts',
          'badgeColor': const Color(0xFFE11D48),
          'badgeBg': const Color(0xFFFFE4E6),
          'valColor': const Color(0xFF0F172A),
        },
        {
          'label': 'Student Attend',
          'value': studentAttendance,
          'badge': stuBadge,
          'badgeColor': const Color(0xFF64748B),
          'badgeBg': const Color(0xFFF1F5F9),
          'valColor': const Color(0xFF0F172A),
        },
      ],
      // SET 2: Cash & Staffing
      [
        {
          'label': 'Cash Today',
          'value': cashToday,
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
          'badge': '$staffVacant Open',
          'badgeColor': const Color(0xFFD97706),
          'badgeBg': const Color(0xFFFFFBEB),
          'valColor': const Color(0xFF0F172A),
        },
        {
          'label': 'Student Attrition',
          'value': '${studentAttrition.toStringAsFixed(1)}%',
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
          'value': '${operatingMargin.toStringAsFixed(1)}%',
          'badge': 'EBITDA',
          'badgeColor': const Color(0xFF059669),
          'badgeBg': const Color(0xFFECFDF5),
          'valColor': const Color(0xFF7C3AED),
        },
        {
          'label': 'Staff Attend',
          'value': staffAttendance,
          'badge': '$staffAbsent Absent',
          'badgeColor': const Color(0xFFE11D48),
          'badgeBg': const Color(0xFFFFE4E6),
          'valColor': const Color(0xFFE11D48),
        },
        {
          'label': 'Outstanding Fees',
          'value': outstanding,
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
    final collection = _dashboardData?['collection'] as Map<String, dynamic>?;
    final colPct = (collection?['collectionPct'] as num?)?.toDouble() ??
        (group?['collectionPct'] as num?)?.toDouble() ??
        68.2;
    final duePct = (collection?['duePct'] as num?)?.toDouble() ?? 18.4;
    final overduePct = (collection?['overduePct'] as num?)?.toDouble() ?? 13.3;

    final rawCollected = collection?['collected'] ?? group?['collectedYTD'] ?? 9658180;
    final colStr = rawCollected is num ? '₹${(rawCollected / 100000).toStringAsFixed(1)} L' : '₹96.6 L';

    final rawDue = collection?['due'] ?? 2608167;
    final dueStr = rawDue is num ? '₹${(rawDue / 100000).toStringAsFixed(1)} L' : '₹26.1 L';

    final rawOverdue = collection?['overdue'] ?? 1888673;
    final overdueStr = rawOverdue is num ? '₹${(rawOverdue / 100000).toStringAsFixed(1)} L' : '₹18.9 L';

    final aging = collection?['aging'] as Map<String, dynamic>?;
    final num a0 = (aging?['current'] as num?) ?? 2608167;
    final num a30 = (aging?['days30'] as num?) ?? 944336;
    final num a60 = (aging?['days60'] as num?) ?? 566602;
    final num a90 = (aging?['days90Plus'] as num?) ?? 377735;
    final num totalOut = a0 + a30 + a60 + a90;
    final totalOutStr = '₹${(totalOut / 100000).toStringAsFixed(1)} L Total';

    final a0Pct = totalOut > 0 ? (a0 / totalOut * 100).toStringAsFixed(1) : '58.0';
    final a30Pct = totalOut > 0 ? (a30 / totalOut * 100).toStringAsFixed(1) : '21.0';
    final a60Pct = totalOut > 0 ? (a60 / totalOut * 100).toStringAsFixed(1) : '12.6';
    final a90Pct = totalOut > 0 ? (a90 / totalOut * 100).toStringAsFixed(1) : '8.4';

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
                      children: [
                        const Icon(Icons.circle, color: Color(0xFF10B981), size: 5),
                        const SizedBox(width: 4),
                        Text(
                          'EBITDA ${(group?['ebitdaMargin'] ?? 35.9)}%',
                          style: const TextStyle(
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
                    const Expanded(
                      child: Text(
                        'CASH TRAJECTORY (₹ LAKHS)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
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
                  child: CustomPaint(
                    painter: CashTrajectoryPainter(
                      ebitdaMargin: (group?['ebitdaMargin'] as num?)?.toDouble() ?? 35.9,
                      collectionPct: (group?['collectionPct'] as num?)?.toDouble() ?? 68.2,
                    ),
                  ),
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
                          collectedPct: colPct,
                          duePct: duePct,
                          overduePct: overduePct,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${colPct.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
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
                          Text(
                            colStr,
                            style: const TextStyle(
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
                          Text(
                            dueStr,
                            style: const TextStyle(
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
                          Text(
                            overdueStr,
                            style: const TextStyle(
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
            children: [
              const Text(
                'RECEIVABLES AGING',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                totalOutStr,
                style: const TextStyle(
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
                '₹${(a0 / 100000).toStringAsFixed(1)} L',
                '$a0Pct%',
                const Color(0xFF059669),
                const Color(0xFFF8FAFC),
              ),
              const SizedBox(width: 6),
              _buildAgingBox(
                '31–60 D',
                '₹${(a30 / 100000).toStringAsFixed(1)} L',
                '$a30Pct%',
                const Color(0xFFD97706),
                const Color(0xFFF8FAFC),
              ),
              const SizedBox(width: 6),
              _buildAgingBox(
                '61–90 D',
                '₹${(a60 / 100000).toStringAsFixed(1)} L',
                '$a60Pct%',
                const Color(0xFFE11D48),
                const Color(0xFFF8FAFC),
              ),
              const SizedBox(width: 6),
              _buildAgingBox(
                '90+ D',
                '₹${(a90 / 100000).toStringAsFixed(1)} L',
                '$a90Pct%',
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
    final branches = _dashboardData?['branches'] as List<dynamic>? ?? [];
    final totalBranchesCount = branches.isNotEmpty ? branches.length : 6;

    final sorted = List<Map<String, dynamic>>.from(
      branches.map((e) => e as Map<String, dynamic>),
    );
    sorted.sort((a, b) => ((b['revenue'] as num?) ?? 0).compareTo((a['revenue'] as num?) ?? 0));
    final top3 = sorted.take(3).toList();

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
              const Expanded(
                child: Text(
                  'Branch Performance Benchmark',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                  child: Text(
                    'All $totalBranchesCount Branches →',
                    style: const TextStyle(
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

          if (top3.isNotEmpty)
            ...top3.asMap().entries.map((entry) {
              final idx = entry.key;
              final b = entry.value;
              final name = b['name']?.toString() ?? 'Branch';
              final stu = b['students'] ?? 0;
              final teachers = b['teachers'] ?? b['staffTeach'] ?? 2;
              final rev = b['revenue'];
              final revStr = rev is num ? '₹${(rev / 100000).toStringAsFixed(1)} L Rev' : '₹0.0 L Rev';
              final health = b['health'] ?? 75;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: _buildQuickBenchmarkItem(
                  name: name,
                  sub: '$stu Students · $teachers Faculty · $revStr',
                  score: '$health%',
                  rank: 'Rank #${idx + 1}',
                  isTop: idx == 0,
                ),
              );
            })
          else ...[
            _buildQuickBenchmarkItem(
              name: 'Gachibowli Campus',
              sub: '21 Students · 2 Faculty · ₹27.3 L Rev',
              score: '75%',
              rank: 'Rank #1',
              isTop: true,
            ),
            const SizedBox(height: 6),
            _buildQuickBenchmarkItem(
              name: 'Steel Plant Branch',
              sub: '43 Students · 2 Faculty · ₹26.5 L Rev',
              score: '70%',
              rank: 'Rank #2',
              isTop: false,
            ),
            const SizedBox(height: 6),
            _buildQuickBenchmarkItem(
              name: 'Kukatpally Campus',
              sub: '17 Students · 2 Faculty · ₹23.4 L Rev',
              score: '76%',
              rank: 'Rank #3',
              isTop: false,
            ),
          ],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
    final branchList = (branches.isNotEmpty ? branches : (_dashboardData?['branches'] as List<dynamic>? ?? []));
    final group = _dashboardData?['group'] as Map<String, dynamic>?;
    final double avgCollection = (group?['collectionPct'] as num?)?.toDouble() ?? 68.2;
    final double avgAttendance = (group?['attendance'] as num?)?.toDouble() ?? 92.1;
    final List<Map<String, dynamic>> branchQuadrantData = branchList.asMap().entries.map((entry) {
      final idx = entry.key;
      final b = entry.value as Map<String, dynamic>;
      final name = b['name']?.toString() ?? 'Branch';
      final color = _getBranchColor(name, idx);
      final double colPct = (b['collectionPct'] as num?)?.toDouble() ?? 68.0;
      final double attPct = (b['attendancePct'] as num?)?.toDouble() ?? 92.0;
      final int students = (b['students'] as num?)?.toInt() ?? 10;
      return {
        'name': name,
        'code': b['code']?.toString() ?? '',
        'color': color,
        'collectionPct': colPct,
        'attendancePct': attPct,
        'students': students,
      };
    }).toList();

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
                  children: const [
                    Text(
                      'Performance quadrant',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Collection × attendance · bubble = enrolment',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                  child: CustomPaint(
                    painter: PerformanceQuadrantPainter(
                      branches: branchQuadrantData,
                      avgCollection: avgCollection,
                      avgAttendance: avgAttendance,
                    ),
                  ),
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

          // Interactive Dynamic Legend
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: branchQuadrantData.map((b) {
              return _QuadrantLegendItem(
                color: b['color'] as Color,
                label: b['name'] as String,
              );
            }).toList(),
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
    final branchList = (branches.isNotEmpty ? branches : (_dashboardData?['branches'] as List<dynamic>? ?? []));
    final branchesData = branchList.asMap().entries.map((entry) {
      final idx = entry.key;
      final m = entry.value as Map<String, dynamic>;
      final name = m['name']?.toString() ?? 'Branch';
      final health = (m['health'] as num?)?.toInt() ?? 75;
      final rev = m['revenue'];
      final revStr = rev is num ? '₹${(rev / 100000).toStringAsFixed(1)} L' : '₹0.0 L';
      final col = _getBranchColor(name, idx);

      return {
        'name': name,
        'pct': health,
        'rev': revStr,
        'color': col,
      };
    }).toList();

    branchesData.sort((a, b) => (b['pct'] as int).compareTo(a['pct'] as int));

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
    final alertList = (alerts.isNotEmpty ? alerts : (_dashboardData?['alerts'] as List<dynamic>? ?? []));
    final alertItems = alertList.isNotEmpty
        ? alertList.take(6).map((al) {
            final m = al as Map<String, dynamic>;
            final id = m['id']?.toString() ?? 'alt-${m['branch']}-${m['text'] ?? m['title']}';
            final type = (m['type']?.toString() ?? 'ALERT').toUpperCase();
            final time = m['time']?.toString() ?? 'today';
            final title = m['text']?.toString() ?? m['title']?.toString() ?? '';
            final branch = m['branch']?.toString() ?? '';
            final level = (m['level'] ?? m['severity'])?.toString().toLowerCase();
            final isRose = level == 'critical' || level == 'danger';
            return {
              'id': id,
              'tag': type,
              'time': time,
              'title': title,
              'branch': branch,
              'isRose': isRose,
            };
          }).toList()
        : [
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
    final rawApprovals = _dashboardData?['approvals'] as List<dynamic>? ?? [];
    final approvals = rawApprovals.isNotEmpty
        ? rawApprovals.take(6).map((ap) {
            final m = ap as Map<String, dynamic>;
            final id = m['id']?.toString() ?? 'apr-${m['type']}-${m['branch']}';
            final type = m['type']?.toString() ?? 'Approval';
            final text = m['text']?.toString() ?? '';
            final title = m['title']?.toString() ?? (text.isNotEmpty ? '$type · $text' : type);
            final branch = m['branch']?.toString() ?? '';
            final age = m['age']?.toString() ?? '';
            final meta = m['meta']?.toString() ?? (age.isNotEmpty ? '$branch · $age waiting' : branch);
            final num? amt = m['amount'] as num?;
            String amtStr = '';
            if (amt != null && amt > 0) {
              amtStr = amt >= 100000
                  ? '₹${(amt / 100000).toStringAsFixed(1)} L'
                  : '₹${amt.toInt()}';
            }
            return {
              'id': id,
              'title': title,
              'meta': meta,
              'amount': amtStr,
            };
          }).toList()
        : [
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
    final rawFunnel = _dashboardData?['funnel'] as List<dynamic>? ?? [];
    num maxVal = 1;
    for (final fn in rawFunnel) {
      if (fn is Map) {
        final v = (fn['value'] ?? fn['count'] as num?) ?? 0;
        if (v > maxVal) maxVal = v;
      }
    }
    num prevCount = 0;
    final stages = rawFunnel.isNotEmpty
        ? rawFunnel.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value as Map<String, dynamic>;
            final label = m['stage']?.toString() ?? m['label']?.toString() ?? '';
            final count = (m['value'] as num?)?.toInt() ?? (m['count'] as num?)?.toInt() ?? 0;
            final pct = (m['pct'] as num?)?.round() ?? ((count / maxVal) * 100).clamp(10, 100).round();
            String sub = '';
            if (idx > 0 && prevCount > 0) {
              final stepConv = ((count / prevCount) * 100).round();
              sub = '↳ $stepConv% step conversion';
            }
            prevCount = count;
            return {
              'label': label,
              'count': count,
              'pct': pct,
              'sub': sub,
            };
          }).toList()
        : [
            {'label': 'Enquiries', 'count': 16, 'pct': 64, 'sub': ''},
            {'label': 'Applications', 'count': 25, 'pct': 100, 'sub': '↳ 156% step conversion'},
            {'label': 'Shortlisted', 'count': 9, 'pct': 36, 'sub': '↳ 36% step conversion'},
            {'label': 'Admitted', 'count': 8, 'pct': 32, 'sub': '↳ 89% step conversion'},
            {'label': 'Enrolled', 'count': 2, 'pct': 8, 'sub': '↳ 25% step conversion'},
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

  void _openBranchDropdown(BuildContext context, BranchGroupNode treeData) {
    HapticFeedback.selectionClick();
    final renderBox = _branchDropdownKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;

    RelativeRect position = const RelativeRect.fromLTRB(100, 160, 100, 0);
    if (renderBox != null && overlay != null) {
      final buttonTopLeft = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
      final buttonBottomRight = renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero), ancestor: overlay);
      position = RelativeRect.fromLTRB(
        buttonTopLeft.dx,
        buttonBottomRight.dy + 4,
        overlay.size.width - buttonBottomRight.dx,
        overlay.size.height - buttonBottomRight.dy,
      );
    }

    final options = [
      'All branches',
      ...treeData.branches.map((b) => b.name),
    ];

    showMenu<String>(
      context: context,
      position: position,
      elevation: 6,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      items: options.map((opt) {
        final isSel = opt == _branchSelectedFilter;
        final matchingBranch = (opt == 'All branches' || treeData.branches.isEmpty)
            ? null
            : treeData.branches.where((b) => b.name == opt).firstOrNull;
        return PopupMenuItem<String>(
          value: opt,
          height: 42,
          child: Row(
            children: [
              if (opt == 'All branches')
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF7C3AED),
                    shape: BoxShape.circle,
                  ),
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: matchingBranch?.dotColor ?? const Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  opt,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                    color: isSel ? const Color(0xFF7C3AED) : const Color(0xFF0F172A),
                  ),
                ),
              ),
              if (isSel)
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Color(0xFF7C3AED),
                ),
            ],
          ),
        );
      }).toList(),
    ).then((val) {
      if (val != null && mounted) {
        HapticFeedback.selectionClick();
        setState(() {
          _branchSelectedFilter = val;
          _isOrgTreeExpanded = true;
        });
      }
    });
  }

  // --- Sub-Views (Branch Tree, Student 360, Finance, Ops) ---
  Widget _buildBranchTreeView([List<dynamic>? branches]) {
    final treeData = _branchTreeData ??
        (branches != null && branches.isNotEmpty
            ? BranchService.parseFromDashboard(
                {
                  'orgName': _dashboardData?['orgName'] ?? widget.user.organizationName,
                  'group': _dashboardData?['group'],
                  'branches': branches,
                },
                orgName: _dashboardData?['orgName'] ?? widget.user.organizationName,
              )
            : BranchGroupNode.empty(
                orgName: _dashboardData?['orgName'] ?? widget.user.organizationName,
              ));
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

        // Control bar: [All branches v]
        Row(
          children: [
            // Dropdown for branches
            GestureDetector(
              key: _branchDropdownKey,
              onTap: () => _openBranchDropdown(context, treeData),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _branchSelectedFilter,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
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
                text: '• roll-ups aggregate every child · ',
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
                _branchSelectedFilter == 'All branches'
                    ? '${treeData.totalBranches} branches across ${treeData.totalRegions} region'
                    : '${filteredBranches.length} of ${treeData.totalBranches} branches (Filtered by $_branchSelectedFilter)',
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
                          children: [
                            const SizedBox(
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
                            const SizedBox(
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
                            const SizedBox(
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
                                'COLLECTION',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Color(0xFF7C3AED),
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
                                  '${treeData.getCollectionPctForPeriod(_branchPeriod).toStringAsFixed(treeData.getCollectionPctForPeriod(_branchPeriod) % 1 == 0 ? 0 : 1)}%',
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
                        if (treeData.branches.isEmpty)
                          Container(
                            width: 420,
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.account_tree_outlined,
                                    size: 32,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No branches returned from API',
                                    style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Only branches provided by the API will be displayed here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () {
                                      _fetchDashboard();
                                      _fetchBranchTree();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEDE9FE),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Reload API',
                                        style: TextStyle(
                                          color: Color(0xFF7C3AED),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (filteredBranches.isEmpty)
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
                                        '${branch.getCollectionPctForPeriod(_branchPeriod).toStringAsFixed(branch.getCollectionPctForPeriod(_branchPeriod) % 1 == 0 ? 0 : 1)}%',
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
        return StatefulBuilder(
          builder: (modalCtx, _) {
            final periodColPct = branch.getCollectionPctForPeriod(_branchPeriod);
            final periodRev = branch.getRevenueForPeriod(_branchPeriod);
            final periodOutstanding = branch.getOutstandingForPeriod(_branchPeriod);
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
                  const SizedBox(height: 16),
                  // KPI Cards Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildDrillCard(
                          'STUDENTS',
                          '${branch.students}',
                          '${branch.capacityPct.toStringAsFixed(branch.capacityPct % 1 == 0 ? 0 : 1)}% of ${branch.capacity} capacity',
                          const Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDrillCard(
                          'COLLECTION',
                          '${periodColPct.toStringAsFixed(periodColPct % 1 == 0 ? 0 : 1)}%',
                          periodRev > 0
                              ? '₹${periodRev >= 100000 ? "${(periodRev / 100000).toStringAsFixed(1)}L" : periodRev.toStringAsFixed(0)} billed'
                              : 'Fees collected',
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
                          '${branch.attendancePct.toStringAsFixed(branch.attendancePct % 1 == 0 ? 0 : 1)}%',
                          'Present today',
                          const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDrillCard(
                          'FACULTY & DUES',
                          '${branch.teachers} Staff',
                          periodOutstanding > 0
                              ? '₹${periodOutstanding >= 100000 ? "${(periodOutstanding / 100000).toStringAsFixed(1)}L" : periodOutstanding.toStringAsFixed(0)} dues'
                              : 'Exam Index: ${branch.examIndex}',
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
    return const StudentLookupView();
  }

  Widget _buildFinanceFeesView(Map<String, dynamic>? group) {
    return FinanceFeesView(
      initialGroup: group,
      initialBranches: _dashboardData?['branches'] as List<dynamic>?,
      activePeriod: _financePeriod,
      selectedBranch: _financeBranch,
      onPeriodChanged: (p) => setState(() => _financePeriod = p),
      onBranchChanged: (b) => setState(() => _financeBranch = b),
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
    return AcademicsView(dashboardData: _dashboardData);
  }

  Widget _buildOperationsView(List<dynamic> branches) {
    return PeopleOpsView(
      branches: branches,
      dashboardData: _dashboardData,
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
    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedAttendanceDate = picked;
      });
      await _fetchAttendanceForDate(picked);
    }
  }

  Future<void> _fetchAttendanceForDate(DateTime date) async {
    if (!mounted) return;
    setState(() {
      _isAttendanceLoading = true;
    });

    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _isAttendanceLoading = false;
        });
      }
      return;
    }

    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final url = '${ApiConfig.ownerAttendance}?date=$dateStr';

    try {
      var res = await http.get(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
      );

      if (res.statusCode == 401) {
        final refreshed = await AuthService.refreshToken();
        if (refreshed) {
          final newToken = await SessionManager.getToken();
          if (newToken != null && newToken.isNotEmpty) {
            res = await http.get(
              Uri.parse(url),
              headers: ApiConfig.authHeaders(newToken),
            );
          }
        }
      }

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic> && mounted) {
          _applyAttendanceData(body);
        }
      }
    } catch (e) {
      debugPrint('Error fetching attendance for date $dateStr: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAttendanceLoading = false;
        });
      }
    }
  }

  void _applyAttendanceData(Map<String, dynamic> body) {
    final rawByBranch = body['byBranch'] as Map<String, dynamic>? ?? {};

    _updateRosterStatusesFromAttendance(rawByBranch);

    setState(() {
      _dashboardData ??= {};
      _dashboardData!['attendance'] = body;

      final branches = _dashboardData!['branches'] as List<dynamic>?;
      if (branches != null) {
        for (final b in branches) {
          if (b is Map<String, dynamic>) {
            final bName = (b['name']?.toString() ?? '').toLowerCase();
            final bSlug = _getBranchSlug(bName);
            for (final entry in rawByBranch.entries) {
              final eName = entry.key.toLowerCase();
              final eSlug = _getBranchSlug(eName);
              if (eSlug == bSlug || bName.contains(eName) || eName.contains(bName)) {
                if (entry.value is Map<String, dynamic>) {
                  b['attendanceCounts'] = entry.value;
                }
                break;
              }
            }
          }
        }
      }
    });
  }

  void _updateRosterStatusesFromAttendance(Map<String, dynamic> rawByBranch) {
    final allStudents = _getAllStudentRecords();
    final allStaff = _getAllStaffRecords();

    rawByBranch.forEach((branchName, val) {
      if (val is! Map<String, dynamic>) return;
      final branchSlug = _getBranchSlug(branchName);

      final stu = val['students'] as Map<String, dynamic>?;
      if (stu != null) {
        final pCount = (stu['present'] as num?)?.toInt() ?? 0;
        final aCount = (stu['absent'] as num?)?.toInt() ?? 0;
        final lCount = (stu['leave'] as num?)?.toInt() ?? 0;

        final branchStudents = allStudents.where((s) => s['branchId'] == branchSlug).toList();
        int idx = 0;
        for (int i = 0; i < aCount && idx < branchStudents.length; i++, idx++) {
          branchStudents[idx]['status'] = 'Absent';
        }
        for (int i = 0; i < pCount && idx < branchStudents.length; i++, idx++) {
          branchStudents[idx]['status'] = 'Present';
        }
        for (int i = 0; i < lCount && idx < branchStudents.length; i++, idx++) {
          branchStudents[idx]['status'] = 'On Leave';
        }
        while (idx < branchStudents.length) {
          branchStudents[idx]['status'] = 'Not marked';
          idx++;
        }
      }

      final staff = val['staff'] as Map<String, dynamic>?;
      if (staff != null) {
        final pCount = (staff['present'] as num?)?.toInt() ?? 0;
        final aCount = (staff['absent'] as num?)?.toInt() ?? 0;
        final lCount = (staff['leave'] as num?)?.toInt() ?? 0;

        final branchStaff = allStaff.where((st) => st['branchId'] == branchSlug).toList();
        int idx = 0;
        for (int i = 0; i < lCount && idx < branchStaff.length; i++, idx++) {
          branchStaff[idx]['status'] = 'On Leave';
        }
        for (int i = 0; i < aCount && idx < branchStaff.length; i++, idx++) {
          branchStaff[idx]['status'] = 'Absent';
        }
        for (int i = 0; i < pCount && idx < branchStaff.length; i++, idx++) {
          branchStaff[idx]['status'] = 'Present';
        }
        while (idx < branchStaff.length) {
          branchStaff[idx]['status'] = 'Not marked';
          idx++;
        }
      }
    });
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
        final count = (_dashboardData?['branches'] as List?)?.length ?? 6;
        return 'All branches ($count)';
    }
  }

  Color _getBranchColor(String name, int index) {
    final lower = name.toLowerCase();
    if (lower.contains('steel')) return const Color(0xFF10B981);
    if (lower.contains('gachi')) return const Color(0xFF8B5CF6);
    if (lower.contains('kondapur')) return const Color(0xFF06B6D4);
    if (lower.contains('kukat')) return const Color(0xFFA855F7);
    if (lower.contains('maddipalem')) return const Color(0xFFEF4444);
    if (lower.contains('madhapur')) return const Color(0xFFF59E0B);
    const palette = [
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFFA855F7),
      Color(0xFFEF4444),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
    ];
    return palette[index % palette.length];
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
    final branches = _dashboardData?['branches'] as List<dynamic>? ?? [];
    final totalCount = branches.isNotEmpty ? branches.length : 6;

    final List<Map<String, String>> options = [
      {'id': 'all', 'label': 'All branches ($totalCount)'},
    ];

    if (branches.isNotEmpty) {
      for (final b in branches) {
        final bm = b as Map<String, dynamic>;
        final name = bm['name']?.toString() ?? 'Branch';
        final stu = bm['students'] ?? 0;
        final stf = bm['staffTotal'] ?? bm['teachers'] ?? 4;
        final lower = name.toLowerCase();
        final id = lower.contains('steel')
            ? 'steel-plant'
            : lower.contains('gachi')
                ? 'gachibowli'
                : lower.contains('maddipalem')
                    ? 'maddipalem'
                    : lower.contains('kukat')
                        ? 'kukatpally'
                        : lower.contains('kondapur')
                            ? 'kondapur'
                            : 'madhapur';
        options.add({
          'id': id,
          'label': '$name ($stu Roll / $stf Staff)',
        });
      }
    } else {
      options.addAll([
        {'id': 'steel-plant', 'label': 'Steel Plant Branch (43 Roll / 25 Staff)'},
        {'id': 'gachibowli', 'label': 'Gachibowli Campus (21 Roll / 4 Staff)'},
        {'id': 'maddipalem', 'label': 'Maddipalem Branch (18 Roll / 5 Staff)'},
        {'id': 'kukatpally', 'label': 'Kukatpally Campus (17 Roll / 4 Staff)'},
        {'id': 'kondapur', 'label': 'Kondapur Branch (14 Roll / 4 Staff)'},
        {'id': 'madhapur', 'label': 'Madhapur Branch (9 Roll / 4 Staff)'},
      ]);
    }

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
        _showAllAttendanceStudents = false;
      } else {
        _staffRoleFilter = 'all-staff';
        _staffSubFilter = 'all-nt';
        _selectedDeptFilter = 'all';
        _selectedShiftFilter = 'general';
        _rosterFilterPill = 'all';
        _showAllAttendanceStaff = false;
      }
    });
  }

  String _getBranchSlug(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('steel')) return 'steel-plant';
    if (lower.contains('gachi')) return 'gachibowli';
    if (lower.contains('maddipalem')) return 'maddipalem';
    if (lower.contains('kukat')) return 'kukatpally';
    if (lower.contains('kondapur')) return 'kondapur';
    return 'madhapur';
  }

  String _roleNameToSlug(String roleName) {
    final lower = roleName.toLowerCase();
    if (lower.contains('admin')) return 'admin-officer';
    if (lower.contains('principal')) return 'principal';
    if (lower.contains('librar')) return 'librarian';
    if (lower.contains('account')) return 'account-mgr';
    if (lower.contains('bus')) return 'bus-attendant';
    if (lower.contains('hostel') || lower.contains('warden')) return 'hostel-warden';
    if (lower.contains('reception')) return 'receptionist';
    if (lower.contains('transport')) return 'transport-mgr';
    return lower.replaceAll(' ', '-');
  }

  String _slugToRoleName(String slug) {
    switch (slug) {
      case 'admin-officer':
        return 'Administrative Officer';
      case 'principal':
        return 'Principal';
      case 'librarian':
        return 'Librarian';
      case 'account-mgr':
        return 'Account Manager';
      case 'bus-attendant':
        return 'Bus Attendant';
      case 'hostel-warden':
        return 'Hostel Warden';
      case 'receptionist':
        return 'Receptionist';
      case 'transport-mgr':
        return 'Transport Manager';
      default:
        return 'Staff';
    }
  }

  Map<String, int> _getNonTeachingRolesCounts() {
    final branches = _dashboardData?['branches'] as List<dynamic>? ?? [];
    final Map<String, int> counts = {};

    for (final b in branches) {
      if (b is! Map<String, dynamic>) continue;
      final bSlug = _getBranchSlug(b['name']?.toString() ?? '');
      if (_selectedBranchFilter != 'all' && bSlug != _selectedBranchFilter) {
        continue;
      }
      final roles = b['roles'] as List<dynamic>? ?? [];
      for (final r in roles) {
        if (r is! Map<String, dynamic>) continue;
        final roleName = r['role']?.toString() ?? '';
        final filled = (r['filled'] as num?)?.toInt() ?? 0;
        final isTeaching = roleName.toLowerCase().contains('teacher') ||
            roleName.toLowerCase().contains('faculty');
        if (!isTeaching && filled > 0) {
          counts[roleName] = (counts[roleName] ?? 0) + filled;
        }
      }
    }
    return counts;
  }

  bool _matchesStaffSubRole(Map<String, dynamic> st, String subFilter) {
    if (subFilter == 'all-nt') return st['category'] == 'non-teaching';
    final role = (st['role']?.toString() ?? '').toLowerCase();
    final subRole = (st['subRole']?.toString() ?? '').toLowerCase();

    switch (subFilter) {
      case 'admin-officer':
        return subRole == 'admin-officer' || role.contains('admin');
      case 'principal':
        return subRole == 'principal' || role.contains('principal');
      case 'librarian':
        return subRole == 'librarian' || role.contains('librar');
      case 'account-mgr':
        return subRole == 'account-mgr' || role.contains('account');
      case 'bus-attendant':
        return subRole == 'bus-attendant' || role.contains('bus');
      case 'hostel-warden':
        return subRole == 'hostel-warden' || role.contains('hostel') || role.contains('warden');
      case 'receptionist':
        return subRole == 'receptionist' || role.contains('reception');
      case 'transport-mgr':
        return subRole == 'transport-mgr' || role.contains('transport');
      default:
        return subRole == subFilter;
    }
  }

  String _getStaffScopeSubtitle() {
    if (_staffRoleFilter == 'teaching') return 'teaching faculty';
    if (_staffRoleFilter == 'non-teaching') {
      if (_staffSubFilter == 'all-nt') return 'non-teaching staff';
      return '${_slugToRoleName(_staffSubFilter).toLowerCase()}s';
    }
    return 'sanctioned staff';
  }

  Map<String, dynamic> _getAttendanceAggregateStats(bool isStudents) {
    final attData = _dashboardData?['attendance'] as Map<String, dynamic>?;
    final branches = _dashboardData?['branches'] as List<dynamic>? ?? [];
    final rawByBranch = attData?['byBranch'];
    final List<Map<String, dynamic>> byBranch = [];
    if (rawByBranch is List) {
      for (final item in rawByBranch) {
        if (item is Map<String, dynamic>) {
          final bName = item['branchName']?.toString() ?? item['branchCode']?.toString() ?? '';
          byBranch.add({
            'branchCode': bName,
            'branchName': bName,
            'branchSlug': _getBranchSlug(bName),
            ...item,
          });
        }
      }
    } else if (rawByBranch is Map) {
      rawByBranch.forEach((k, v) {
        if (v is Map) {
          final bName = k.toString();
          byBranch.add({
            'branchCode': bName,
            'branchName': bName,
            'branchSlug': _getBranchSlug(bName),
            ...v.cast<String, dynamic>(),
          });
        }
      });
    }

    if (isStudents) {
      int total = 0;
      int present = 0;
      int absent = 0;
      int leave = 0;
      int pending = 0;

      if (_selectedBranchFilter == 'all') {
        if (byBranch.isNotEmpty) {
          for (final bm in byBranch) {
            final s = bm['students'] as Map<String, dynamic>?;
            if (s != null) {
              total += (s['roster'] as num?)?.toInt() ?? 0;
              present += (s['present'] as num?)?.toInt() ?? 0;
              absent += (s['absent'] as num?)?.toInt() ?? 0;
              leave += (s['leave'] as num?)?.toInt() ?? 0;
              pending += (s['notMarked'] as num?)?.toInt() ?? 0;
            }
          }
        }
        if (total == 0) {
          final stuOverall = attData?['students'] as Map<String, dynamic>?;
          total = (stuOverall?['roster'] as num?)?.toInt() ??
              (_dashboardData?['group']?['students'] as num?)?.toInt() ??
              122;
          present = (stuOverall?['present'] as num?)?.toInt() ?? 0;
          absent = (stuOverall?['absent'] as num?)?.toInt() ?? 0;
          leave = (stuOverall?['leave'] as num?)?.toInt() ?? 0;
          pending = (stuOverall?['notMarked'] as num?)?.toInt() ?? (total - present - absent - leave);
        } else if (pending == 0 && (present + absent + leave) < total) {
          pending = total - present - absent - leave;
        }
      } else {
        Map<String, dynamic>? bAtt;
        for (final bm in byBranch) {
          final bSlug = (bm['branchSlug'] ?? _getBranchSlug(bm['branchName']?.toString() ?? '')).toString().toLowerCase();
          final bName = (bm['branchName']?.toString() ?? '').toLowerCase();
          final target = _selectedBranchFilter.replaceAll('-', ' ').toLowerCase();
          if (bSlug == _selectedBranchFilter || bName.contains(target)) {
            bAtt = bm['students'] as Map<String, dynamic>?;
            break;
          }
        }
        if (bAtt == null) {
          for (final b in branches) {
            final bm = b as Map<String, dynamic>;
            final bName = (bm['name']?.toString() ?? '').toLowerCase();
            final bCode = (bm['code']?.toString() ?? '').toLowerCase();
            final target = _selectedBranchFilter.replaceAll('-', ' ').toLowerCase();
            if (bName.contains(target) || bCode == _selectedBranchFilter) {
              bAtt = bm['attendanceCounts']?['students'] as Map<String, dynamic>?;
              break;
            }
          }
        }
        if (bAtt != null) {
          total = (bAtt['roster'] as num?)?.toInt() ?? 0;
          present = (bAtt['present'] as num?)?.toInt() ?? 0;
          absent = (bAtt['absent'] as num?)?.toInt() ?? 0;
          leave = (bAtt['leave'] as num?)?.toInt() ?? 0;
          pending = (bAtt['notMarked'] as num?)?.toInt() ?? (total - present - absent - leave);
        }
      }

      if (_studentResidencyFilter == 'hostel-residents') {
        final hostelCount = (_dashboardData?['hostel']?['occupied'] as num?)?.toInt() ?? 12;
        if (_selectedBranchFilter == 'all') {
          total = hostelCount;
          present = 0;
          absent = 0;
          leave = 0;
          pending = total;
        } else {
          total = (total * 0.1).round().clamp(1, total);
          present = 0;
          absent = 0;
          leave = 0;
          pending = total;
        }
      } else if (_studentResidencyFilter == 'day-scholars') {
        final hostelCount = (_dashboardData?['hostel']?['occupied'] as num?)?.toInt() ?? 12;
        if (_selectedBranchFilter == 'all') {
          total = (total - hostelCount).clamp(0, total);
          pending = (total - present - absent - leave).clamp(0, total);
        } else {
          final hCount = (total * 0.1).round().clamp(1, total);
          total = (total - hCount).clamp(1, total);
          pending = (total - present - absent - leave).clamp(0, total);
        }
      }

      if (_selectedClassFilter != 'all') {
        const classProportions = {
          'Class 10': 0.35,
          'Class 9': 0.16,
          'Class 8': 0.10,
          'Class 7': 0.08,
          'Class 6': 0.10,
          'Class 5': 0.07,
          'Class 2': 0.08,
          'Class 1': 0.06,
        };
        final prop = classProportions[_selectedClassFilter] ?? 0.15;
        total = (total * prop).round().clamp(2, total);
        present = (present * prop).round().clamp(0, total);
        absent = (absent * prop).round().clamp(0, total);
        leave = 0;
        pending = (total - present - absent).clamp(0, total);
      }

      if (_selectedSectionFilter != 'all') {
        total = (total / 2).round().clamp(1, total);
        present = (present / 2).round().clamp(0, total);
        absent = (absent / 2).round().clamp(0, total);
        leave = 0;
        pending = (total - present - absent).clamp(0, total);
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
      int total = 0;
      int present = 0;
      int absent = 0;
      int leave = 0;
      int pending = 0;

      if (_selectedBranchFilter == 'all') {
        if (byBranch.isNotEmpty) {
          for (final bm in byBranch) {
            final st = bm['staff'] as Map<String, dynamic>?;
            if (st != null) {
              total += (st['roster'] as num?)?.toInt() ?? 0;
              present += (st['present'] as num?)?.toInt() ?? 0;
              absent += (st['absent'] as num?)?.toInt() ?? 0;
              leave += (st['leave'] as num?)?.toInt() ?? 0;
              pending += (st['notMarked'] as num?)?.toInt() ?? 0;
            }
          }
        }
        if (total == 0) {
          final staffOverall = attData?['staff'] as Map<String, dynamic>?;
          total = (staffOverall?['roster'] as num?)?.toInt() ??
              (_dashboardData?['group']?['staffFilled'] as num?)?.toInt() ??
              46;
          present = (staffOverall?['present'] as num?)?.toInt() ?? 0;
          absent = (staffOverall?['absent'] as num?)?.toInt() ?? 0;
          leave = (staffOverall?['leave'] as num?)?.toInt() ?? 0;
          pending = (staffOverall?['notMarked'] as num?)?.toInt() ?? (total - present - absent - leave);
        } else if (pending == 0 && (present + absent + leave) < total) {
          pending = total - present - absent - leave;
        }
      } else {
        Map<String, dynamic>? bAtt;
        for (final bm in byBranch) {
          final bSlug = (bm['branchSlug'] ?? _getBranchSlug(bm['branchName']?.toString() ?? '')).toString().toLowerCase();
          final bName = (bm['branchName']?.toString() ?? '').toLowerCase();
          final target = _selectedBranchFilter.replaceAll('-', ' ').toLowerCase();
          if (bSlug == _selectedBranchFilter || bName.contains(target)) {
            bAtt = bm['staff'] as Map<String, dynamic>?;
            break;
          }
        }
        if (bAtt == null) {
          for (final b in branches) {
            final bm = b as Map<String, dynamic>;
            final bName = (bm['name']?.toString() ?? '').toLowerCase();
            final bCode = (bm['code']?.toString() ?? '').toLowerCase();
            final target = _selectedBranchFilter.replaceAll('-', ' ').toLowerCase();
            if (bName.contains(target) || bCode == _selectedBranchFilter) {
              bAtt = bm['attendanceCounts']?['staff'] as Map<String, dynamic>?;
              break;
            }
          }
        }
        if (bAtt != null) {
          total = (bAtt['roster'] as num?)?.toInt() ?? 0;
          present = (bAtt['present'] as num?)?.toInt() ?? 0;
          absent = (bAtt['absent'] as num?)?.toInt() ?? 0;
          leave = (bAtt['leave'] as num?)?.toInt() ?? 0;
          pending = (bAtt['notMarked'] as num?)?.toInt() ?? (total - present - absent - leave);
        }
      }

      if (_staffRoleFilter == 'teaching') {
        final roleCounts = _getNonTeachingRolesCounts();
        final totalNt = roleCounts.values.fold(0, (a, b) => a + b);
        final teachersTotal = (46 - totalNt).clamp(0, 46); // 21
        if (_selectedBranchFilter == 'all') {
          total = teachersTotal;
          present = present.clamp(0, total);
          absent = absent.clamp(0, total);
          leave = leave.clamp(0, total);
          pending = total - present - absent - leave;
        } else {
          total = (total * 0.5).round().clamp(2, total);
          present = present.clamp(0, total);
          absent = absent.clamp(0, total);
          leave = leave.clamp(0, total);
          pending = total - present - absent - leave;
        }
      } else if (_staffRoleFilter == 'non-teaching') {
        final roleCounts = _getNonTeachingRolesCounts();
        final allNtTotal = roleCounts.values.fold(0, (a, b) => a + b); // 25

        if (_staffSubFilter != 'all-nt') {
          int subTotal = 0;
          for (final entry in roleCounts.entries) {
            if (_roleNameToSlug(entry.key) == _staffSubFilter) {
              subTotal += entry.value;
            }
          }
          total = subTotal > 0 ? subTotal : 1;
          present = 0;
          absent = 0;
          leave = 0;
          pending = total;
        } else {
          if (_selectedBranchFilter == 'all') {
            total = allNtTotal;
            present = 0;
            absent = 0;
            leave = 0;
            pending = total;
          } else {
            final branchNt = roleCounts.values.fold(0, (sum, count) => sum + count);
            total = branchNt > 0 ? branchNt : (total * 0.5).round().clamp(1, total);
            present = 0;
            absent = 0;
            leave = 0;
            pending = total;
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
    return _getAllStudentRecords().where((s) {
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
    return _getAllStaffRecords().where((st) {
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
      if (_staffRoleFilter == 'non-teaching' &&
          _staffSubFilter != 'all-nt' &&
          !_matchesStaffSubRole(st, _staffSubFilter)) {
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
                    if (_isAttendanceLoading)
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                        ),
                      )
                    else
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
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    isStudents
                        ? (isFiltered
                              ? '$branchName • $count enrolled students'
                              : '${(_dashboardData?['branches'] as List?)?.length ?? 6} branches • $count total enrolled students')
                        : (isFiltered
                              ? '$branchName • $count ${_getStaffScopeSubtitle()}'
                              : '${(_dashboardData?['branches'] as List?)?.length ?? 6} branches • $count total ${_getStaffScopeSubtitle()}'),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
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
                padding: const EdgeInsets.symmetric(vertical: 6.5),
                decoration: BoxDecoration(
                  color: isStudents
                      ? const Color(0xFF7C3AED)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isStudents
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF7C3AED,
                            ).withValues(alpha: 0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 15,
                      color: isStudents
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Students',
                      style: TextStyle(
                        color: isStudents
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isStudents
                            ? Colors.white.withValues(alpha: 0.22)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(_dashboardData?['attendance']?['students']?['roster'] ?? _dashboardData?['group']?['students'] ?? 122)}',
                        style: TextStyle(
                          color: isStudents
                              ? Colors.white
                              : const Color(0xFF475569),
                          fontSize: 9.5,
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
              behavior: HitTestBehavior.opaque,
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
                padding: const EdgeInsets.symmetric(vertical: 6.5),
                decoration: BoxDecoration(
                  color: !isStudents
                      ? const Color(0xFF7C3AED)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: !isStudents
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF7C3AED,
                            ).withValues(alpha: 0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.badge_rounded,
                      size: 15,
                      color: !isStudents
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Staff',
                      style: TextStyle(
                        color: !isStudents
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: !isStudents
                            ? Colors.white.withValues(alpha: 0.22)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '46',
                        style: TextStyle(
                          color: !isStudents
                              ? Colors.white
                              : const Color(0xFF475569),
                          fontSize: 9.5,
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
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
                    horizontal: 8,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: Color(0xFF7C3AED),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatDate(_selectedAttendanceDate),
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 3),
                      if (_isAttendanceLoading)
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                          ),
                        )
                      else
                        const Icon(
                          Icons.expand_more_rounded,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7C3AED),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isStudents ? 'Students View' : 'Staff View',
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // Sub-filters row (Residency vs Staff Role)
          if (isStudents) ...[
            const Text(
              'RESIDENCY SCOPE',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
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
                    '${(_dashboardData?['attendance']?['students']?['roster'] ?? _dashboardData?['group']?['students'] ?? 122)}',
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
                    '${((_dashboardData?['attendance']?['students']?['roster'] ?? 122) - 12)}',
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
                        ? 'All branches (${(_dashboardData?['branches'] as List?)?.length ?? 6})'
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
                    '${(_dashboardData?['attendance']?['staff']?['roster'] ?? _dashboardData?['group']?['staffFilled'] ?? 46)}',
                    _staffRoleFilter == 'all-staff',
                    () {
                      setState(() {
                        _staffRoleFilter = 'all-staff';
                        _staffSubFilter = 'all-nt';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (context) {
                      final roleCounts = _getNonTeachingRolesCounts();
                      final totalNt = roleCounts.values.fold(0, (a, b) => a + b);
                      final totalTeach = (46 - totalNt).clamp(0, 46);

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildScopePill(
                            'Teaching staff',
                            '$totalTeach',
                            _staffRoleFilter == 'teaching',
                            () {
                              setState(() {
                                _staffRoleFilter = 'teaching';
                                _staffSubFilter = 'all-nt';
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildScopePill(
                            'Non-teaching staff',
                            '$totalNt',
                            _staffRoleFilter == 'non-teaching',
                            () {
                              setState(() {
                                _staffRoleFilter = 'non-teaching';
                                _staffSubFilter = 'all-nt';
                              });
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            if (_staffRoleFilter == 'non-teaching') ...[
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
              Builder(
                builder: (context) {
                  final roleCounts = _getNonTeachingRolesCounts();
                  final totalNtCount = roleCounts.values.fold(0, (a, b) => a + b);

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildSubRolePill(
                          'All non-teaching',
                          '$totalNtCount',
                          _staffSubFilter == 'all-nt',
                          () {
                            setState(() => _staffSubFilter = 'all-nt');
                          },
                        ),
                        ...roleCounts.entries.map((entry) {
                          final slug = _roleNameToSlug(entry.key);
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _buildSubRolePill(
                              entry.key,
                              '${entry.value}',
                              _staffSubFilter == slug,
                              () {
                                setState(() => _staffSubFilter = slug);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
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
                        ? 'All branches (${(_dashboardData?['branches'] as List?)?.length ?? 6})'
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
        padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 4.5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF7C3AED) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
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
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.22)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF475569),
                  fontSize: 9.5,
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
        padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
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
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                  fontSize: 9.5,
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEDE9FE) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
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
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFF0F172A),
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 14,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFBEB), Colors.white],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.pending_actions_rounded,
                color: Color(0xFFB45309),
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
                      const Flexible(
                        child: Text(
                          'Daily Roll Audit Pending',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF78350F),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Awaiting Morning Sync',
                          style: TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$pendingCount students pending roll call submission $branchText',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
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
      final total = stats['total'];
      final branchText = _selectedBranchFilter == 'all'
          ? 'all campuses'
          : _getBranchLabel(_selectedBranchFilter);

      String bannerTitle = 'Staff Biometric Sync Complete';
      String bannerSubtitle =
          '$present present, $leave on leave, $absent absent across $branchText';

      if (_staffRoleFilter == 'teaching') {
        bannerTitle = 'Teaching Faculty Attendance Sync';
        bannerSubtitle = '$total teaching faculty rostered across $branchText';
      } else if (_staffRoleFilter == 'non-teaching') {
        if (_staffSubFilter == 'all-nt') {
          bannerTitle = 'Non-Teaching Staff Status';
          bannerSubtitle = '$total non-teaching staff rostered across $branchText';
        } else {
          final roleName = _slugToRoleName(_staffSubFilter);
          bannerTitle = '$roleName Status';
          bannerSubtitle = '$total ${roleName.toLowerCase()}s rostered across $branchText';
        }
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFECFDF5), Colors.white],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFA7F3D0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fingerprint_rounded,
                color: Color(0xFF047857),
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
                      Flexible(
                        child: Text(
                          bannerTitle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF064E3B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedShiftFilter == 'general'
                              ? '09:30 AM Shift'
                              : (_selectedShiftFilter == 'morning'
                                    ? '07:00 AM Shift'
                                    : '12:00 PM Shift'),
                          style: const TextStyle(
                            color: Color(0xFF065F46),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bannerSubtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
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
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Live Summary Strip',
                style: TextStyle(
                  color: Color(0xFF6D28D9),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Main White Summary Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
              // Top Row: Active Count + Attendance Block
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon Avatar
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Color(0xFF7C3AED),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),

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
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                activeBadge,
                                style: const TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Attendance % Pill Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
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
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              attendancePct,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFA7F3D0),
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            size: 11,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Middle Row: Distribution & Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Distribution',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    distributionNote,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // Distribution Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 4,
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
              const SizedBox(height: 10),

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
                  const SizedBox(width: 6),
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
                  const SizedBox(width: 6),
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
                  const SizedBox(width: 6),
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
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
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
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: isPending ? const Color(0xFF78350F) : textColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            pct,
            style: TextStyle(
              color: isPending
                  ? const Color(0xFF92400E)
                  : const Color(0xFF64748B),
              fontSize: 9,
              fontWeight: isPending ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- Attendance Component 6: "By Branch" Accordion Section ---
  Widget _buildAttendanceBranchSection(bool isStudents) {
    final rawBranches = _dashboardData?['branches'] as List<dynamic>? ?? [];
    final rawByBranch = _dashboardData?['attendance']?['byBranch'];
    final List<Map<String, dynamic>> byBranch = [];
    if (rawByBranch is List) {
      for (final item in rawByBranch) {
        if (item is Map<String, dynamic>) byBranch.add(item);
      }
    } else if (rawByBranch is Map) {
      rawByBranch.forEach((k, v) {
        if (v is Map) {
          byBranch.add({'branchCode': k, ...v.cast<String, dynamic>()});
        }
      });
    }

    final studentBranches = rawBranches.map((b) {
      final bm = b as Map<String, dynamic>;
      final name = bm['name']?.toString() ?? 'Branch';
      final lower = name.toLowerCase();
      final slug = lower.contains('steel')
          ? 'steel-plant'
          : lower.contains('gachi')
              ? 'gachibowli'
              : lower.contains('maddipalem')
                  ? 'maddipalem'
                  : lower.contains('kukat')
                      ? 'kukatpally'
                      : lower.contains('kondapur')
                          ? 'kondapur'
                          : 'madhapur';

      Map<String, dynamic>? att;
      for (final bbm in byBranch) {
        final bbmSlug = (bbm['branchSlug'] ?? _getBranchSlug(bbm['branchName']?.toString() ?? '')).toString().toLowerCase();
        final bbmName = (bbm['branchName']?.toString() ?? '').toLowerCase();
        if (bbm['branchId'] == bm['id'] ||
            bbmSlug == slug ||
            bbmName.contains(slug) ||
            slug.contains(bbmSlug)) {
          att = bbm['students'] as Map<String, dynamic>?;
          break;
        }
      }
      att ??= bm['attendanceCounts']?['students'] as Map<String, dynamic>?;

      final total = (att?['roster'] as num?)?.toInt() ?? (bm['students'] as num?)?.toInt() ?? 0;
      final present = (att?['present'] as num?)?.toInt() ?? 0;
      final absent = (att?['absent'] as num?)?.toInt() ?? 0;
      final leave = (att?['leave'] as num?)?.toInt() ?? 0;
      final pending = (att?['notMarked'] as num?)?.toInt() ?? (total - present - absent - leave);
      final pct = total > 0 ? '${((present / total) * 100).toStringAsFixed(0)}%' : '0%';

      final statusText = present > 0
          ? '$present Present • $absent Absent • $pending Not marked'
          : '$total Not marked';

      final sections = [
        {
          'name': 'Class 10 • Sec A',
          'count': '${(total * 0.55).round()} students',
          'status': present > 0 ? '$present Present' : 'Not marked',
        },
        if (absent > 0)
          {
            'name': 'Class 10 • Sec B',
            'count': '$absent students',
            'status': '$absent Absent',
          },
        {
          'name': 'Class 9 • Sec A',
          'count': '${(total * 0.45).round()} students',
          'status': 'Not marked',
        },
      ];

      return {
        'id': slug,
        'name': name,
        'total': total,
        'present': present,
        'absent': absent,
        'leave': leave,
        'pct': pct,
        'statusText': statusText,
        'sections': sections,
      };
    }).toList();

    final staffBranches = rawBranches.map((b) {
      final bm = b as Map<String, dynamic>;
      final name = bm['name']?.toString() ?? 'Branch';
      final lower = name.toLowerCase();
      final slug = _getBranchSlug(lower);

      Map<String, dynamic>? att;
      for (final bbm in byBranch) {
        final bbmSlug = (bbm['branchSlug'] ?? _getBranchSlug(bbm['branchName']?.toString() ?? '')).toString().toLowerCase();
        final bbmName = (bbm['branchName']?.toString() ?? '').toLowerCase();
        if (bbm['branchId'] == bm['id'] ||
            bbmSlug == slug ||
            bbmName.contains(slug) ||
            slug.contains(bbmSlug)) {
          att = bbm['staff'] as Map<String, dynamic>?;
          break;
        }
      }
      att ??= bm['attendanceCounts']?['staff'] as Map<String, dynamic>?;

      int total = (att?['roster'] as num?)?.toInt() ??
          (bm['staffTotal'] as num?)?.toInt() ??
          4;
      final present = (att?['present'] as num?)?.toInt() ?? 0;
      final absent = (att?['absent'] as num?)?.toInt() ?? 0;
      final leave = (att?['leave'] as num?)?.toInt() ?? 0;
      int pending = (att?['notMarked'] as num?)?.toInt() ??
          (total - present - absent - leave);
      double progress = total > 0 ? (present / total) : 0.0;
      String pct = '${(progress * 100).toStringAsFixed(1)}%';

      String statusText = absent > 0
          ? '$absent Absent • $pending Pending'
          : (present > 0
              ? '$present Present • $pending Pending'
              : '$pending Pending Biometric Log');

      final rawRoles = bm['roles'] as List<dynamic>? ?? [];
      List<Map<String, String>> sections = [];

      if (_staffRoleFilter == 'teaching') {
        final tCount = (bm['teachers'] as int? ?? 2);
        total = tCount;
        pending = tCount;
        progress = 0.0;
        pct = '0.0%';
        statusText = '$tCount Teaching faculty';
        sections = [
          {
            'name': 'Teaching Faculty',
            'count': '$tCount faculty',
            'status': 'Sanctioned',
          },
        ];
      } else if (_staffRoleFilter == 'non-teaching') {
        if (_staffSubFilter == 'all-nt') {
          final tCount = (bm['teachers'] as int? ?? 2);
          final ntCount = (total - tCount).clamp(0, total);
          total = ntCount;
          pending = ntCount;
          progress = 0.0;
          pct = '0.0%';
          statusText = '$ntCount Non-teaching staff';
          sections = rawRoles
              .where((r) =>
                  r is Map &&
                  !r['role'].toString().toLowerCase().contains('teacher') &&
                  !r['role'].toString().toLowerCase().contains('faculty'))
              .map((r) {
            final rm = r as Map<String, dynamic>;
            final roleName = rm['role']?.toString() ?? 'Staff';
            final filled = rm['filled'] ?? 1;
            final open = rm['open'] ?? 0;
            return {
              'name': roleName,
              'count': '$filled filled ${open > 0 ? "• $open open" : ""}',
              'status': 'Sanctioned',
            };
          }).toList();
        } else {
          // Specific sub-role selected
          int subFilled = 0;
          int subOpen = 0;
          final List<Map<String, String>> matchedSections = [];

          for (final r in rawRoles) {
            if (r is Map) {
              final rName = r['role']?.toString() ?? '';
              if (_roleNameToSlug(rName) == _staffSubFilter) {
                final filled = (r['filled'] as num?)?.toInt() ?? 0;
                final open = (r['open'] as num?)?.toInt() ?? 0;
                subFilled += filled;
                subOpen += open;
                matchedSections.add({
                  'name': rName,
                  'count': '$filled filled ${open > 0 ? "• $open open" : ""}',
                  'status': 'Sanctioned',
                });
              }
            }
          }

          total = subFilled;
          pending = subFilled;
          progress = 0.0;
          pct = '0.0%';
          statusText = subFilled > 0
              ? '$subFilled Filled ${subOpen > 0 ? "• $subOpen open" : ""}'
              : '0 Filled • 0 Open';
          sections = matchedSections.isNotEmpty
              ? matchedSections
              : [
                  {
                    'name': _slugToRoleName(_staffSubFilter),
                    'count': '0 filled • 0 open',
                    'status': 'Unassigned',
                  },
                ];
        }
      } else {
        sections = rawRoles.isNotEmpty
            ? rawRoles.map((r) {
                final rm = r as Map<String, dynamic>;
                final roleName = rm['role']?.toString() ?? 'Staff';
                final filled = rm['filled'] ?? 1;
                final open = rm['open'] ?? 0;
                return {
                  'name': roleName,
                  'count': '$filled filled ${open > 0 ? "• $open open" : ""}',
                  'status': 'Sanctioned',
                };
              }).toList()
            : [
                {
                  'name': 'Teaching Faculty',
                  'count': '${bm['teachers'] ?? 2} faculty',
                  'status': 'Sanctioned',
                },
                {
                  'name': 'Support Staff',
                  'count':
                      '${(total - (bm['teachers'] as int? ?? 2)).clamp(1, total)} staff',
                  'status': 'Sanctioned',
                },
              ];
      }

      return {
        'id': slug,
        'name': name,
        'total': total,
        'present': present,
        'absent': absent,
        'leave': leave,
        'pct': pct,
        'progress': progress,
        'statusText': statusText,
        'sections': sections,
      };
    }).toList();

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
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    size: 14,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'By Branch',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
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
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC4B5FD)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_getBranchLabel(_selectedBranchFilter)} ✕',
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 9.5,
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
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${branches.length} Branches active',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...branches.map((b) {
          final bId = b['id'] as String;
          final isExpanded = _expandedBranchIds.contains(bId);
          final sections = (b['sections'] as List<Map<String, String>>);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isExpanded
                    ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
                    : const Color(0xFFE2E8F0),
                width: isExpanded ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
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
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
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
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isStudents
                                          ? const Color(0xFF7C3AED)
                                          : const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      b['name'] as String,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isStudents
                                        ? const Color(0xFFFFFBEB)
                                        : const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
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
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Icon(
                                    Icons.expand_more_rounded,
                                    size: 16,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
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
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              b['pct'] as String,
                              style: TextStyle(
                                color: isStudents
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF059669),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: isStudents
                                ? 1.0
                                : (b['progress'] as double? ?? 0.0),
                            minHeight: 4,
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
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12),
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
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '${sections.length} ${isStudents ? 'Sections' : 'Depts'}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...sections.map((s) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
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
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${s['count']} • ',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 9.5,
                                      ),
                                    ),
                                    Text(
                                      s['status']!,
                                      style: TextStyle(
                                        color: isStudents
                                            ? const Color(0xFF92400E)
                                            : const Color(0xFF7C3AED),
                                        fontSize: 9.5,
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

    final displayedStudents = _showAllAttendanceStudents
        ? filteredStudents
        : filteredStudents.take(5).toList();

    final displayedStaff = _showAllAttendanceStaff
        ? filteredStaff
        : filteredStaff.take(5).toList();

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
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    isStudents ? Icons.group_rounded : Icons.badge_rounded,
                    size: 14,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isStudents ? 'Student Roster' : 'Staff Directory',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: isStudents
                    ? const Color(0xFFFFFBEB)
                    : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isStudents
                      ? const Color(0xFFFDE68A)
                      : const Color(0xFFA7F3D0),
                ),
              ),
              child: Text(
                isStudents
                    ? 'Showing ${displayedStudents.length} of ${filteredStudents.length} Students'
                    : 'Showing ${displayedStaff.length} of ${filteredStaff.length} Staff',
                style: TextStyle(
                  color: isStudents
                      ? const Color(0xFF92400E)
                      : const Color(0xFF047857),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Search Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _attendanceSearchQuery = val;
                    });
                  },
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: isStudents
                        ? 'Search student name, roll number, or section...'
                        : 'Search staff name, employee ID, role...',
                    hintStyle: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 7),
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
                    size: 15,
                    color: Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

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
                    const SizedBox(width: 5),
                    _buildRosterFilterPill(
                      'All ($totalInScope)',
                      _rosterFilterPill == 'all',
                      () {
                        setState(() => _rosterFilterPill = 'all');
                      },
                    ),
                    const SizedBox(width: 5),
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
                    const SizedBox(width: 5),
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
                    if (_staffRoleFilter == 'all-staff') ...[
                      const SizedBox(width: 5),
                      Builder(
                        builder: (context) {
                          int dynamicTeachingCount = 0;
                          int dynamicNonTeachingCount = 0;
                          final brList = _dashboardData?['branches'] as List<dynamic>? ?? [];
                          for (final b in brList) {
                            if (b is! Map<String, dynamic>) continue;
                            final bSlug = _getBranchSlug(b['name']?.toString() ?? '');
                            if (_selectedBranchFilter != 'all' && bSlug != _selectedBranchFilter) continue;
                            dynamicTeachingCount += ((b['teachers'] ?? b['staffTeach'] ?? 0) as num).toInt();
                            dynamicNonTeachingCount += ((b['staffNon'] ?? 0) as num).toInt();
                          }
                          if (dynamicTeachingCount == 0) {
                            dynamicTeachingCount = (_dashboardData?['group']?['teachers'] as num?)?.toInt() ?? 19;
                          }
                          if (dynamicNonTeachingCount == 0) {
                            dynamicNonTeachingCount = (totalInScope - dynamicTeachingCount).clamp(0, totalInScope);
                          }

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildRosterFilterPill(
                                'Teaching ($dynamicTeachingCount)',
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
                              const SizedBox(width: 5),
                              _buildRosterFilterPill(
                                'Non-Teaching ($dynamicNonTeachingCount)',
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
                            ],
                          );
                        },
                      ),
                    ],
                    const SizedBox(width: 5),
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
                    const SizedBox(width: 5),
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
                    const SizedBox(width: 5),
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
        const SizedBox(height: 8),

        // Empty state check
        if ((isStudents && filteredStudents.isEmpty) ||
            (!isStudents && filteredStaff.isEmpty)) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.filter_alt_off_rounded,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No matching records found',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Try relaxing your search query or dropdown filter criteria.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _resetAttendanceFilters(isStudents),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 13,
                          color: Color(0xFF7C3AED),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Reset All Filters',
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 10.5,
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
          ...displayedStudents.map((s) {
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
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
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
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      s['rollNo'] as String,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                s['meta'] as String,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 9.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusBorder),
                    ),
                    child: Text(
                      s['status'] as String,
                      style: TextStyle(
                        color: statusText,
                        fontSize: 8.5,
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
          ...displayedStaff.map((st) {
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
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                              width: 28,
                              height: 28,
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
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    st['name'] as String,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    '${st['role']} • ${st['branchName']}',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 9.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: tagBorder),
                        ),
                        child: Text(
                          st['status'] as String,
                          style: TextStyle(
                            color: tagText,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        st['subStatus'] as String? ?? 'General Shift',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9.5,
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
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.call_rounded,
                                    size: 11,
                                    color: Color(0xFF7C3AED),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Call',
                                    style: TextStyle(
                                      color: Color(0xFF7C3AED),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
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
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 11,
                                    color: Color(0xFF7C3AED),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Message',
                                    style: TextStyle(
                                      color: Color(0xFF7C3AED),
                                      fontSize: 9.5,
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

        // Load All / Show Remaining Toggle Button
        if (isStudents && filteredStudents.length > 5) ...[
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _showAllAttendanceStudents = !_showAllAttendanceStudents;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showAllAttendanceStudents
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 15,
                    color: const Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showAllAttendanceStudents
                        ? 'Showing all ${filteredStudents.length} students (tap to collapse)'
                        : 'Showing ${displayedStudents.length} of ${filteredStudents.length} students (tap to show all ${filteredStudents.length})',
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else if (!isStudents && filteredStaff.length > 5) ...[
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _showAllAttendanceStaff = !_showAllAttendanceStaff;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showAllAttendanceStaff
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 15,
                    color: const Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showAllAttendanceStaff
                        ? 'Showing all ${filteredStaff.length} staff members (tap to collapse)'
                        : 'Showing ${displayedStaff.length} of ${filteredStaff.length} staff members (tap to show all ${filteredStaff.length})',
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF475569),
            fontSize: 9.5,
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

  // ============================================================================
  // --- USERS DIRECTORY VIEW (Matching Web Design with Dashboard / Attendance UI/UX) ---
  // ============================================================================
  Widget _buildUsersView() {
    final allUsers = UsersDirectoryData.users;

    // Active counts based on current branch selection
    final totalUsersCount = allUsers.where((u) => _usersBranchFilter == 'all' || u.branchId == _usersBranchFilter).length;
    final studentsCount = allUsers.where((u) => u.role == 'students' && (_usersBranchFilter == 'all' || u.branchId == _usersBranchFilter)).length;
    final teachingCount = allUsers.where((u) => u.role == 'teaching' && (_usersBranchFilter == 'all' || u.branchId == _usersBranchFilter)).length;
    final nonTeachingCount = allUsers.where((u) => u.role == 'non-teaching' && (_usersBranchFilter == 'all' || u.branchId == _usersBranchFilter)).length;
    final adminsCount = allUsers.where((u) => u.role == 'admins' && (_usersBranchFilter == 'all' || u.branchId == _usersBranchFilter)).length;
    final principalsCount = allUsers.where((u) => u.role == 'principals' && (_usersBranchFilter == 'all' || u.branchId == _usersBranchFilter)).length;
    final parentsCount = allUsers.where((u) => u.role == 'parents' && (_usersBranchFilter == 'all' || u.branchId == _usersBranchFilter)).length;

    // Count strictly for role + branch (matching web banner behavior)
    final roleAndBranchCount = allUsers.where((u) {
      final matchRole = _usersRoleFilter == 'all' || u.role == _usersRoleFilter;
      final matchBranch = _usersBranchFilter == 'all' || u.branchId == _usersBranchFilter;
      return matchRole && matchBranch;
    }).length;

    // Filtered user list (incorporating search)
    final filteredUsers = allUsers.where((u) {
      if (_usersRoleFilter != 'all' && u.role != _usersRoleFilter) {
        return false;
      }
      if (_usersBranchFilter != 'all' && u.branchId != _usersBranchFilter) {
        return false;
      }
      if (_usersSearchQuery.isNotEmpty) {
        final q = _usersSearchQuery.toLowerCase();
        final nameMatches = u.name.toLowerCase().contains(q);
        final metaMatches = u.meta.toLowerCase().contains(q);
        final branchMatches = u.branchName.toLowerCase().contains(q);
        final roleMatches = u.roleLabel.toLowerCase().contains(q);
        if (!nameMatches && !metaMatches && !branchMatches && !roleMatches) {
          return false;
        }
      }
      return true;
    }).toList();

    final displayedUsers = _showAllUsers
        ? filteredUsers
        : filteredUsers.take(10).toList();

    // Active role label for banner
    String roleLabel = 'All users';
    switch (_usersRoleFilter) {
      case 'students':
        roleLabel = 'Students';
        break;
      case 'teaching':
        roleLabel = 'Teaching staff';
        break;
      case 'non-teaching':
        roleLabel = 'Non-teaching staff';
        break;
      case 'admins':
        roleLabel = 'Admins';
        break;
      case 'principals':
        roleLabel = 'Principals';
        break;
      case 'parents':
        roleLabel = 'Parents / guardians';
        break;
    }

    // Active branch label for banner
    String branchLabel = 'All branches';
    if (_usersBranchFilter != 'all') {
      branchLabel = _getBranchLabel(_usersBranchFilter);
    }

    // Branch breakdown data
    final branchConfigs = [
      {'slug': 'steel-plant', 'name': 'Steel Plant Branch'},
      {'slug': 'gachibowli', 'name': 'Gachibowli Campus'},
      {'slug': 'maddipalem', 'name': 'Maddipalem'},
      {'slug': 'kukatpally', 'name': 'Kukatpally Campus'},
      {'slug': 'kondapur', 'name': 'Kondapur Branch'},
      {'slug': 'madhapur', 'name': 'Madhapur Branch'},
    ];

    int maxBranchCount = 1;
    final List<Map<String, dynamic>> branchBreakdown = branchConfigs.map((b) {
      final slug = b['slug']!;
      final name = b['name']!;
      final count = allUsers.where((u) {
        final matchBranch = u.branchId == slug;
        final matchRole = _usersRoleFilter == 'all' || u.role == _usersRoleFilter;
        return matchBranch && matchRole;
      }).length;
      if (count > maxBranchCount) maxBranchCount = count;
      return {
        'slug': slug,
        'name': name,
        'count': count,
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Context & Title
        _buildUsersHeaderContext(),
        const SizedBox(height: 14),

        // 2. Role Filter Pills (Horizontal Scrolling)
        _buildUsersRoleFilterPills(
          totalUsersCount,
          studentsCount,
          teachingCount,
          nonTeachingCount,
          adminsCount,
          principalsCount,
          parentsCount,
        ),
        const SizedBox(height: 14),

        // 3. Branch Filter Dropdown / Selector
        _buildUsersBranchFilterDropdown(),
        const SizedBox(height: 14),

        // 4. Summary Banner Strip (Matching Web Purple Banner)
        _buildUsersSummaryBanner(roleAndBranchCount, roleLabel, branchLabel),
        const SizedBox(height: 16),

        // 5. "BY BRANCH" Breakdown Card
        _buildUsersByBranchCard(branchBreakdown, maxBranchCount),
        const SizedBox(height: 20),

        // 6. User Directory / Search & Roster Section
        _buildUsersDirectoryListCard(filteredUsers, displayedUsers),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- Users Component 1: Header Context ---
  Widget _buildUsersHeaderContext() {
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
                  'DIRECTORY SUITE',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Users directory',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Filter by role, branch, class & section · counts update instantly',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- Users Component 2: Role Filter Pills ---
  Widget _buildUsersRoleFilterPills(
    int totalCount,
    int studentsCount,
    int teachingCount,
    int nonTeachingCount,
    int adminsCount,
    int principalsCount,
    int parentsCount,
  ) {
    final pills = [
      {'id': 'all', 'label': 'All users $totalCount'},
      {'id': 'students', 'label': 'Students $studentsCount'},
      {'id': 'teaching', 'label': 'Teaching staff $teachingCount'},
      {'id': 'non-teaching', 'label': 'Non-teaching staff $nonTeachingCount'},
      {'id': 'admins', 'label': 'Admins $adminsCount'},
      {'id': 'principals', 'label': 'Principals $principalsCount'},
      {'id': 'parents', 'label': 'Parents / guardians $parentsCount'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: pills.map((p) {
          final isSelected = _usersRoleFilter == p['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _usersRoleFilter = p['id']!;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
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
                            ).withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  p['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Users Component 3: Branch Filter Dropdown ---
  Widget _buildUsersBranchFilterDropdown() {
    final branchName = _usersBranchFilter == 'all'
        ? 'All branches'
        : _getBranchLabel(_usersBranchFilter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BRANCH',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            final branchOptions = [
              {'id': 'all', 'label': 'All branches'},
              {'id': 'steel-plant', 'label': 'Steel Plant Branch'},
              {'id': 'gachibowli', 'label': 'Gachibowli Campus'},
              {'id': 'maddipalem', 'label': 'Maddipalem'},
              {'id': 'kukatpally', 'label': 'Kukatpally Campus'},
              {'id': 'kondapur', 'label': 'Kondapur Branch'},
              {'id': 'madhapur', 'label': 'Madhapur Branch'},
            ];
            _showFilterPicker(
              title: 'Select Campus Branch',
              options: branchOptions,
              selectedValue: _usersBranchFilter,
              onSelected: (val) {
                setState(() {
                  _usersBranchFilter = val;
                });
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.apartment_rounded,
                      size: 14,
                      color: Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      branchName,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Users Component 4: Summary Banner Strip ---
  Widget _buildUsersSummaryBanner(
    int count,
    String roleLabel,
    String branchLabel,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF1E1B4B),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$roleLabel · $branchLabel',
            style: const TextStyle(
              color: Color(0xFF6D28D9),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // --- Users Component 5: "BY BRANCH" Breakdown Card ---
  Widget _buildUsersByBranchCard(
    List<Map<String, dynamic>> branchBreakdown,
    int maxBranchCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'BY BRANCH',
                style: TextStyle(
                  color: Color(0xFF1E1B4B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                'COUNT',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          ...branchBreakdown.map((b) {
            final slug = b['slug'] as String;
            final name = b['name'] as String;
            final count = b['count'] as int;
            final isSelected = _usersBranchFilter == slug;
            final double ratio = maxBranchCount > 0
                ? (count / maxBranchCount).clamp(0.0, 1.0)
                : 0.0;

            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _usersBranchFilter = isSelected ? 'all' : slug;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 7,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEDE9FE).withValues(alpha: 0.5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF0F172A),
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$count',
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF0F172A),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 5,
                        width: double.infinity,
                        color: const Color(0xFFF1F5F9),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: ratio,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF6D28D9)
                                  : const Color(0xFF7C3AED),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- Users Component 6: User Directory List Card ---
  Widget _buildUsersDirectoryListCard(
    List<UserDirectoryItem> filteredUsers,
    List<UserDirectoryItem> displayedUsers,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      size: 14,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'User Directory',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  'Showing ${displayedUsers.length} of ${filteredUsers.length} Users',
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _usersSearchController,
                    onChanged: (val) {
                      setState(() {
                        _usersSearchQuery = val;
                      });
                    },
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search all users by name...',
                      hintStyle: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                if (_usersSearchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _usersSearchController.clear();
                      setState(() {
                        _usersSearchQuery = '';
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Icon(
                        Icons.clear_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Users List
          if (filteredUsers.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  Icon(
                    Icons.search_off_rounded,
                    size: 36,
                    color: Color(0xFFCBD5E1),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No users found matching current filters',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ...displayedUsers.map((user) => _buildUserCardItem(user)),
            const SizedBox(height: 10),

            // Expand/Collapse Button
            if (filteredUsers.length > 10)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _showAllUsers = !_showAllUsers;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showAllUsers
                              ? 'Showing all ${filteredUsers.length} users (tap to collapse)'
                              : 'Showing 10 of ${filteredUsers.length} users (tap to show all)',
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showAllUsers
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: const Color(0xFF7C3AED),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // --- Users Component 7: User Card Item ---
  Widget _buildUserCardItem(UserDirectoryItem user) {
    Color avatarBg;
    Color avatarTextColor;
    Color roleBadgeBg;
    Color roleBadgeTextColor;

    switch (user.role) {
      case 'students':
        avatarBg = const Color(0xFFEFF6FF);
        avatarTextColor = const Color(0xFF2563EB);
        roleBadgeBg = const Color(0xFFDBEAFE);
        roleBadgeTextColor = const Color(0xFF1D4ED8);
        break;
      case 'teaching':
        avatarBg = const Color(0xFFF3E8FF);
        avatarTextColor = const Color(0xFF7C3AED);
        roleBadgeBg = const Color(0xFFEDE9FE);
        roleBadgeTextColor = const Color(0xFF6D28D9);
        break;
      case 'non-teaching':
        avatarBg = const Color(0xFFFFFBEB);
        avatarTextColor = const Color(0xFFD97706);
        roleBadgeBg = const Color(0xFFFEF3C7);
        roleBadgeTextColor = const Color(0xFFB45309);
        break;
      case 'admins':
        avatarBg = const Color(0xFFFFE4E6);
        avatarTextColor = const Color(0xFFE11D48);
        roleBadgeBg = const Color(0xFFFFE4E6);
        roleBadgeTextColor = const Color(0xFFBE123C);
        break;
      case 'principals':
        avatarBg = const Color(0xFFEEF2FF);
        avatarTextColor = const Color(0xFF4F46E5);
        roleBadgeBg = const Color(0xFFE0E7FF);
        roleBadgeTextColor = const Color(0xFF4338CA);
        break;
      case 'parents':
      default:
        avatarBg = const Color(0xFFECFDF5);
        avatarTextColor = const Color(0xFF059669);
        roleBadgeBg = const Color(0xFFD1FAE5);
        roleBadgeTextColor = const Color(0xFF047857);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Initials Avatar
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: avatarBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.initials,
                style: TextStyle(
                  color: avatarTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
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
                        color: roleBadgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.roleLabel,
                        style: TextStyle(
                          color: roleBadgeTextColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.meta,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
  final double ebitdaMargin;
  final double collectionPct;

  const CashTrajectoryPainter({
    this.ebitdaMargin = 35.9,
    this.collectionPct = 68.2,
  });

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

    // OpEx Dashed Curve - scaled according to EBITDA Margin
    final opexRatio = (1.0 - (ebitdaMargin / 100.0)).clamp(0.40, 0.85);
    final opexPoints = [
      Offset(0, h * (0.65 + (opexRatio * 0.25))),
      Offset(w * 0.17, h * (0.50 + (opexRatio * 0.30))),
      Offset(w * 0.34, h * (0.42 + (opexRatio * 0.30))),
      Offset(w * 0.51, h * (0.35 + (opexRatio * 0.30))),
      Offset(w * 0.68, h * (0.28 + (opexRatio * 0.30))),
      Offset(w * 0.85, h * (0.22 + (opexRatio * 0.30))),
      Offset(w, h * (0.18 + (opexRatio * 0.30))),
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
  bool shouldRepaint(covariant CashTrajectoryPainter oldDelegate) =>
      oldDelegate.ebitdaMargin != ebitdaMargin || oldDelegate.collectionPct != collectionPct;
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
  final List<Map<String, dynamic>> branches;
  final double avgCollection;
  final double avgAttendance;

  const PerformanceQuadrantPainter({
    this.branches = const [],
    this.avgCollection = 68.2,
    this.avgAttendance = 92.1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final dashPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final crossX = ((avgCollection - 40.0) / 60.0).clamp(0.15, 0.85) * w;
    final crossY = h - (((avgAttendance - 80.0) / 20.0).clamp(0.15, 0.85) * h);

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

    drawText('avg collection ${avgCollection.toStringAsFixed(0)}%', Offset(crossX + 4, 8));
    drawText('avg attendance ${avgAttendance.toStringAsFixed(0)}%', Offset(crossX + 4, (crossY - 14).clamp(16.0, h - 20.0)));
    drawText(
      '▼ NEEDS ATTENTION',
      Offset(12, h - 16),
      color: const Color(0xFF64748B),
      weight: FontWeight.w700,
    );

    // Draw branch bubbles dynamically from live data
    if (branches.isNotEmpty) {
      for (final b in branches) {
        final double colPct = (b['collectionPct'] as num?)?.toDouble() ?? 68.0;
        final double attPct = (b['attendancePct'] as num?)?.toDouble() ?? 92.0;
        final int students = (b['students'] as num?)?.toInt() ?? 15;
        final Color col = b['color'] as Color? ?? const Color(0xFF7C3AED);

        final bx = ((colPct - 40.0) / 60.0).clamp(0.08, 0.92) * w;
        final by = h - (((attPct - 80.0) / 20.0).clamp(0.08, 0.92) * h);
        final br = (6.0 + ((students / 50.0).clamp(0.0, 1.0) * 10.0));

        final bubbleFill = Paint()
          ..color = col.withValues(alpha: 0.70)
          ..style = PaintingStyle.fill;
        final bubbleStroke = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawCircle(Offset(bx, by), br, bubbleFill);
        canvas.drawCircle(Offset(bx, by), br, bubbleStroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PerformanceQuadrantPainter oldDelegate) => true;
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
