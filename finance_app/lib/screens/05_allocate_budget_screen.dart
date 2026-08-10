import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header_icon_button.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '03_dashboard_screen.dart';

class AllocateBudgetScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const AllocateBudgetScreen({super.key, this.onBackPressed});

  @override
  State<AllocateBudgetScreen> createState() => _AllocateBudgetScreenState();
}

class _AllocateBudgetScreenState extends State<AllocateBudgetScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  int? _selectedEmployeeId;
  List<UserModel> _users = [];
  bool _isAllocating = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await ApiService.getUsers();
    if (mounted) {
      setState(() {
        _users = users;
        if (_users.isNotEmpty) {
          if (_selectedEmployeeId == null || !_users.any((u) => u.id == _selectedEmployeeId)) {
            _selectedEmployeeId = _users.first.id;
          }
        } else {
          _selectedEmployeeId = null;
        }
      });
    }
  }

  UserModel? get _selectedUser {
    if (_selectedEmployeeId == null || _users.isEmpty) return null;
    final idx = _users.indexWhere((u) => u.id == _selectedEmployeeId);
    return idx != -1 ? _users[idx] : null;
  }

  Future<void> _handleAllocate() async {
    if (_selectedEmployeeId == null || _amountController.text.isEmpty) return;

    setState(() => _isAllocating = true);
    final amt = double.tryParse(_amountController.text) ?? 0.0;
    final targetEmpId = _selectedEmployeeId!;
    final success = await ApiService.allocateBudget(
      employeeId: targetEmpId,
      amount: amt,
      note: _noteController.text.trim(),
      isAddition: true,
    );

    await _loadUsers();
    _amountController.clear();
    _noteController.clear();

    if (mounted) {
      setState(() {
        _selectedEmployeeId = targetEmpId;
        _isAllocating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Budget allocated successfully!' : 'Failed to allocate budget'),
          backgroundColor: success ? AppColors.approvedGreen : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Top Bar Header (Back Button, Extra Bold Title)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppHeaderIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () {
                      if (widget.onBackPressed != null) {
                        widget.onBackPressed!();
                      } else if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const FounderDashboardScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                  const Text(
                    'Allocate Budget',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Wallet Illustration Circle & Subtitle
              Center(
                child: Column(
                  children: [
                    const WalletIllustrationWidget(size: 140),
                    const SizedBox(height: 20),
                    const Text(
                      'Allocate budget to employee',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 3. Form Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Employee',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  () {
                    final rawUsers = _users;
                    final Map<int, UserModel> uniqueUserMap = {};
                    for (final u in rawUsers) {
                      uniqueUserMap.putIfAbsent(u.id, () => u);
                    }
                    final userList = uniqueUserMap.values.toList();
                    final effVal = (userList.any((u) => u.id == _selectedEmployeeId))
                        ? _selectedEmployeeId
                        : (userList.isNotEmpty ? userList.first.id : null);

                    return DropdownButtonFormField<int>(
                      value: effVal,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1F2937)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      items: userList
                          .map((u) => DropdownMenuItem(
                                value: u.id,
                                child: Text(
                                  '${u.fullName} (${u.role})',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedEmployeeId = val;
                          });
                        }
                      },
                    );
                  }(),
                  const SizedBox(height: 20),

                  // Dynamic Current Balance Card
                  _buildCurrentBalanceCard(),
                  const SizedBox(height: 20),

                  // Amount Input
                  CustomTextField(
                    label: 'Amount to Allocate (₹)',
                    hint: 'Enter amount',
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 14),

                  // Note Input
                  CustomTextField(
                    label: 'Note (Optional)',
                    hint: 'Enter a note',
                    controller: _noteController,
                  ),
                  const SizedBox(height: 24),

                  // Action Button
                  CustomButton(
                    text: 'Allocate',
                    onPressed: _handleAllocate,
                    isLoading: _isAllocating,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBalanceCard() {
    final u = _selectedUser;
    final allocated = u?.allocatedAmount ?? 0.0;
    final remaining = u?.remainingAmount ?? 0.0;
    final isNegative = remaining < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNegative ? const Color(0xFFFEF2F2) : const Color(0xFFFFF5ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNegative ? const Color(0xFFFCA5A5) : const Color(0xFFFFD4C0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Allocated (${u?.fullName.isNotEmpty == true ? u!.fullName : 'Selected Employee'})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isNegative ? const Color(0xFF991B1B) : Colors.grey.shade700,
                ),
              ),
              if (isNegative)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Over Budget by ₹${remaining.abs().toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${allocated.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Remaining: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    isNegative ? '- ₹${remaining.abs().toStringAsFixed(0)}' : '₹${remaining.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isNegative ? Colors.redAccent : AppColors.approvedGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WalletIllustrationWidget extends StatelessWidget {
  final double size;

  const WalletIllustrationWidget({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WalletPainter(),
      ),
    );
  }
}

class _WalletPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Soft Peach Background Circle
    final bgPaint = Paint()
      ..color = const Color(0xFFFFF0E5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Save state for angled wallet
    canvas.save();
    canvas.translate(center.dx - 10, center.dy + 4);
    canvas.rotate(-0.12); // Tilted angle matching image

    // 2. Card Sticking out of wallet top
    final cardPaint = Paint()
      ..color = const Color(0xFFFFD4C0)
      ..style = PaintingStyle.fill;
    final cardRRect = RRect.fromRectAndRadius(
      const Rect.fromLTRB(-35, -38, 15, -10),
      const Radius.circular(6),
    );
    canvas.drawRRect(cardRRect, cardPaint);

    // 3. Main Orange Wallet Body
    final walletPaint = Paint()
      ..color = const Color(0xFFFF5500)
      ..style = PaintingStyle.fill;
    final walletRRect = RRect.fromRectAndRadius(
      const Rect.fromLTRB(-45, -20, 35, 28),
      const Radius.circular(10),
    );
    canvas.drawRRect(walletRRect, walletPaint);

    // 4. Dark Grey Flap / Compartment
    final flapPaint = Paint()
      ..color = const Color(0xFF374151)
      ..style = PaintingStyle.fill;
    final flapRRect = RRect.fromRectAndRadius(
      const Rect.fromLTRB(0, -20, 35, 8),
      const Radius.circular(8),
    );
    canvas.drawRRect(flapRRect, flapPaint);

    // 5. Clasp tab & Button
    final claspPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;
    final claspRRect = RRect.fromRectAndRadius(
      const Rect.fromLTRB(-4, -10, 10, 2),
      const Radius.circular(4),
    );
    canvas.drawRRect(claspRRect, claspPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFFFDE047)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(3, -4), 2.5, dotPaint);

    canvas.restore(); // Restore angle transform

    // 6. Top Right Golden Coin
    final coinPaint1 = Paint()
      ..color = const Color(0xFFFFB800)
      ..style = PaintingStyle.fill;
    final coinBorderPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final coin1Center = Offset(size.width * 0.76, size.height * 0.32);
    canvas.drawCircle(coin1Center, 13, coinPaint1);
    canvas.drawCircle(coin1Center, 10, coinBorderPaint);

    // 7. Bottom Right Golden Coin
    final coin2Center = Offset(size.width * 0.74, size.height * 0.62);
    canvas.drawCircle(coin2Center, 14, coinPaint1);
    canvas.drawCircle(coin2Center, 11, coinBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


