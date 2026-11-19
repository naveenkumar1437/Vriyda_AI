import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';

/// Comprehensive Profile Screen matching Web Portal Profile (Images 2 & 3):
/// - Breadcrumb: ORGANIZATION · ACCOUNT · SECURITY
/// - Title & Date: "My Profile", "Chairman · Sai Ravindra School · Thu, 19 Nov 2026"
/// - Hero Banner Card with Avatar, Camera Badge, Name, Role Badge, Email, Member Since
/// - Personal Details Card with Edit Details dialog (First/Last name, Mobile, Office Phone, Gender, DOB)
/// - Account Card (Email login, Role, Organisation, Branch Access)
/// - Change Password Card with Live Requirements Checklist and Update Password button
class ProfileScreen extends StatefulWidget {
  final UserSession user;
  final bool initialScrollToPassword;
  final VoidCallback? onBack;

  const ProfileScreen({
    super.key,
    required this.user,
    this.initialScrollToPassword = false,
    this.onBack,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _passwordSectionKey = GlobalKey();

  // Personal details state (initialized from UserSession)
  late String _firstName;
  late String _lastName;
  String _mobile = 'Not set';
  String _officePhone = 'Not set';
  String _gender = 'Not set';
  String _dateOfBirth = 'Not set';
  String _memberSince = '28 May 2026';
  final String _lastLogin = '—';

  // Change Password state
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isUpdatingPassword = false;
  String? _passwordErrorMessage;
  String? _passwordSuccessMessage;

  @override
  void initState() {
    super.initState();
    final nameParts = widget.user.name.trim().split(RegExp(r'\s+'));
    _firstName = nameParts.isNotEmpty ? nameParts.first : 'Charan';
    _lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Makkuva';

    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
    _currentPasswordController.addListener(() => setState(() {}));

    if (widget.initialScrollToPassword) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToPasswordSection();
      });
    }

    _fetchProfileData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    // 1. Load locally persisted edits first
    try {
      final local = await SessionManager.getProfileDetails();
      if (local != null && mounted) {
        setState(() {
          if (local['firstName']?.toString().isNotEmpty == true) {
            _firstName = local['firstName'].toString();
          }
          if (local['lastName']?.toString().isNotEmpty == true) {
            _lastName = local['lastName'].toString();
          }
          if (local['mobile']?.toString().isNotEmpty == true) {
            _mobile = local['mobile'].toString();
          }
          if (local['officePhone']?.toString().isNotEmpty == true) {
            _officePhone = local['officePhone'].toString();
          }
          if (local['gender']?.toString().isNotEmpty == true) {
            _gender = local['gender'].toString();
          }
          if (local['dateOfBirth']?.toString().isNotEmpty == true) {
            _dateOfBirth = local['dateOfBirth'].toString();
          }
        });
      }
    } catch (_) {}

    // 2. Fetch backend profile from GET /my-profile
    try {
      final res = await AuthService.getMyProfile();
      if (res.success && res.data != null && mounted) {
        final data = res.data!;
        final local = await SessionManager.getProfileDetails();
        setState(() {
          // Only overwrite if user hasn't explicitly set them locally
          if (local?['firstName'] == null && data['firstName'] != null && data['firstName'].toString().isNotEmpty) {
            _firstName = data['firstName'].toString();
          }
          if (local?['lastName'] == null && data['lastName'] != null && data['lastName'].toString().isNotEmpty) {
            _lastName = data['lastName'].toString();
          }
          if (local?['mobile'] == null && data['phone'] != null && data['phone'].toString().isNotEmpty) {
            _mobile = data['phone'].toString();
          }
          if (local?['officePhone'] == null && data['officePhone'] != null && data['officePhone'].toString().isNotEmpty) {
            _officePhone = data['officePhone'].toString();
          }
          if (local?['gender'] == null && data['gender'] != null && data['gender'].toString().isNotEmpty) {
            _gender = data['gender'].toString();
          }
          if (local?['dateOfBirth'] == null && data['dateOfBirth'] != null && data['dateOfBirth'].toString().isNotEmpty) {
            _dateOfBirth = data['dateOfBirth'].toString();
          }
          if (data['createdAt'] != null) {
            _memberSince = data['createdAt'].toString();
          }
        });
      }
    } catch (_) {}
  }

  void _scrollToPasswordSection() {
    final ctx = _passwordSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // --- Password Criteria Checkers ---
  bool get _hasMin8Chars => _newPasswordController.text.length >= 8;
  bool get _hasLettersAndNumbers {
    final text = _newPasswordController.text;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(text);
    final hasNumber = RegExp(r'[0-9]').hasMatch(text);
    return hasLetter && hasNumber;
  }

  bool get _isDifferentFromCurrent {
    final cur = _currentPasswordController.text;
    final newP = _newPasswordController.text;
    if (newP.isEmpty) return false;
    if (cur.isEmpty) return true;
    return newP != cur;
  }

  bool get _isBothPasswordsMatch {
    final newP = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    return newP.isNotEmpty && newP == confirm;
  }

  bool get _isPasswordFormValid =>
      _currentPasswordController.text.isNotEmpty &&
      _hasMin8Chars &&
      _hasLettersAndNumbers &&
      _isDifferentFromCurrent &&
      _isBothPasswordsMatch;

  Future<void> _handlePasswordUpdate() async {
    HapticFeedback.lightImpact();
    if (!_isPasswordFormValid) {
      setState(() {
        _passwordErrorMessage = 'Please fulfill all password requirements before updating.';
        _passwordSuccessMessage = null;
      });
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
      _passwordErrorMessage = null;
      _passwordSuccessMessage = null;
    });

    try {
      final res = await AuthService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      setState(() => _isUpdatingPassword = false);

      if (res.success) {
        setState(() {
          _passwordSuccessMessage = 'Password updated successfully!';
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Password updated successfully!'),
              ],
            ),
          ),
        );
      } else {
        setState(() {
          _passwordErrorMessage = res.message.isNotEmpty ? res.message : 'Failed to update password';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdatingPassword = false;
        _passwordErrorMessage = 'Error: $e';
      });
    }
  }

  DateTime? _parseDate(String dateStr) {
    if (dateStr == 'Not set' || dateStr.isEmpty) return null;
    final parts = dateStr.split(RegExp(r'[-/]'));
    if (parts.length == 3) {
      if (parts[0].length == 4) {
        // YYYY-MM-DD
        return DateTime.tryParse(dateStr);
      } else {
        // DD/MM/YYYY
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    }
    return DateTime.tryParse(dateStr);
  }

  void _openEditDetailsDialog() {
    final fNameCtrl = TextEditingController(text: _firstName);
    final lNameCtrl = TextEditingController(text: _lastName);
    final mobileCtrl = TextEditingController(text: _mobile == 'Not set' ? '' : _mobile);
    final officeCtrl = TextEditingController(text: _officePhone == 'Not set' ? '' : _officePhone);
    String selectedGender = _gender == 'Not set' ? 'Male' : _gender;
    DateTime? selectedDob = _parseDate(_dateOfBirth);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_outline, color: Color(0xFF7C3AED), size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Edit Personal Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogField('First Name', fNameCtrl),
                    const SizedBox(height: 12),
                    _buildDialogField('Last Name', lNameCtrl),
                    const SizedBox(height: 12),
                    _buildDialogField('Mobile Number', mobileCtrl, keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _buildDialogField('Office Phone', officeCtrl, keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    // Gender selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: ['Male', 'Female', 'Other', 'Prefer not to say'].contains(selectedGender)
                                  ? selectedGender
                                  : 'Male',
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                              ),
                              items: ['Male', 'Female', 'Other', 'Prefer not to say']
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedGender = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Date of Birth Calendar Picker Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date of Birth',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDob ?? DateTime(1985, 1, 1),
                              firstDate: DateTime(1940),
                              lastDate: now,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF7C3AED),
                                      onPrimary: Colors.white,
                                      onSurface: Color(0xFF0F172A),
                                    ),
                                    dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedDob = picked;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedDob != null
                                      ? "${selectedDob!.day.toString().padLeft(2, '0')}/${selectedDob!.month.toString().padLeft(2, '0')}/${selectedDob!.year}"
                                      : (_dateOfBirth != 'Not set'
                                          ? _dateOfBirth
                                          : 'Select Date of Birth (Calendar)'),
                                  style: TextStyle(
                                    color: (selectedDob != null || _dateOfBirth != 'Not set')
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFF94A3B8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  color: Color(0xFF7C3AED),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        FocusManager.instance.primaryFocus?.unfocus();
                        setDialogState(() => isSaving = true);
                        final fName = fNameCtrl.text.trim();
                        final lName = lNameCtrl.text.trim();
                        final mob = mobileCtrl.text.trim();
                        final off = officeCtrl.text.trim();
                        final gen = selectedGender;
                        final dobFormatted = selectedDob != null
                            ? "${selectedDob!.day.toString().padLeft(2, '0')}/${selectedDob!.month.toString().padLeft(2, '0')}/${selectedDob!.year}"
                            : (_dateOfBirth != 'Not set' ? _dateOfBirth : '');

                        final newFirstName = fName.isNotEmpty ? fName : _firstName;
                        final newLastName = lName.isNotEmpty ? lName : _lastName;
                        final newMobile = mob.isNotEmpty ? mob : 'Not set';
                        final newOffice = off.isNotEmpty ? off : 'Not set';
                        final newGender = gen.isNotEmpty && gen != 'Not set' ? gen : 'Not set';
                        final newDob = dobFormatted.isNotEmpty && dobFormatted != 'Not set'
                            ? dobFormatted
                            : 'Not set';

                        // 1. Permanently save to local storage
                        await SessionManager.saveProfileDetails({
                          'firstName': newFirstName,
                          'lastName': newLastName,
                          'fullName': '$newFirstName $newLastName'.trim(),
                          'mobile': newMobile,
                          'officePhone': newOffice,
                          'gender': newGender,
                          'dateOfBirth': newDob,
                        });

                        // 2. Update cached session if name changed
                        try {
                          final currentSession = await SessionManager.getSession();
                          if (currentSession != null) {
                            final updatedSession = UserSession(
                              id: currentSession.id,
                              token: currentSession.token,
                              refreshToken: currentSession.refreshToken,
                              email: currentSession.email,
                              name: '$newFirstName $newLastName'.trim(),
                              role: currentSession.role,
                              roles: currentSession.roles,
                              branchId: currentSession.branchId,
                              branchName: currentSession.branchName,
                              organizationId: currentSession.organizationId,
                              organizationName: currentSession.organizationName,
                              mustChangePassword: currentSession.mustChangePassword,
                            );
                            final remembered = await SessionManager.isRemembered();
                            await SessionManager.saveSession(updatedSession, rememberMe: remembered);
                          }
                        } catch (_) {}

                        // 3. Dispatch to backend API (PUT /my-profile) in anticipation of backend update
                        try {
                          await AuthService.updateMyProfile(
                            firstName: newFirstName,
                            lastName: newLastName,
                            fullName: '$newFirstName $newLastName'.trim(),
                            phone: newMobile != 'Not set' ? newMobile : null,
                            officePhone: newOffice != 'Not set' ? newOffice : null,
                            gender: newGender != 'Not set' ? newGender : null,
                            dateOfBirth: newDob != 'Not set' ? newDob : null,
                          );
                        } catch (_) {}

                        if (!mounted) return;
                        setState(() {
                          _firstName = newFirstName;
                          _lastName = newLastName;
                          _mobile = newMobile;
                          _officePhone = newOffice;
                          _gender = newGender;
                          _dateOfBirth = newDob;
                        });

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF10B981),
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Personal details saved successfully!'),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Save Details',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController ctrl, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: const Color(0xFF7C3AED),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF7C3AED)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgName = widget.user.organizationName ?? 'Sai Ravindra School';
    final roleName = widget.user.role.isNotEmpty
        ? widget.user.role[0].toUpperCase() + widget.user.role.substring(1)
        : 'Chairman';
    final email = widget.user.email.isNotEmpty ? widget.user.email : 'charan.makkuva@innovorex.co.in';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TOP BAR ---
                  _buildTopBar(),
                  const SizedBox(height: 16),

                  // --- HERO PROFILE BANNER CARD ---
                  _buildHeroProfileBanner(orgName, roleName, email),
                  const SizedBox(height: 16),

                  // --- MAIN GRID: DETAILS (LEFT) & PASSWORD (RIGHT) ---
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 840;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (Personal Details + Account)
                            Expanded(
                              flex: 11,
                              child: Column(
                                children: [
                                  _buildPersonalDetailsCard(),
                                  const SizedBox(height: 16),
                                  _buildAccountCard(orgName, roleName, email),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right Column (Change Password)
                            Expanded(
                              key: _passwordSectionKey,
                              flex: 9,
                              child: _buildChangePasswordCard(),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildPersonalDetailsCard(),
                            const SizedBox(height: 16),
                            _buildAccountCard(orgName, roleName, email),
                            const SizedBox(height: 16),
                            Container(
                              key: _passwordSectionKey,
                              child: _buildChangePasswordCard(),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- TOP BAR ---
  Widget _buildTopBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (Navigator.of(context).canPop() || widget.onBack != null) ...[
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 22, color: Color(0xFF0F172A)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        const Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // --- 1. HERO PROFILE BANNER CARD ---
  Widget _buildHeroProfileBanner(String orgName, String roleName, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final avatarAndInfo = Row(
            children: [
              // Circular Avatar with Innovorex branding + Camera badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'innovorex',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'products',
                            style: TextStyle(
                              color: const Color(0xFF64748B).withValues(alpha: 0.8),
                              fontSize: 6,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Name, Pill, Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_firstName $_lastName',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            roleName,
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '$orgName · $email',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final stats = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LAST LOGIN',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _lastLogin,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MEMBER SINCE',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _memberSince,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatarAndInfo,
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 12),
                stats,
              ],
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: avatarAndInfo),
                const SizedBox(width: 16),
                stats,
              ],
            );
          }
        },
      ),
    );
  }

  // --- 2. PERSONAL DETAILS CARD ---
  Widget _buildPersonalDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_outline, color: Color(0xFF7C3AED), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal details',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Shown to branch admins and principals',
                            style: TextStyle(
                              color: Color(0xFF64748B),
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
              OutlinedButton(
                onPressed: _openEditDetailsDialog,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Edit details',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),

          // Row 1: First Name / Last Name
          _build2ColumnRow('FIRST NAME', _firstName, 'LAST NAME', _lastName),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),

          // Row 2: Mobile / Office Phone
          _build2ColumnRow('MOBILE', _mobile, 'OFFICE PHONE', _officePhone),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),

          // Row 3: Gender / Date of Birth
          _build2ColumnRow('GENDER', _gender, 'DATE OF BIRTH', _dateOfBirth),
        ],
      ),
    );
  }

  // --- 3. ACCOUNT CARD ---
  Widget _buildAccountCard(String orgName, String roleName, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.badge_outlined, color: Color(0xFF7C3AED), size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Managed by your organisation',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),

          // Row 1: Email / Role
          _build2ColumnRow('EMAIL (LOGIN)', email, 'ROLE', roleName),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),

          // Row 2: Organisation / Branch Access
          _build2ColumnRow('ORGANISATION', orgName, 'BRANCH ACCESS', 'All branches'),
        ],
      ),
    );
  }

  Widget _build2ColumnRow(String label1, String val1, String label2, String val2) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                val1,
                style: TextStyle(
                  color: val1 == 'Not set' ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label2,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                val2,
                style: TextStyle(
                  color: val2 == 'Not set' ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 4. CHANGE PASSWORD CARD ---
  Widget _buildChangePasswordCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline, color: Color(0xFF7C3AED), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change password',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Use at least 8 characters with a mix of letters and numbers',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Messages
          if (_passwordErrorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _passwordErrorMessage!,
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_passwordSuccessMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _passwordSuccessMessage!,
                      style: const TextStyle(color: Color(0xFF059669), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Current password field
          _buildPasswordField(
            label: 'Current password',
            controller: _currentPasswordController,
            obscureText: _obscureCurrent,
            onToggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 14),

          // New password field
          _buildPasswordField(
            label: 'New password',
            controller: _newPasswordController,
            obscureText: _obscureNew,
            onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 14),

          // Confirm new password field
          _buildPasswordField(
            label: 'Confirm new password',
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 16),

          // Requirements checklist
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChecklistItem('At least 8 characters', _hasMin8Chars),
                const SizedBox(height: 8),
                _buildChecklistItem('Letters and numbers', _hasLettersAndNumbers),
                const SizedBox(height: 8),
                _buildChecklistItem('Different from the current password', _isDifferentFromCurrent),
                const SizedBox(height: 8),
                _buildChecklistItem('Both new passwords match', _isBothPasswordsMatch),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Update password button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _isUpdatingPassword ? null : _handlePasswordUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _isUpdatingPassword
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Update password',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: const Color(0xFF7C3AED),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(String title, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isMet ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: isMet ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            fontSize: 11,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
