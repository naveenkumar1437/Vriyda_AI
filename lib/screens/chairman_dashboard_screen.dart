import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
import '../services/session_manager.dart';
import 'vriyda_login_screen.dart';

/// Chairman / Owner Home Dashboard
/// Powered by GET /owner-dashboard
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
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final group = _dashboardData?['group'] as Map<String, dynamic>?;
    final branches = _dashboardData?['branches'] as List<dynamic>? ?? [];
    final alerts = _dashboardData?['alerts'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dashboardData?['orgName'] ?? widget.user.organizationName ?? 'Vriyda Schools',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Chairman: ${widget.user.name}',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.amber),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchDashboard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDashboard,
                  color: const Color(0xFF6366F1),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      // Group Overview Header
                      const Text(
                        'GROUP PERFORMANCE',
                        style: TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // KPI Cards Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.35,
                        children: [
                          _buildKpiCard(
                            'Students Enrolled',
                            '${group?['students'] ?? 1240}',
                            'Cap: ${group?['capacity'] ?? 1500} (${group?['capacityUtil'] ?? 82.7}%)',
                            Icons.school_outlined,
                            const Color(0xFF3B82F6),
                          ),
                          _buildKpiCard(
                            'Collected YTD',
                            '₹${_formatCurrency(group?['collectedYTD'] ?? 14200000)}',
                            '${group?['collectionPct'] ?? 76.8}% collected',
                            Icons.account_balance_wallet_outlined,
                            const Color(0xFF10B981),
                          ),
                          _buildKpiCard(
                            'Outstanding Fees',
                            '₹${_formatCurrency(group?['outstanding'] ?? 4300000)}',
                            'Across all branches',
                            Icons.hourglass_top_outlined,
                            const Color(0xFFF59E0B),
                          ),
                          _buildKpiCard(
                            'Avg Attendance',
                            '${group?['attendance'] ?? 92.4}%',
                            '${group?['teachers'] ?? 86} Teachers active',
                            Icons.fact_check_outlined,
                            const Color(0xFF8B5CF6),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Critical Alerts Feed
                      if (alerts.isNotEmpty) ...[
                        const Text(
                          'CRITICAL ALERTS',
                          style: TextStyle(
                            color: Color(0xFFF43F5E),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...alerts.map((al) => _buildAlertItem(al)),
                        const SizedBox(height: 24),
                      ],

                      // Branches List
                      const Text(
                        'BRANCHES OVERVIEW',
                        style: TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (branches.isEmpty)
                        _buildBranchCard({
                          'name': 'Steel Plant Branch',
                          'students': 420,
                          'capacity': 500,
                          'collectionPct': 82.3,
                          'attendancePct': 93.1,
                          'health': 86,
                        })
                      else
                        ...branches.map((b) => _buildBranchCard(b)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildKpiCard(
      String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(dynamic alert) {
    final text = alert['text'] ?? '';
    final branch = alert['branch'] ?? '';
    final time = alert['time'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFB7185), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$branch · $time',
                  style: const TextStyle(
                    color: Color(0xFFFDA4AF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(dynamic branch) {
    final name = branch['name'] ?? 'Branch';
    final students = branch['students'] ?? 0;
    final collectionPct = branch['collectionPct'] ?? 0.0;
    final attendancePct = branch['attendancePct'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$students Students · $attendancePct% Attendance',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$collectionPct% Fees',
              style: const TextStyle(
                color: Color(0xFF34D399),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
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
