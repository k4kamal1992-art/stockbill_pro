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

/// Collects the shop details.
///
/// * [isOnboarding] = true (first run): saves the main store info, marks
///   onboarding as done and continues to the PIN screen.
/// * [isOnboarding] = false (from "Add Shop"): creates an additional shop and
///   goes back, without touching the main store info.
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
    if (!_formKey.currentState!.validate()) return;

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
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              title: const Text('নতুন দোকান'),
              backgroundColor: AppTheme.background,
              elevation: 0,
            ),
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
                if (widget.isOnboarding) ...[
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
                ],
                // Business type banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    gradient: config.gradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.storefront_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        config.labelBn,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 16,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'BASIC INFO',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF34C759),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _field(
                        icon: Icons.home_outlined,
                        label: 'দোকানের নাম *',
                        controller: _storeNameController,
                        capitalization: TextCapitalization.words,
                        action: TextInputAction.next,
                        validator: (v) =>
                            _validateRequired(v, 'দোকানের নাম দিন'),
                      ),
                      _divider(),
                      _field(
                        icon: Icons.location_on_outlined,
                        label: 'ঠিকানা *',
                        controller: _addressController,
                        capitalization: TextCapitalization.sentences,
                        action: TextInputAction.next,
                        validator: (v) => _validateRequired(v, 'ঠিকানা দিন'),
                      ),
                      _divider(),
                      _field(
                        icon: Icons.phone_outlined,
                        label: 'ফোন *',
                        controller: _phoneController,
                        keyboard: TextInputType.phone,
                        action: TextInputAction.next,
                        formatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                          LengthLimitingTextInputFormatter(14),
                        ],
                        validator: _validatePhone,
                      ),
                      _divider(),
                      _field(
                        icon: Icons.bar_chart_outlined,
                        label: 'GSTIN (ঐচ্ছিক)',
                        controller: _gstinController,
                        capitalization: TextCapitalization.characters,
                        action: TextInputAction.done,
                        formatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9a-zA-Z]')),
                          LengthLimitingTextInputFormatter(15),
                        ],
                        validator: _validateGstin,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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

  Widget _divider() =>
      Divider(height: 1, indent: 64, color: Colors.grey[200]);

  Widget _field({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboard,
    TextInputAction? action,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0x1A34C759),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF34C759), size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboard,
              textInputAction: action,
              textCapitalization: capitalization,
              inputFormatters: formatters,
              validator: validator,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
