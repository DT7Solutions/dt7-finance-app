import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header_icon_button.dart';
import '../widgets/custom_button.dart';
import '02_login_screen.dart';
import '03_dashboard_screen.dart';
import '06_employee_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const ProfileScreen({super.key, this.onBackPressed});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedVersion = 0; // 0 = Overview, 1 = Settings & Security
  UserModel? _currentUser;
  String? _profilePhotoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = await ApiService.getCurrentUser();
    final photo = await AuthService.getProfilePhoto();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _profilePhotoUrl = photo;
        _isLoading = false;
      });
    }
  }

  void _showEditProfilePhotoModal(BuildContext context) {
    final photoCtrl = TextEditingController(text: _profilePhotoUrl ?? '');
    String selectedPhoto = _profilePhotoUrl ?? 'assets/images/founder_avatar.png';

    final presetAvatars = [
      'assets/images/founder_avatar.png',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Edit Profile Photo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: _buildAvatarImage(selectedPhoto, size: 88),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Preset Avatar',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: presetAvatars.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, idx) {
                        final avatarPath = presetAvatars[idx];
                        final isSelected = selectedPhoto == avatarPath;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedPhoto = avatarPath;
                              photoCtrl.text = avatarPath;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.grey.shade100,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: _buildAvatarImage(avatarPath, size: 52),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Or Custom Image URL / Asset Path',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: photoCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. https://example.com/avatar.jpg',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        selectedPhoto = val.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await AuthService.saveProfilePhoto('');
                            if (mounted) {
                              Navigator.pop(ctx);
                              _loadProfileData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile photo removed!'), backgroundColor: Colors.grey),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Remove Photo', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Save Photo',
                          onPressed: () async {
                            final finalPath = photoCtrl.text.trim().isNotEmpty ? photoCtrl.text.trim() : selectedPhoto;
                            await AuthService.saveProfilePhoto(finalPath);
                            if (mounted) {
                              Navigator.pop(ctx);
                              _loadProfileData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile photo updated successfully!'), backgroundColor: AppColors.approvedGreen),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String path, {required double size}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.person, size: size * 0.6, color: AppColors.primary),
      );
    } else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.person, size: size * 0.6, color: AppColors.primary),
      );
    } else {
      return Icon(Icons.person, size: size * 0.6, color: AppColors.primary);
    }
  }

  Future<void> _handleBackNavigation() async {
    if (widget.onBackPressed != null) {
      widget.onBackPressed!();
      return;
    }
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    final role = await AuthService.getUserRole();
    if (mounted) {
      if (role == 'EMPLOYEE') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeDashboardScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const FounderDashboardScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = _currentUser?.username ?? '';
    final name = _currentUser?.fullName.isNotEmpty == true 
        ? _currentUser!.fullName 
        : (_currentUser?.username.isNotEmpty == true ? _currentUser!.username : 'Employee User');
    final email = _currentUser?.email.isNotEmpty == true 
        ? _currentUser!.email 
        : (username.isNotEmpty ? '$username@gmail.com' : 'employee@gmail.com');
    final roleTitle = (_currentUser?.isFounder == true || _currentUser?.role == 'FOUNDER')
        ? 'FOUNDER (SUPER USER)'
        : ((_currentUser?.isAdmin == true || _currentUser?.role == 'ADMIN') ? 'ADMIN' : 'STAFF EMPLOYEE');
    final empId = _currentUser?.employeeId.isNotEmpty == true ? _currentUser!.employeeId : 'DT7EMP002';
    final dept = _currentUser?.department.isNotEmpty == true ? _currentUser!.department : 'Operations Department';
    final phone = _currentUser?.phone ?? '+91 98765 43210';
    final allocated = _currentUser?.allocatedAmount ?? 0.0;
    final used = _currentUser?.usedAmount ?? 0.0;
    final remaining = _currentUser?.remainingAmount ?? (allocated - used);

    return Scaffold(
      drawer: const AppDrawer(currentRoute: 'profile'),
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Profile & Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: AppHeaderIconButton(
          icon: Icons.arrow_back,
          color: Colors.white,
          onPressed: _handleBackNavigation,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile details copied to clipboard!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // --- 1. HERO THEME HEADER CARD ---
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33FF5500),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 4),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _showEditProfilePhotoModal(context),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircleAvatar(
                                    radius: 44,
                                    backgroundColor: AppColors.primaryLight,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: _buildAvatarImage(
                                        _profilePhotoUrl ?? 'assets/images/founder_avatar.png',
                                        size: 88,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 6,
                                      )
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, size: 20, color: Colors.white),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              roleTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- 2. QUICK METRICS ROW ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Remaining',
                              value: '₹${remaining.toStringAsFixed(0)}',
                              icon: Icons.account_balance_wallet_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Allocated',
                              value: '₹${allocated.toStringAsFixed(0)}',
                              icon: Icons.pie_chart_rounded,
                              color: Colors.amber.shade800,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Used',
                              value: '₹${used.toStringAsFixed(0)}',
                              icon: Icons.fact_check_rounded,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- 3. VERSION / VIEW SWITCHER PILL ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedVersion = 0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedVersion == 0 ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _selectedVersion == 0
                                        ? [
                                            const BoxShadow(
                                              color: Color(0x33FF5500),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            )
                                          ]
                                        : [],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Overview',
                                    style: TextStyle(
                                      color: _selectedVersion == 0 ? Colors.white : Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedVersion = 1),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedVersion == 1 ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _selectedVersion == 1
                                        ? [
                                            const BoxShadow(
                                              color: Color(0x33FF5500),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            )
                                          ]
                                        : [],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Settings & Security',
                                    style: TextStyle(
                                      color: _selectedVersion == 1 ? Colors.white : Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- 4. VERSION CONTENT ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _selectedVersion == 0 ? _buildOverviewVersion(empId, email, phone, dept) : _buildSettingsVersion(),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewVersion(String empId, String email, String phone, String dept) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Details',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _ProfileDetailRow(icon: Icons.badge_outlined, label: 'Employee ID', value: empId),
              const Divider(height: 22),
              _ProfileDetailRow(icon: Icons.email_outlined, label: 'Email', value: email),
              const Divider(height: 22),
              _ProfileDetailRow(icon: Icons.phone_outlined, label: 'Phone', value: phone),
              const Divider(height: 22),
              _ProfileDetailRow(icon: Icons.corporate_fare_outlined, label: 'Department', value: dept),
              const Divider(height: 22),
              const _ProfileDetailRow(icon: Icons.calendar_today_outlined, label: 'Member Since', value: '15 Jan 2024'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Role & Permissions',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: const [
              _PermissionRow(title: 'Submit Expense Claims', subtitle: 'Submit new expenses for approval', isEnabled: true),
              Divider(height: 22),
              _PermissionRow(title: 'Request Budget Increase', subtitle: 'Submit request for additional funds', isEnabled: true),
              Divider(height: 22),
              _PermissionRow(title: 'View Expense Reports', subtitle: 'Access personal expense history', isEnabled: true),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            onPressed: _handleLogout,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showChangePasswordModal(BuildContext context) {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool showOld = false;
    bool showNew = false;
    bool showConfirm = false;
    bool isUpdating = false;
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter your current password and choose a new secure password.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  if (errorText != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorText!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: oldPasswordCtrl,
                    obscureText: !showOld,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(showOld ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setModalState(() => showOld = !showOld),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: newPasswordCtrl,
                    obscureText: !showNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_reset, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(showNew ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setModalState(() => showNew = !showNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: confirmPasswordCtrl,
                    obscureText: !showConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(showConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setModalState(() => showConfirm = !showConfirm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isUpdating
                          ? null
                          : () async {
                              final oldPass = oldPasswordCtrl.text.trim();
                              final newPass = newPasswordCtrl.text.trim();
                              final confirmPass = confirmPasswordCtrl.text.trim();

                              if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                                setModalState(() => errorText = 'Please fill in all password fields.');
                                return;
                              }
                              if (newPass.length < 6) {
                                setModalState(() => errorText = 'New password must be at least 6 characters.');
                                return;
                              }
                              if (newPass != confirmPass) {
                                setModalState(() => errorText = 'New password and confirmation do not match.');
                                return;
                              }

                              setModalState(() {
                                isUpdating = true;
                                errorText = null;
                              });

                              final success = await AuthService.changePassword(
                                oldPassword: oldPass,
                                newPassword: newPass,
                              );

                              setModalState(() => isUpdating = false);

                              if (success) {
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Password updated successfully!'),
                                      backgroundColor: AppColors.approvedGreen,
                                    ),
                                  );
                                }
                              } else {
                                setModalState(() => errorText = 'Incorrect current password. Please try again.');
                              }
                            },
                      child: isUpdating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Update Password',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsVersion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Settings',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                title: const Text('Change Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _showChangePasswordModal(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_none_outlined, color: AppColors.primary),
                title: const Text('Notification Preferences', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Sign Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                onTap: () async {
                  await AuthService.logout();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isEnabled;

  const _PermissionRow({
    required this.title,
    required this.subtitle,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        Icon(
          isEnabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isEnabled ? Colors.green : Colors.grey,
          size: 20,
        ),
      ],
    );
  }
}
