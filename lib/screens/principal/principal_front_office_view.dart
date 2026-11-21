import 'package:flutter/material.dart';

/// Principal Front Office Screen matching Web Screenshots 12 & 13:
/// - Subtitle: Meeting requests, gate passes, certificate and ID requests, and complaints from the desk.
/// - 4 KPI Cards:
///   - Admission queries (12 open)
///   - Complaints (2 to resolve)
///   - Visitors today (0 FaceGuard)
///   - Couriers (0 dispatched)
/// - Two-column / Stacked Sections:
///   1. Appointments (2 awaiting your decision):
///      - Ramesh (Scheduled, 12:30 | 18 Jun, Fee discussion, 8651345788) -> [Confirm] [Reject]
///      - Mrs. Iyer (Confirmed, 12:30 | 18 Jun, Academic concern, 9876500011) -> [Reject]
///      - srikanth (Scheduled, 16:59 | 17 Jun, General, 9789323456) -> [Confirm] [Reject]
///   2. Open Complaints · 2:
///      - Hostel · Room A201 (Medium) · Plumbing · Tap Leakage -> [Resolve]
///      - ZZ E2E attach test (Low) · Academic · verifying attachment upload -> [Resolve]
///   3. My Availability:
///      - Weekly schedule (Mon-Sun 10:00-12:00, 12:00-16:00), edit slots, date excluded selector, Save availability button
///   4. Gate Pass Approvals · 2:
///      - Sai Purushotham Gude (Hostel) -> [Approve] [Deny]
///      - Vihaan Iyer (Class - 5) -> [Approve] [Deny]
///   5. Certificate / ID requests · 0 (Empty placeholder)
class PrincipalFrontOfficeView extends StatefulWidget {
  const PrincipalFrontOfficeView({super.key});

  @override
  State<PrincipalFrontOfficeView> createState() =>
      _PrincipalFrontOfficeViewState();
}

class _PrincipalFrontOfficeViewState extends State<PrincipalFrontOfficeView> {
  // Appointment status tracking
  final Map<String, String> _appointmentStatus = {
    'apt-1': 'Scheduled',
    'apt-2': 'Confirmed',
    'apt-3': 'Scheduled',
  };

  // Complaint status tracking
  final Set<String> _resolvedComplaints = {};

  // Gate pass status tracking
  final Map<String, String> _gatePassStatus = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Subtitle
        const Text(
          'Front Office',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Meeting requests, gate passes, certificate and ID requests, and complaints from the desk.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 16),

        // 4 KPI Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildFrontOfficeKpi(
                label: 'Admission queries',
                value: '12',
                subtext: 'open',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFrontOfficeKpi(
                label: 'Complaints',
                value: '2',
                subtext: 'to resolve',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFrontOfficeKpi(
                label: 'Visitors today',
                value: '0',
                subtext: 'FaceGuard',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFrontOfficeKpi(
                label: 'Couriers',
                value: '0',
                subtext: 'dispatched',
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Section 1: Appointments
        _buildAppointmentsSection(),

        const SizedBox(height: 20),

        // Section 2: Open Complaints · 2
        _buildOpenComplaintsSection(),

        const SizedBox(height: 20),

        // Section 3: Gate Pass Approvals · 2
        _buildGatePassesSection(),

        const SizedBox(height: 20),

        // Section 4: My Availability
        _buildMyAvailabilitySection(),

        const SizedBox(height: 20),

        // Section 5: Certificate / ID requests · 0
        _buildCertificatesSection(),
      ],
    );
  }

  Widget _buildFrontOfficeKpi({
    required String label,
    required String value,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Urbanist',
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Urbanist',
                ),
              ),
              const SizedBox(width: 6),
              Text(
                subtext,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Urbanist',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Appointments ---
  Widget _buildAppointmentsSection() {
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
                'Appointments',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Urbanist',
                ),
              ),
              Text(
                '2 awaiting your decision',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Urbanist',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Appointment 1: Ramesh
          _buildAppointmentCard(
            id: 'apt-1',
            time: '12:30',
            date: '18 Jun',
            name: 'Ramesh',
            status: _appointmentStatus['apt-1'] ?? 'Scheduled',
            rolePurpose: 'Principal · Fee discussion',
            requestedVia: 'Requested via front desk · 8651345788',
          ),
          const SizedBox(height: 12),

          // Appointment 2: Mrs. Iyer
          _buildAppointmentCard(
            id: 'apt-2',
            time: '12:30',
            date: '18 Jun',
            name: 'Mrs. Iyer',
            status: _appointmentStatus['apt-2'] ?? 'Confirmed',
            rolePurpose: 'Principal · Academic concern',
            requestedVia: 'Requested via front desk · 9876500011',
          ),
          const SizedBox(height: 12),

          // Appointment 3: srikanth
          _buildAppointmentCard(
            id: 'apt-3',
            time: '16:59',
            date: '17 Jun',
            name: 'srikanth',
            status: _appointmentStatus['apt-3'] ?? 'Scheduled',
            rolePurpose: 'Principal · General',
            requestedVia: 'Requested via front desk · 9789323456',
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard({
    required String id,
    required String time,
    required String date,
    required String name,
    required String status,
    required String rolePurpose,
    required String requestedVia,
  }) {
    final isConfirmed = status == 'Confirmed';
    final isRejected = status == 'Rejected';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time & Date Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Name & Status Pill
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Urbanist',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isConfirmed
                                ? const Color(0xFFDCFCE7)
                                : isRejected
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: isConfirmed
                                  ? const Color(0xFF15803D)
                                  : isRejected
                                      ? const Color(0xFFB91C1C)
                                      : const Color(0xFF0369A1),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Urbanist',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      rolePurpose,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Urbanist',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      requestedVia,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10.5,
                        fontFamily: 'Urbanist',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isConfirmed && !isRejected) ...[
                ElevatedButton(
                  onPressed: () {
                    setState(() => _appointmentStatus[id] = 'Confirmed');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Appointment with $name confirmed')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Confirm', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
              ],
              if (!isRejected)
                OutlinedButton(
                  onPressed: () {
                    setState(() => _appointmentStatus[id] = 'Rejected');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Appointment with $name declined')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Reject', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Open Complaints ---
  Widget _buildOpenComplaintsSection() {
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
            children: [
              const Text(
                'Open complaints · 2',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Urbanist',
                ),
              ),
              InkWell(
                onTap: () {},
                child: const Text(
                  'Manage →',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Complaint 1
          _buildComplaintCard(
            id: 'cmp-1',
            category: 'Hostel',
            location: 'Hostel - Room A201',
            severity: 'Medium',
            severityColor: const Color(0xFFF59E0B),
            detail: 'Plumbing · Tap Leakage (Room A201) · Ramesh Kumar · 23d ago',
          ),
          const SizedBox(height: 10),

          // Complaint 2
          _buildComplaintCard(
            id: 'cmp-2',
            category: 'Academic',
            location: 'ZZ E2E attach test',
            severity: 'Low',
            severityColor: const Color(0xFF3B82F6),
            detail: 'Academic · verifying attachment upload · sriram.mullapudi@innovorex.co.in · 130d ago',
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard({
    required String id,
    required String category,
    required String location,
    required String severity,
    required Color severityColor,
    required String detail,
  }) {
    final isResolved = _resolvedComplaints.contains(id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
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
                Row(
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Urbanist',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        location,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Urbanist',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        severity,
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: isResolved
                ? null
                : () {
                    setState(() => _resolvedComplaints.add(id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Complaint marked as resolved')),
                    );
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: isResolved ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
              side: BorderSide(color: isResolved ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isResolved ? 'Resolved' : 'Resolve',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- Gate Pass Approvals ---
  Widget _buildGatePassesSection() {
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
          const Text(
            'Gate pass approvals · 2',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFamily: 'Urbanist',
            ),
          ),
          const SizedBox(height: 14),

          // Pass 1: Sai Purushotham Gude
          _buildGatePassCard(
            id: 'gp-1',
            studentName: 'Sai Purushotham Gude',
            tag: 'Hostel',
            detail: 'Home Visit: Birthday · 2026-11-10 -> 2026-11-11',
          ),
          const SizedBox(height: 10),

          // Pass 2: Vihaan Iyer
          _buildGatePassCard(
            id: 'gp-2',
            studentName: 'Vihaan Iyer (Class - 5)',
            tag: 'Medical',
            detail: 'Medical · Venky Iyer (Father) · 01:00',
          ),
        ],
      ),
    );
  }

  Widget _buildGatePassCard({
    required String id,
    required String studentName,
    required String tag,
    required String detail,
  }) {
    final status = _gatePassStatus[id];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                studentName,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Urbanist',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontFamily: 'Urbanist',
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status == null) ...[
                ElevatedButton(
                  onPressed: () {
                    setState(() => _gatePassStatus[id] = 'Approved');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gate pass approved for $studentName')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Approve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() => _gatePassStatus[id] = 'Denied');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gate pass denied for $studentName')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Deny', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status == 'Approved' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == 'Approved' ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- My Availability ---
  Widget _buildMyAvailabilitySection() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
            children: [
              const Text(
                'My availability',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Urbanist',
                ),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Edit slots', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            '20-minute slots · the front desk books only these',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontFamily: 'Urbanist',
            ),
          ),
          const SizedBox(height: 12),

          // Days table
          Column(
            children: days.map((d) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        d,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        '10:00–12:00, 12:00–16:00',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),
          const Text(
            'Not available on',
            style: TextStyle(
              color: Color(0xFF334155),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'Urbanist',
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('dd-mm-yyyy', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      Icon(Icons.calendar_month_outlined, color: Color(0xFF64748B), size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Add date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Availability slots updated successfully'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save availability', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Certificates ---
  Widget _buildCertificatesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Certificate / ID requests · 0',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: 'Urbanist',
            ),
          ),
          SizedBox(height: 3),
          Text(
            'Logged by reception — issue via the TC / Bonafide / ID-card modules',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontFamily: 'Urbanist',
            ),
          ),
          SizedBox(height: 18),
          Center(
            child: Text(
              'No pending certificate / ID requests.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontFamily: 'Urbanist',
              ),
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
