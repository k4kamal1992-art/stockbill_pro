import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/business_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/gst_service.dart';
import '../../../data/services/pin_service.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/theme_provider.dart';
import '../backup/backup_restore_screen.dart';
import '../customer/customer_list_screen.dart';
import '../customer/due_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../expense/expense_list_screen.dart';
import '../printer/printer_setup_screen.dart';
import '../reports/reports_screen.dart';
import '../return/return_screen.dart';
import '../scanner/barcode_scanner_screen.dart';
import '../shop/shop_list_screen.dart';
import '../staff/staff_list_screen.dart';
import '../supplier/supplier_list_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _prefNotifications = 'notifications_enabled';
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _notifications = prefs.getBool(_prefNotifications) ?? true);
    }
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notifications = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefNotifications, value);
  }

  BusinessType get _type => context.read<BusinessProvider>().currentBusiness;

  Future<void> _exportGstr1() async {
    final business = context.read<BusinessProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final json = await GSTService().exportGSTR1Json(
        month: DateTime.now(),
        gstin: business.gstin,
        shopName: business.storeName,
      );
      await Share.share(
        json,
        subject: 'GSTR-1 ${DateTime.now().month}/${DateTime.now().year}',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('GST এক্সপোর্ট ব্যর্থ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : const Color(0xFF34C759),
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────

  Future<void> _editStoreProfile({bool gstinOnly = false}) async {
    final business = context.read<BusinessProvider>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _StoreProfileDialog(business: business, gstinOnly: gstinOnly),
    );
    if (saved == true && mounted) {
      _snack(gstinOnly ? 'GSTIN সেভ হয়েছে' : 'দোকানের তথ্য সেভ হয়েছে');
    }
  }

  Future<void> _changeBusinessType() async {
    final business = context.read<BusinessProvider>();
    final picked = await showDialog<BusinessType>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('ব্যবসার ধরন'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'প্রতিটি ব্যবসার পণ্য ও বিল আলাদা থাকে। ধরন বদলালে ওই ধরনের পণ্য দেখাবে।',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          for (final type in BusinessType.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(type),
              child: Row(
                children: [
                  Icon(
                    type == business.currentBusiness
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: BusinessConfig.of(type).primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(BusinessConfig.of(type).labelBn),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null || picked == business.currentBusiness) return;
    await business.setBusinessType(picked);
    if (!mounted) return;
    // Rebuild the whole app flow for the new business type
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => DashboardScreen(businessType: picked)),
      (route) => false,
    );
  }

  Future<void> _pickLanguage() async {
    final language = context.read<LanguageProvider>();
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('ভাষা'),
        children: [
          for (final name in AppConstants.languages)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(name),
              child: Row(
                children: [
                  Icon(
                    name == language.currentLanguage
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(name),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked != null) {
      await language.setLanguage(picked);
    }
  }

  Future<void> _changePin() async {
    final hasPin = await PinService.hasPin();
    if (!mounted) return;
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _ChangePinDialog(hasPin: hasPin),
    );
    if (changed == true && mounted) _snack('PIN পরিবর্তন হয়েছে');
  }

  void _openScanner() {
    _push(BarcodeScannerScreen(
      businessType: context.read<BusinessProvider>().currentBusiness,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'অ্যাপ',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'সেটিংস',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 32,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ব্যবসা Section
            _buildSectionTitle('ব্যবসা'),
            SliverToBoxAdapter(
              child: _buildSettingsCard([
                _SettingsItem(
                  icon: Icons.store_outlined,
                  iconColor: const Color(0xFF007AFF),
                  iconBg: const Color(0x1A007AFF),
                  title: 'দোকানের প্রোফাইল',
                  trailing: _buildArrow(),
                  onTap: () => _editStoreProfile(),
                ),
                _SettingsItem(
                  icon: Icons.business_outlined,
                  iconColor: const Color(0xFF34C759),
                  iconBg: const Color(0x1A34C759),
                  title: 'ব্যবসার ধরন পরিবর্তন',
                  trailing: _buildArrow(),
                  onTap: _changeBusinessType,
                ),
                _SettingsItem(
                  icon: Icons.receipt_long_outlined,
                  iconColor: const Color(0xFFFF9500),
                  iconBg: const Color(0x1AFF9500),
                  title: 'GST / Tax সেটআপ',
                  trailing: _buildArrow(),
                  onTap: () => _editStoreProfile(gstinOnly: true),
                ),
              ]),
            ),
            // ম্যানেজমেন্ট Section (reports, customers, ...)
            _buildSectionTitle('ম্যানেজমেন্ট'),
            SliverToBoxAdapter(
              child: _buildSettingsCard([
                _SettingsItem(
                  icon: Icons.people_alt_outlined,
                  iconColor: const Color(0xFF007AFF),
                  iconBg: const Color(0x1A007AFF),
                  title: 'গ্রাহক',
                  trailing: _buildArrow(),
                  onTap: () => _push(CustomerListScreen(businessType: _type)),
                ),
                _SettingsItem(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFFFF3B30),
                  iconBg: const Color(0x1AFF3B30),
                  title: 'বাকির তালিকা',
                  trailing: _buildArrow(),
                  onTap: () => _push(DueListScreen(businessType: _type)),
                ),
                _SettingsItem(
                  icon: Icons.assignment_return_outlined,
                  iconColor: const Color(0xFFFF9500),
                  iconBg: const Color(0x1AFF9500),
                  title: 'রিটার্ন',
                  trailing: _buildArrow(),
                  onTap: () => _push(ReturnScreen(businessType: _type)),
                ),
                _SettingsItem(
                  icon: Icons.bar_chart_outlined,
                  iconColor: const Color(0xFF34C759),
                  iconBg: const Color(0x1A34C759),
                  title: 'রিপোর্ট',
                  trailing: _buildArrow(),
                  onTap: () => _push(ReportsScreen(businessType: _type)),
                ),
                _SettingsItem(
                  icon: Icons.local_shipping_outlined,
                  iconColor: const Color(0xFF5AC8FA),
                  iconBg: const Color(0x1A5AC8FA),
                  title: 'সাপ্লায়ার',
                  trailing: _buildArrow(),
                  onTap: () => _push(const SupplierListScreen()),
                ),
                _SettingsItem(
                  icon: Icons.payments_outlined,
                  iconColor: const Color(0xFFAF52DE),
                  iconBg: const Color(0x1AAF52DE),
                  title: 'খরচ',
                  trailing: _buildArrow(),
                  onTap: () => _push(const ExpenseListScreen()),
                ),
                _SettingsItem(
                  icon: Icons.storefront_outlined,
                  iconColor: const Color(0xFF007AFF),
                  iconBg: const Color(0x1A007AFF),
                  title: 'আমার দোকানসমূহ',
                  trailing: _buildArrow(),
                  onTap: () => _push(const ShopListScreen()),
                ),
                _SettingsItem(
                  icon: Icons.file_upload_outlined,
                  iconColor: const Color(0xFFFF9500),
                  iconBg: const Color(0x1AFF9500),
                  title: 'GSTR-1 এক্সপোর্ট',
                  trailing: _buildArrow(),
                  onTap: _exportGstr1,
                ),
              ]),
            ),
            // হার্ডওয়্যার Section
            _buildSectionTitle('হার্ডওয়্যার'),
            SliverToBoxAdapter(
              child: _buildSettingsCard([
                _SettingsItem(
                  icon: Icons.print_outlined,
                  iconColor: const Color(0xFFAF52DE),
                  iconBg: const Color(0x1AAF52DE),
                  title: 'প্রিন্টার সেটআপ',
                  trailing: _buildArrow(),
                  onTap: () => _push(const PrinterSetupScreen()),
                ),
                _SettingsItem(
                  icon: Icons.qr_code_scanner,
                  iconColor: const Color(0xFF5AC8FA),
                  iconBg: const Color(0x1A5AC8FA),
                  title: 'বারকোড স্ক্যানার',
                  trailing: _buildArrow(),
                  onTap: _openScanner,
                ),
              ]),
            ),
            // ডেটা & সুরক্ষা Section
            _buildSectionTitle('ডেটা & সুরক্ষা'),
            SliverToBoxAdapter(
              child: _buildSettingsCard([
                _SettingsItem(
                  icon: Icons.backup_outlined,
                  iconColor: const Color(0xFF007AFF),
                  iconBg: const Color(0x1A007AFF),
                  title: 'ব্যাকআপ & রিস্টোর',
                  trailing: _buildArrow(),
                  onTap: () => _push(const BackupRestoreScreen()),
                ),
                _SettingsItem(
                  icon: Icons.people_outline,
                  iconColor: const Color(0xFF34C759),
                  iconBg: const Color(0x1A34C759),
                  title: 'ব্যবহারকারী',
                  trailing: _buildArrow(),
                  onTap: () => _push(const StaffListScreen()),
                ),
                _SettingsItem(
                  icon: Icons.lock_outline,
                  iconColor: const Color(0xFFFF3B30),
                  iconBg: const Color(0x1AFF3B30),
                  title: 'PIN পরিবর্তন',
                  trailing: _buildArrow(),
                  onTap: _changePin,
                ),
              ]),
            ),
            // অ্যাপ Section
            _buildSectionTitle('অ্যাপ'),
            SliverToBoxAdapter(
              child: _buildSettingsCard([
                _SettingsItem(
                  icon: Icons.language,
                  iconColor: const Color(0xFF007AFF),
                  iconBg: const Color(0x1A007AFF),
                  title: 'ভাষা',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        language.currentLanguage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: AppTheme.muted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildArrow(),
                    ],
                  ),
                  onTap: _pickLanguage,
                ),
                _SettingsItem(
                  icon: Icons.dark_mode_outlined,
                  iconColor: const Color(0xFFAF52DE),
                  iconBg: const Color(0x1AAF52DE),
                  title: 'ডার্ক মোড',
                  trailing: _buildToggle(theme.isDarkMode, (_) => theme.toggleDarkMode()),
                  onTap: () => theme.toggleDarkMode(),
                ),
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  iconColor: const Color(0xFFFF3B30),
                  iconBg: const Color(0x1AFF3B30),
                  title: 'নোটিফিকেশন',
                  trailing: _buildToggle(_notifications, _setNotifications),
                  onTap: () => _setNotifications(!_notifications),
                ),
              ]),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.muted,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<_SettingsItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                onTap: item.onTap,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 20),
                ),
                title: Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: item.trailing,
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
    );
  }

  Widget _buildArrow() {
    return Icon(
      Icons.arrow_forward_ios,
      size: 14,
      color: Colors.grey[400],
    );
  }

  Widget _buildToggle(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: value ? const Color(0xFF34C759) : const Color(0x338E8E93),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.trailing,
    this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────
// Edit shop details / GSTIN
// ─────────────────────────────────────────────────────────────
class _StoreProfileDialog extends StatefulWidget {
  final BusinessProvider business;
  final bool gstinOnly;
  const _StoreProfileDialog({required this.business, this.gstinOnly = false});

  @override
  State<_StoreProfileDialog> createState() => _StoreProfileDialogState();
}

class _StoreProfileDialogState extends State<_StoreProfileDialog> {
  static final RegExp _gstinRegex =
      RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _gstin;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.business.storeName);
    _address = TextEditingController(text: widget.business.storeAddress);
    _phone = TextEditingController(text: widget.business.storePhone);
    _gstin = TextEditingController(text: widget.business.gstin);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _gstin.dispose();
    super.dispose();
  }

  String? _required(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  String? _validatePhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final number = (digits.length == 12 && digits.startsWith('91'))
        ? digits.substring(2)
        : digits;
    return number.length == 10 ? null : '১০ digit এর ফোন নম্বর দিন';
  }

  String? _validateGstin(String? v) {
    final value = (v ?? '').trim().toUpperCase();
    if (value.isEmpty) return null;
    return _gstinRegex.hasMatch(value)
        ? null
        : 'GSTIN ঠিক নয় (১৫ অক্ষর, যেমন 19ABCDE1234F1Z5)';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    if (widget.gstinOnly) {
      await widget.business.setStoreInfo(gstin: _gstin.text.trim().toUpperCase());
    } else {
      await widget.business.setStoreInfo(
        name: _name.text.trim(),
        address: _address.text.trim(),
        phone: _phone.text.trim(),
        gstin: _gstin.text.trim().toUpperCase(),
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.gstinOnly ? 'GST / Tax সেটআপ' : 'দোকানের প্রোফাইল'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.gstinOnly) ...[
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'দোকানের নাম *'),
                  validator: (v) => _required(v, 'দোকানের নাম দিন'),
                ),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'ঠিকানা *'),
                  validator: (v) => _required(v, 'ঠিকানা দিন'),
                ),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                    LengthLimitingTextInputFormatter(14),
                  ],
                  decoration: const InputDecoration(labelText: 'ফোন *'),
                  validator: _validatePhone,
                ),
              ],
              TextFormField(
                controller: _gstin,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
                  LengthLimitingTextInputFormatter(15),
                ],
                decoration: const InputDecoration(
                  labelText: 'GSTIN (ঐচ্ছিক)',
                  helperText: 'বিলে ও GSTR-1 এক্সপোর্টে ব্যবহার হবে',
                ),
                validator: _validateGstin,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('বাতিল'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: const Text('সেভ'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Change PIN
// ─────────────────────────────────────────────────────────────
class _ChangePinDialog extends StatefulWidget {
  final bool hasPin;
  const _ChangePinDialog({required this.hasPin});

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _currentError;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validatePin(String? v) =>
      (v == null || v.length != 4) ? '৪ সংখ্যার PIN দিন' : null;

  Future<void> _save() async {
    setState(() => _currentError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    if (widget.hasPin && !await PinService.verify(_current.text)) {
      if (mounted) {
        setState(() {
          _saving = false;
          _currentError = 'বর্তমান PIN ভুল';
        });
      }
      return;
    }
    await PinService.setPin(_new.text);
    if (mounted) Navigator.of(context).pop(true);
  }

  Widget _pinField(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    String? errorText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      decoration: InputDecoration(labelText: label, errorText: errorText),
      validator: validator ?? _validatePin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.hasPin ? 'PIN পরিবর্তন' : 'নতুন PIN সেট করুন'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.hasPin)
              _pinField(_current, 'বর্তমান PIN', errorText: _currentError),
            _pinField(_new, 'নতুন PIN (৪ সংখ্যা)'),
            _pinField(
              _confirm,
              'নতুন PIN আবার দিন',
              validator: (v) {
                if (v == null || v.length != 4) return '৪ সংখ্যার PIN দিন';
                if (v != _new.text) return 'PIN মেলেনি';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('বাতিল'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: const Text('সেভ'),
        ),
      ],
    );
  }
}

