import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/student_service.dart';

/// Enhanced Student Lookup View matching the official Web screens:
/// - Context Header: SAI RAVINDRA SCHOOL · STUDENT LOOKUP · GARUDA AI
/// - 4 Cascading Filters: BRANCH, CLASS, SECTION, STUDENT (Search & Dropdown)
/// - Interactive Student Card with Student Name, Hierarchy Pill, and ⚡ GARUDA AI badge
/// - 4 Metric Badges: Attendance %, Exam Score, Support Status, Due Amount
/// - 5-Point Garuda AI Executive Bullet Points (Academics, Attendance, Fees, Conduct, Overall)
class StudentLookupView extends StatefulWidget {
  const StudentLookupView({super.key});

  @override
  State<StudentLookupView> createState() => _StudentLookupViewState();
}

class _StudentLookupViewState extends State<StudentLookupView> {
  bool _isLoadingRoster = true;
  bool _isLoadingSnippet = false;
  bool _isFetchingAi = false;

  List<StudentLookupItem> _allStudents = [];
  List<StudentLookupItem> _filteredStudents = [];

  String _selectedBranch = 'All branches';
  String _selectedClass = 'All classes';
  String _selectedSection = 'All sections';

  StudentLookupItem? _selectedStudent;
  StudentSnippetData? _studentSnippet;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadInitialRoster();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialRoster() async {
    setState(() => _isLoadingRoster = true);
    final students = await StudentService.getStudents();
    if (!mounted) return;

    setState(() {
      _allStudents = students;
      _applyFilters();
      _isLoadingRoster = false;
    });

    // Auto-select Jatin kalidindi by default if available to match initial screen
    final defaultStudent = _allStudents.firstWhere(
      (s) => s.name.toLowerCase().contains('jatin'),
      orElse: () => _allStudents.isNotEmpty ? _allStudents.first : const StudentLookupItem(
        id: 'EDU-STU-2026-00012',
        name: 'Jatin kalidindi',
        branch: 'Steel Plant Branch',
        klass: 'Class - 1',
        section: 'Section-A',
      ),
    );
    _onStudentSelected(defaultStudent);
  }

  void _applyFilters() {
    setState(() {
      _filteredStudents = _allStudents.where((s) {
        if (_selectedBranch != 'All branches' && s.branch != _selectedBranch) {
          return false;
        }
        if (_selectedClass != 'All classes' && s.klass != _selectedClass) {
          return false;
        }
        if (_selectedSection != 'All sections' && s.section != _selectedSection) {
          return false;
        }
        final q = _searchController.text.trim().toLowerCase();
        if (q.isNotEmpty &&
            !s.name.toLowerCase().contains(q) &&
            !s.id.toLowerCase().contains(q)) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _onStudentSelected(StudentLookupItem student) async {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedStudent = student;
      _searchController.text = student.name;
      _showSuggestions = false;
      _isLoadingSnippet = true;
    });

    // Step 1: Instant snapshot (API 15)
    final snapshot = await StudentService.getStudentSnippet(student.id);
    if (!mounted) return;

    setState(() {
      _studentSnippet = snapshot;
      _isLoadingSnippet = false;
      _isFetchingAi = true;
    });

    // Step 2: Garuda AI refinement (API 16)
    final aiSnippet = await StudentService.getStudentAiSnippet(student.id);
    if (!mounted) return;

    if (aiSnippet != null) {
      setState(() {
        _studentSnippet = aiSnippet;
        _isFetchingAi = false;
      });
    } else {
      setState(() => _isFetchingAi = false);
    }
  }

  List<String> get _branchOptions {
    final set = {'All branches'};
    for (final s in _allStudents) {
      if (s.branch.isNotEmpty) set.add(s.branch);
    }
    return set.toList();
  }

  List<String> get _classOptions {
    final set = {'All classes'};
    for (final s in _allStudents) {
      if (_selectedBranch == 'All branches' || s.branch == _selectedBranch) {
        if (s.klass.isNotEmpty) set.add(s.klass);
      }
    }
    return set.toList();
  }

  List<String> get _sectionOptions {
    final set = {'All sections'};
    for (final s in _allStudents) {
      final matchesBranch = _selectedBranch == 'All branches' || s.branch == _selectedBranch;
      final matchesClass = _selectedClass == 'All classes' || s.klass == _selectedClass;
      if (matchesBranch && matchesClass && s.section.isNotEmpty) {
        set.add(s.section);
      }
    }
    return set.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top Section Header (matching web screenshot)
        _buildSectionHeader(),
        const SizedBox(height: 14),

        // 2. Find a student card with 4 cascading filters
        _buildFindStudentCard(),
        const SizedBox(height: 16),

        // 3. Student 360 Garuda AI Snapshot Card
        if (_isLoadingRoster || _isLoadingSnippet)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
              ),
            ),
          )
        else if (_studentSnippet != null)
          _buildStudentGarudaCard(_studentSnippet!),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return const Text(
      'Student Lookup',
      style: TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
    );
  }

  Widget _buildFindStudentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Find a student',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Filter down, then pick a student to see a 4–5 point snapshot',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          // Filters Row 1: Branch, Class, Section (Mobile responsive flex)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildDropdownSelector(
                        label: 'BRANCH',
                        value: _selectedBranch,
                        items: _branchOptions,
                        onChanged: (val) {
                          setState(() {
                            _selectedBranch = val;
                            _selectedClass = 'All classes';
                            _selectedSection = 'All sections';
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdownSelector(
                        label: 'CLASS',
                        value: _selectedClass,
                        items: _classOptions,
                        onChanged: (val) {
                          setState(() {
                            _selectedClass = val;
                            _selectedSection = 'All sections';
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdownSelector(
                        label: 'SECTION',
                        value: _selectedSection,
                        items: _sectionOptions,
                        onChanged: (val) {
                          setState(() {
                            _selectedSection = val;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                );
              }

              // On compact screens: 3 filters in a clean row
              return Row(
                children: [
                  Expanded(
                    child: _buildDropdownSelector(
                      label: 'BRANCH',
                      value: _selectedBranch,
                      items: _branchOptions,
                      onChanged: (val) {
                        setState(() {
                          _selectedBranch = val;
                          _selectedClass = 'All classes';
                          _selectedSection = 'All sections';
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildDropdownSelector(
                      label: 'CLASS',
                      value: _selectedClass,
                      items: _classOptions,
                      onChanged: (val) {
                        setState(() {
                          _selectedClass = val;
                          _selectedSection = 'All sections';
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildDropdownSelector(
                      label: 'SECTION',
                      value: _selectedSection,
                      items: _sectionOptions,
                      onChanged: (val) {
                        setState(() {
                          _selectedSection = val;
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 10),

          // Filter 4: STUDENT Search Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STUDENT',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onTap: () => setState(() => _showSuggestions = true),
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Search student...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _showSuggestions = false);
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          _showSuggestions
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: const Color(0xFF64748B),
                        ),
                        onPressed: () {
                          setState(() => _showSuggestions = !_showSuggestions);
                        },
                      ),
                    ],
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                  ),
                ),
              ),
            ],
          ),

          // Dropdown Auto-suggest List
          if (_showSuggestions && _filteredStudents.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _filteredStudents.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final s = _filteredStudents[index];
                  final isSelected = _selectedStudent?.id == s.id;
                  return InkWell(
                    onTap: () => _onStudentSelected(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: isSelected ? const Color(0xFFF5F3FF) : Colors.transparent,
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  style: TextStyle(
                                    color: const Color(0xFF0F172A),
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${s.klass} · ${s.section} · ${s.branch}',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Color(0xFF7C3AED),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownSelector({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            _showFilterBottomSheet(
              title: 'Select $label',
              items: items,
              selectedValue: value,
              onSelected: onChanged,
            );
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
    );
  }

  void _showFilterBottomSheet({
    required String title,
    required List<String> items,
    required String selectedValue,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    final isSel = item == selectedValue;
                    return ListTile(
                      dense: true,
                      title: Text(
                        item,
                        style: TextStyle(
                          color: isSel ? const Color(0xFF7C3AED) : const Color(0xFF0F172A),
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      trailing: isSel
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF7C3AED), size: 18)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        onSelected(item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentGarudaCard(StudentSnippetData data) {
    final klass = data.klass.isNotEmpty ? data.klass : 'Class - 1';
    final section = data.section.isNotEmpty ? data.section : 'Section-A';
    final branch = data.branch.isNotEmpty ? data.branch : 'Steel Plant Branch';
    final hierarchyText = '${klass.toUpperCase()} · ${section.toUpperCase()} · ${branch.toUpperCase()}';

    final dueText = data.due > 0 ? 'Due ₹${_formatAmount(data.due)}' : 'Fees Cleared';
    final standingText = data.passed ? 'Passing' : 'Needs support';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Dot + Student Name + Hierarchy Pill + ⚡ GARUDA AI Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Purple Dot
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF7C3AED),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Student Name & Hierarchy Pill
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          data.name,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hierarchyText,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ⚡ GARUDA AI Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    const Text(
                      'GARUDA AI',
                      style: TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (_isFetchingAi) ...[
                      const SizedBox(width: 4),
                      const SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Metric Badges Strip (Attendance 92%, Exam 32/100, Needs support, Due ₹65,000)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildMetricPill('Attendance ${data.attendancePct}%'),
                const SizedBox(width: 6),
                _buildMetricPill('Exam ${data.examAvg}/100'),
                const SizedBox(width: 6),
                _buildMetricPill(
                  standingText,
                  textColor: data.passed ? const Color(0xFF059669) : const Color(0xFFB91C1C),
                  bgColor: data.passed ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                ),
                const SizedBox(width: 6),
                _buildMetricPill(
                  dueText,
                  textColor: data.due > 0 ? const Color(0xFFB91C1C) : const Color(0xFF047857),
                  bgColor: data.due > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // 5-Point Garuda AI Bullet Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.bullets.map((bullet) => _buildGarudaBullet(bullet)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String text, {Color? textColor, Color? bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? const Color(0xFF1E293B),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildGarudaBullet(String text) {
    // Parse prefix (e.g. "Academics:") from description
    String prefix = '';
    String body = text;

    final colonIdx = text.indexOf(':');
    if (colonIdx > 0 && colonIdx < 16) {
      prefix = text.substring(0, colonIdx + 1);
      body = text.substring(colonIdx + 1).trim();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '•',
              style: TextStyle(
                color: Color(0xFF7C3AED),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 12.5,
                  height: 1.45,
                ),
                children: [
                  if (prefix.isNotEmpty)
                    TextSpan(
                      text: '$prefix ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  TextSpan(
                    text: body,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(num amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)} L';
    }
    return amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
