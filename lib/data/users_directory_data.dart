/// Model representing an individual user in the directory / roster
class UserDirectoryItem {
  final String name;
  final String initials;
  final String role; // 'students' | 'teaching' | 'non-teaching' | 'admins' | 'principals' | 'parents'
  final String roleLabel;
  final String branchId;
  final String branchName;
  final String meta;
  final String phone;

  const UserDirectoryItem({
    required this.name,
    required this.initials,
    required this.role,
    required this.roleLabel,
    required this.branchId,
    required this.branchName,
    required this.meta,
    required this.phone,
  });

  factory UserDirectoryItem.fromJson(Map<String, dynamic> json) {
    final rawName = (json['name'] ?? json['fullName'] ?? json['student_name'] ?? json['employee_name'] ?? json['first_name'] ?? '').toString().trim();
    
    // Compute initials
    String computedInitials = (json['initials'] ?? '').toString();
    if (computedInitials.isEmpty && rawName.isNotEmpty) {
      final parts = rawName.split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        computedInitials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        computedInitials = parts[0][0].toUpperCase();
      }
    }

    // Role mapping
    final rawRole = (json['role'] ?? json['user_role'] ?? json['roleLabel'] ?? '').toString().toLowerCase();
    String mappedRole = 'students';
    String mappedRoleLabel = 'Student';

    if (rawRole.contains('teach') || rawRole.contains('faculty') || rawRole.contains('instructor')) {
      if (rawRole.contains('non')) {
        mappedRole = 'non-teaching';
        mappedRoleLabel = 'Non-Teaching Staff';
      } else {
        mappedRole = 'teaching';
        mappedRoleLabel = 'Teaching Staff';
      }
    } else if (rawRole.contains('admin')) {
      mappedRole = 'admins';
      mappedRoleLabel = 'Administrator';
    } else if (rawRole.contains('princ')) {
      mappedRole = 'principals';
      mappedRoleLabel = 'Principal';
    } else if (rawRole.contains('parent') || rawRole.contains('guard')) {
      mappedRole = 'parents';
      mappedRoleLabel = 'Parent';
    } else if (rawRole.contains('student')) {
      mappedRole = 'students';
      mappedRoleLabel = 'Student';
    } else if (json['roleLabel'] != null) {
      mappedRoleLabel = json['roleLabel'].toString();
      mappedRole = rawRole;
    }

    final branch = (json['branchName'] ?? json['branch'] ?? json['custom_branch'] ?? '').toString().trim();
    final rawBranchId = (json['branchId'] ?? json['branch_id'] ?? '').toString().trim();
    final branchId = rawBranchId.isNotEmpty
        ? rawBranchId
        : branch.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    final meta = (json['meta'] ?? json['designation'] ?? json['department'] ?? json['grade'] ?? json['className'] ?? mappedRoleLabel).toString();
    final phone = (json['phone'] ?? json['mobileNo'] ?? json['mobile'] ?? json['cell_number'] ?? '').toString();

    return UserDirectoryItem(
      name: rawName.isNotEmpty ? rawName : 'User',
      initials: computedInitials.isNotEmpty ? computedInitials : 'U',
      role: mappedRole,
      roleLabel: mappedRoleLabel,
      branchId: branchId,
      branchName: branch,
      meta: meta,
      phone: phone,
    );
  }
}

/// Users directory repository (dynamically populated from live API)
class UsersDirectoryData {
  static const List<UserDirectoryItem> users = [];
}
