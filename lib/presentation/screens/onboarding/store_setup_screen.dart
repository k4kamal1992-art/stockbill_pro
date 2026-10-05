import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/business_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/shop_model.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/shop_provider.dart';
import 'pin_login_screen.dart';

class StoreSetupScreen extends StatefulWidget {
  final BusinessType businessType;
  final bool isOnboarding;
  const StoreSetupScreen({
    super.key,
    required this.businessType,
    this.isOnboarding = true,
  });

  @override
  State<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen> {
  static final RegExp _gstinRegex =
      RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');

  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstinController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? v, String message) =>
      (v == null || v.trim().isEmpty) ? message : null;

  String? _validatePhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    // allow a leading 91 country code
    final number = (digits.length == 12 && digits.startsWith('91'))
        ? digits.substring(2)
        : digits;
    if (number.length != 10) return '১০ digit এর ফোন নম্বর দিন';
    return null;
  }

  String? _validateGstin(String? v) {
    final value = (v ?? '').trim().toUpperCase();
    if (value.isEmpty) return null; // optional
    if (!_gstinRegex.hasMatch(value)) {
      return 'GSTIN ঠিক নয় (১৫ অক্ষর, যেমন 19ABCDE1234F1Z5)';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('লাল লেখার ঘরগুলো ঠিক করে আবার চাপুন'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final business = context.read<BusinessProvider>();
    final shops = context.read<ShopProvider>();

    final name = _storeNameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    final gstin = _gstinController.text.trim().toUpperCase();

    setState(() => _saving = true);
    try {
      if (widget.isOnboarding) {
        await business.setBusinessType(widget.businessType);
        await business.setStoreInfo(
          name: name,
          address: address,
          phone: phone,
          gstin: gstin,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.prefOnboardingComplete, true);
        if (!mounted) return;
        // First run: the PIN screen starts in "set a new PIN" mode.
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const PinLoginScreen()),
        );
      } else {
        await shops.createShop(
          ShopModel(
            id: const Uuid().v4(),
            name: name,
            address: address,
            phone: phone,
            gstin: gstin.isEmpty ? null : gstin,
            businessType: widget.businessType.name,
            createdAt: DateTime.now(),
          ),
        );
        if (!mounted) return;
        navigator.pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('সেভ করা যায়নি: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = BusinessConfig.of(widget.businessType);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'সেটআপ',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.muted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'দোকানের তথ্য',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 30,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                // Logo Upload Area
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('লোগো আপলোড শীঘ্রই আসছে')),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      gradient: config.gradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'লোগো আপলোড করুন',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SVG, PNG (max 2MB)',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Form Fields
                _buildFormSection(
                  title: 'Basic Info',
                  iconColor: const Color(0xFF34C759),
                  iconBgColor: const Color(0x1A34C759),
                  items: [
                    _FormItem(
                      icon: Icons.home_outlined,
                      label: 'দোকানের নাম *',
                      hint: 'নাম লিখুন',
                      controller: _storeNameController,
                      validator: (v) => _validateRequired(v, 'দোকানের নাম দিন'),
                      capitalization: TextCapitalization.words,
                    ),
                    _FormItem(
                      icon: Icons.location_on_outlined,
                      label: 'ঠিকানা *',
                      hint: 'ঠিকানা লিখুন',
                      controller: _addressController,
                      validator: (v) => _validateRequired(v, 'ঠিকানা দিন'),
                      capitalization: TextCapitalization.sentences,
                    ),
                    _FormItem(
                      icon: Icons.phone_outlined,
                      label: 'ফোন *',
                      hint: '১০ digit',
                      controller: _phoneController,
                      validator: _validatePhone,
                      keyboard: TextInputType.phone,
                      formatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                        LengthLimitingTextInputFormatter(14),
                      ],
                    ),
                    _FormItem(
                      icon: Icons.bar_chart_outlined,
                      label: 'GSTIN',
                      hint: 'ঐচ্ছিক',
                      controller: _gstinController,
                      validator: _validateGstin,
                      capitalization: TextCapitalization.characters,
                      formatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
                        LengthLimitingTextInputFormatter(15),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Complete Setup Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: config.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: config.primary.withOpacity(0.4),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.isOnboarding
                                ? 'সেটআপ সম্পূর্ণ করুন'
                                : 'দোকান যোগ করুন',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required Color iconColor,
    required Color iconBgColor,
    required List<_FormItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: iconColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  // Same look as the original ListTile rows: icon, label on
                  // the left, value on the right - but the value is editable.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item.icon, color: iconColor, size: 18),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Padding(
                          padding: const EdgeInsets.only(top: 17),
                          child: Text(
                            item.label,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: item.controller,
                            keyboardType: item.keyboard,
                            textCapitalization: item.capitalization,
                            inputFormatters: item.formatters,
                            validator: item.validator,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: AppTheme.muted,
                            ),
                            decoration: InputDecoration(
                              hintText: item.hint,
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              filled: false,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 18),
                              errorStyle: const TextStyle(fontSize: 11),
                              errorMaxLines: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 64,
                      color: Colors.grey[200],
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _FormItem {
  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final TextInputType? keyboard;
  final TextCapitalization capitalization;
  final List<TextInputFormatter>? formatters;

  _FormItem({
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    this.keyboard,
    this.capitalization = TextCapitalization.none,
    this.formatters,
  });
}
