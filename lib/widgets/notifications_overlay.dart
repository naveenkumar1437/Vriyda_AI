import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/approval_service.dart';

/// Item model for key-value row in Branch details popup
class _BranchMetricRow {
  final String label;
  final String value;
  const _BranchMetricRow(this.label, this.value);
}

/// 1. Notifications Dropdown Sheet (Screenshot 1)
class NotificationsDropdownSheet extends StatelessWidget {
  final List<dynamic> alerts;
  final List<dynamic> approvals;
  final List<dynamic> branches;
  final Function(Map<String, dynamic> alert) onAlertTap;
  final Function(Map<String, dynamic> approval) onApprovalTap;
  final VoidCallback? onClose;

  const NotificationsDropdownSheet({
    super.key,
    required this.alerts,
    required this.approvals,
    required this.branches,
    required this.onAlertTap,
    required this.onApprovalTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final alertItems = _normalizeAlerts(alerts);
    final approvalItems = _normalizeApprovals(approvals);
    final totalCount = alertItems.length + approvalItems.length;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.90,
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 620),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Notifications & '14 need your attention')
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 14, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                '$totalCount need your attention',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (onClose != null) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: onClose,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECTION 1: CRITICAL ALERTS
                        const Text(
                          'CRITICAL ALERTS',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (alertItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'No critical alerts',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          ...alertItems.map((al) {
                            return _buildAlertRow(context, al);
                          }),

                        const SizedBox(height: 18),

                        // SECTION 2: APPROVALS WAITING
                        const Text(
                          'APPROVALS WAITING',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (approvalItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'No pending approvals',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          ...approvalItems.map((ap) {
                            return _buildApprovalRow(context, ap);
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertRow(BuildContext context, Map<String, dynamic> al) {
    final type = al['type']?.toString() ?? al['title']?.toString() ?? 'Alert';
    final branch = al['branch']?.toString() ?? al['campus']?.toString() ?? '';
    final time = al['time']?.toString() ?? '';
    final metaText = [branch, time].where((s) => s.isNotEmpty).join(' · ');

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onAlertTap(al);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.5, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: type,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (metaText.isNotEmpty)
                      TextSpan(
                        text: ' $metaText',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
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

  Widget _buildApprovalRow(BuildContext context, Map<String, dynamic> ap) {
    final type = ap['type']?.toString() ?? ap['title']?.toString() ?? 'Approval';
    final branch = ap['branch']?.toString() ?? ap['campus']?.toString() ?? '';
    final age = ap['age']?.toString() ?? ap['time']?.toString() ?? '';
    final amount = ap['amount']?.toString() ?? '';
    final metaText = [branch, age].where((s) => s.isNotEmpty).join(' · ');

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onApprovalTap(ap);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.5, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF7C3AED),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: type,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (metaText.isNotEmpty)
                      TextSpan(
                        text: ' $metaText waiting',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amount.isNotEmpty ? amount : 'Review',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _normalizeAlerts(List<dynamic> raw) {
    if (raw.isNotEmpty) {
      return raw.take(4).map((al) {
        final m = Map<String, dynamic>.from(al as Map);
        final rawType = m['type']?.toString() ?? 'Alert';
        final capitalizedType = rawType.isNotEmpty
            ? '${rawType[0].toUpperCase()}${rawType.substring(1).toLowerCase()}'
            : 'Alert';
        return {
          'id': m['id']?.toString() ?? 'alt-${m['branch']}',
          'type': capitalizedType,
          'branch': m['branch']?.toString() ?? '',
          'time': m['time']?.toString() ?? '',
          'level': m['level']?.toString() ?? 'critical',
          'raw': m,
        };
      }).toList();
    }
    return const [];
  }

  List<Map<String, dynamic>> _normalizeApprovals(List<dynamic> raw) {
    if (raw.isNotEmpty) {
      final pendingOnly = raw.where((ap) {
        if (ap is Map) {
          final status = (ap['status']?.toString() ?? 'pending').toLowerCase();
          return status == 'pending';
        }
        return true;
      }).toList();
      return pendingOnly.take(5).map((ap) {
        final m = Map<String, dynamic>.from(ap as Map);
        final rawType = m['type']?.toString() ?? 'Approval';
        final type = rawType.replaceAll('_', ' ').split(' ').map((w) {
          return w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '';
        }).join(' ');

        final num? amt = m['amount'] as num?;
        String amtStr = '';
        if (amt != null && amt > 0) {
          if (amt >= 100000) {
            amtStr = '₹${(amt / 100000).toStringAsFixed(1)} L';
          } else {
            final s = amt.toInt().toString();
            final formatted = s.replaceAllMapped(
              RegExp(r'(\d+?)(?=(\d{3})+(?!\d))'),
              (match) => '${match[1]},',
            );
            amtStr = '₹$formatted';
          }
        } else {
          amtStr = 'Review';
        }
        if (type.toLowerCase().contains('hiring')) {
          amtStr = 'Review';
        }
        final branch = m['branch']?.toString() ?? '';
        final age = m['age']?.toString() ?? '';
        final title = m['title']?.toString() ?? m['text']?.toString() ?? type;
        return {
          'id': m['id']?.toString() ?? 'apr-${m['branch']}',
          'type': type.isNotEmpty ? type : 'Approval',
          'title': title,
          'branch': branch,
          'age': age,
          'amount': amtStr,
          'raw': m,
        };
      }).toList();
    }
    return const [];
  }
}

/// 2. Notification Details Popup (Branch Detail Metrics Dialog - Screenshot 2)
class BranchNotificationDetailsDialog extends StatelessWidget {
  final String branchName;
  final String status;
  final Map<String, dynamic>? branchData;
  final VoidCallback? onClose;

  const BranchNotificationDetailsDialog({
    super.key,
    required this.branchName,
    this.status = 'STABLE',
    this.branchData,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final rows = _buildMetricRows(branchData);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 680),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                branchName,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onClose ?? () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // Table Rows
                Flexible(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final item = rows[index];
                      final isIndent = item.label.startsWith('·');

                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          isIndent ? 28 : 16,
                          9.5,
                          16,
                          9.5,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.label,
                              style: TextStyle(
                                color: const Color(0xFF64748B),
                                fontSize: 12.5,
                                fontWeight: isIndent
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                item.value,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_BranchMetricRow> _buildMetricRows(Map<String, dynamic>? data) {
    final students = data?['students']?.toString() ?? '—';
    final capacity = data?['capacity']?.toString() ?? '—';
    final capFill = capacity != '—' ? '$students / $capacity' : 'No classroom seats recorded';

    final rev = data?['revenue'] != null
        ? '₹${((data!['revenue'] as num) / 100000).toStringAsFixed(1)} L'
        : '—';
    final collected = data?['collected'] != null
        ? '₹${((data!['collected'] as num) / 100000).toStringAsFixed(1)} L'
        : '—';
    final due = data?['outstanding'] != null
        ? '₹${((data!['outstanding'] as num) / 100000).toStringAsFixed(1)} L'
        : '—';
    final collectionPct = data?['collectionPct'] != null
        ? '${data!['collectionPct']}%'
        : '—';
    final attPct = data?['attendancePct'] != null
        ? '${data!['attendancePct']}%'
        : '—';
    final examIndex = data?['examIndex']?.toString() ?? '—';
    final teachers = data?['teachers']?.toString() ?? '—';
    final vacancies = data?['vacancies']?.toString() ?? '—';
    final vehicles = data?['vehicles']?.toString() ?? '—';

    return [
      _BranchMetricRow('Students', students),
      _BranchMetricRow('Capacity / fill', capFill),
      _BranchMetricRow('Revenue (billed)', rev),
      _BranchMetricRow('Collected', collected),
      _BranchMetricRow('Due', due),
      _BranchMetricRow('Collection', collectionPct),
      _BranchMetricRow('Student attendance', 'not marked · $students on roll'),
      const _BranchMetricRow('Staff attendance', 'not marked'),
      _BranchMetricRow('Attendance rate', attPct),
      _BranchMetricRow('Exam index', examIndex),
      _BranchMetricRow('Teachers', teachers),
      _BranchMetricRow('Open vacancies', vacancies),
      _BranchMetricRow('· Teacher', vacancies != '—' ? '$vacancies open' : '—'),
      _BranchMetricRow('Fleet vehicles', vehicles),
    ];
  }
}

/// 3. Approval Decision Dialog (Screenshot 3)
class ApprovalDecisionDialog extends StatefulWidget {
  final Map<String, dynamic> approvalItem;
  final Function(String decision, String note)? onDecision;
  final VoidCallback? onClose;

  const ApprovalDecisionDialog({
    super.key,
    required this.approvalItem,
    this.onDecision,
    this.onClose,
  });

  @override
  State<ApprovalDecisionDialog> createState() => _ApprovalDecisionDialogState();
}

class _ApprovalDecisionDialogState extends State<ApprovalDecisionDialog> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleDecision(String decision) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final item = widget.approvalItem;
    final id = item['id']?.toString() ?? '';
    final branch = item['branch']?.toString() ?? '';
    final type = item['type']?.toString() ?? '';
    final note = _noteController.text.trim();

    // Call service
    await ApprovalService.decideApproval(
      id: id,
      branch: branch,
      type: type,
      decision: decision,
      note: note,
    );

    if (mounted) {
      widget.onDecision?.call(decision, note);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decision == 'approved'
                ? '${item['type'] ?? 'Item'} approved successfully'
                : '${item['type'] ?? 'Item'} rejected',
          ),
          backgroundColor: decision == 'approved'
              ? const Color(0xFF16A34A)
              : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.approvalItem;
    final type = item['type']?.toString() ?? 'Approval';
    final title = item['title']?.toString() ??
        item['text']?.toString() ??
        type;
    final branch = item['branch']?.toString() ?? '';
    final age = item['age']?.toString() ?? '';
    final amount = item['amount']?.toString() ?? '';

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.90,
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Fee Waiver & Close X)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap:
                          widget.onClose ?? () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Detail Title & Sub
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (branch.isNotEmpty) branch,
                    if (age.isNotEmpty) '$age waiting',
                    if (amount.isNotEmpty) amount,
                  ].join(' · '),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),

                // Note Input
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Optional note for the record...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF7C3AED),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons (Reject / Approve)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _handleDecision('rejected'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _handleDecision('approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 10,
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Approve',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
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
  }
}
