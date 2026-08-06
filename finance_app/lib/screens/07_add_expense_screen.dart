import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header_icon_button.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '03_dashboard_screen.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();
  int? _selectedCategoryId = 1;
  List<CategoryModel> _categories = [];
  bool _isSaving = false;

  String? _receiptFilePath;
  String? _receiptFileName;

  final ImagePicker _imagePicker = ImagePicker();

  final List<CategoryModel> _fallbackCategories = [
    CategoryModel(id: 1, name: 'Software Tools', type: 'EXPENSE', icon: 'computer', color: '#8B5CF6'),
    CategoryModel(id: 2, name: 'AI Subscriptions', type: 'EXPENSE', icon: 'psychology', color: '#EC4899'),
    CategoryModel(id: 3, name: 'Purchase of Domain or Server', type: 'EXPENSE', icon: 'dns', color: '#2563EB'),
    CategoryModel(id: 4, name: 'Cloud Infrastructure & Hosting', type: 'EXPENSE', icon: 'cloud', color: '#0EA5E9'),
    CategoryModel(id: 5, name: 'API & Third-Party Services', type: 'EXPENSE', icon: 'api', color: '#10B981'),
    CategoryModel(id: 6, name: 'Hardware & Dev Peripherals', type: 'EXPENSE', icon: 'devices', color: '#6366F1'),
    CategoryModel(id: 7, name: 'Travel & Client Visits', type: 'EXPENSE', icon: 'directions_car', color: '#F59E0B'),
    CategoryModel(id: 8, name: 'Office Supplies & Utilities', type: 'EXPENSE', icon: 'shopping_bag', color: '#64748B'),
    CategoryModel(id: 9, name: 'Others', type: 'EXPENSE', icon: 'more_horiz', color: '#9CA3AF'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats.isNotEmpty ? cats : _fallbackCategories;
          if (_categories.isNotEmpty) _selectedCategoryId = _categories.first.id;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _categories = _fallbackCategories;
          _selectedCategoryId = 1;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(source: source, imageQuality: 85);
      if (photo != null && mounted) {
        setState(() {
          _receiptFilePath = photo.path;
          _receiptFileName = photo.name.isNotEmpty ? photo.name : 'Receipt_Photo.jpg';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attached "${_receiptFileName}"!'), backgroundColor: AppColors.approvedGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not pick photo. Try sample vouchers.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final XFile? media = await _imagePicker.pickMedia();
      if (media != null && mounted) {
        setState(() {
          _receiptFilePath = media.path;
          _receiptFileName = media.name.isNotEmpty ? media.name : 'Receipt_Document.png';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attached "${_receiptFileName}"!'), backgroundColor: AppColors.approvedGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not pick file. Try sample vouchers.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _showReceiptPickerModal() {
    final presets = [
      {'name': 'Digital_Tax_Invoice.pdf', 'url': 'assets/images/bill_receipt.png'},
      {'name': 'Software_License_Receipt.png', 'url': 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=300'},
      {'name': 'Server_Hosting_Voucher.pdf', 'url': 'https://images.unsplash.com/photo-1554224154-26032ffc0d07?w=300'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upload Bill / Receipt',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 28),
                              SizedBox(height: 6),
                              Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.photo_library_rounded, color: Colors.blueAccent, size: 28),
                              SizedBox(height: 6),
                              Text('Photo Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickFile();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.purple.shade300),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.folder_open_rounded, color: Colors.purple, size: 28),
                              SizedBox(height: 6),
                              Text('Browse Files', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Or Select Sample Digital Receipt Voucher:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
                const SizedBox(height: 10),
                Column(
                  children: presets.map((p) {
                    final isSelected = _receiptFileName == p['name'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLight : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: Icon(
                          p['name']!.endsWith('.pdf') ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                          color: isSelected ? AppColors.primary : Colors.grey.shade600,
                        ),
                        title: Text(
                          p['name']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primary : const Color(0xFF1F2937),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                            : OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _receiptFileName = p['name'];
                                    _receiptFilePath = p['url'];
                                  });
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Attached "${p['name']}"!'), backgroundColor: AppColors.primary),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  side: const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Attach', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                              ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty || _selectedCategoryId == null) return;

    setState(() => _isSaving = true);
    final amt = double.tryParse(_amountController.text) ?? 1200.0;
    final dtStr = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(_selectedDateTime);

    await ApiService.createExpense(
      title: _titleController.text.trim(),
      amount: amt,
      categoryId: _selectedCategoryId!,
      description: _descriptionController.text.trim(),
      dateTime: dtStr,
      receiptPath: _receiptFilePath ?? 'assets/images/bill_receipt.png',
    );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully!'), backgroundColor: AppColors.approvedGreen),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawCategories = _categories.isNotEmpty ? _categories : _fallbackCategories;
    final Map<int, CategoryModel> uniqueCategoryMap = {};
    for (final c in rawCategories) {
      uniqueCategoryMap.putIfAbsent(c.id, () => c);
    }
    final categoryList = uniqueCategoryMap.values.toList();
    final effectiveSelectedId = (categoryList.any((c) => c.id == _selectedCategoryId))
        ? _selectedCategoryId
        : (categoryList.isNotEmpty ? categoryList.first.id : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: AppHeaderIconButton(
          icon: Icons.arrow_back,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const FounderDashboardScreen()),
              );
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Expense Title',
                hint: 'Enter Expense...',
                controller: _titleController,
              ),

              const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: effectiveSelectedId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  fillColor: Colors.white,
                  filled: true,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                items: categoryList.map((c) {
                  final isSelected = c.id == _selectedCategoryId;
                  return DropdownMenuItem<int>(
                    value: c.id,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLight : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? AppColors.primary : Colors.grey.shade400,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            c.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.primary : const Color(0xFF374151),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Enter Amount',
                hint: 'Enter amount (₹)',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),

              CustomTextField(
                label: 'Description',
                hint: 'Enter description...',
                controller: _descriptionController,
              ),

              const Text('Date & Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd MMM yyyy, hh:mm a').format(_selectedDateTime), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                      const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Upload Bill / Receipt', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
              const SizedBox(height: 8),
              _receiptFilePath == null
                  ? InkWell(
                      onTap: _showReceiptPickerModal,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withOpacity(0.4), style: BorderStyle.solid),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Click to Upload Voucher / Bill',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'PDF, PNG, or JPG formats supported',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.approvedGreen, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.approvedGreen.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.approvedGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: AppColors.approvedGreen, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _receiptFileName ?? 'Attached_Receipt.pdf',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  '✓ Receipt File Attached Successfully',
                                  style: TextStyle(fontSize: 11, color: AppColors.approvedGreen, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _receiptFilePath = null;
                                _receiptFileName = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Attached receipt removed!'), backgroundColor: Colors.grey),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 28),

              CustomButton(
                text: 'Save Expense',
                onPressed: _handleSave,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
