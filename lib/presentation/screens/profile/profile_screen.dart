import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/business_config.dart';
import '../../../core/localization/localization.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/customer_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../customer/customer_list_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../return/return_screen.dart';
import '../backup/backup_restore_screen.dart';
import '../shop/shop_list_screen.dart';
import '../staff/staff_list_screen.dart';
import '../expense/expense_list_screen.dart';
import '../supplier/supplier_list_screen.dart';
import '../../../data/services/gst_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final BusinessType businessType;
  const ProfileScreen({super.key, required this.businessType});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadCustomerSummary();
  }

  Future<void> _loadCustomerSummary() async {
    await context.read<CustomerProvider>().loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    final config = BusinessConfig.of(widget.businessType);
    final business = context.watch<BusinessProvider>();
    final theme = context.watch<ThemeProvider>();
    final language = context.watch<LanguageProvider>();
    final customerProvider = context.watch<CustomerProvider>();

    final totalCustomers = customerProvider.customers.length;
    final totalDue = customerProvider.customers.fold<double>(
      0, (sum, c) => sum + c.dueAmount,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCustomerSummary,
          color: config.primary,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 8),
              // Profile header
              _buildProfileHeader(config, business),
              const SizedBox(height: 20),

              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'কাস্টমার',
                      totalCustomers.toString(),
                      const Color(0xFF007AFF),
                      Icons.people,
                      () => _navigateTo(const CustomerListScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'বাকি',
                      'INR ${totalDue.toStringAsFixed(0)}',
                      const Color(0xFFFF3B30),
                      Icons.account_balance_wallet,
                      () => _navigateTo(const CustomerListScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick actions
              _buildSectionHeader('দ্রুত অ্যাক্সেস', config.primary),
              _buildMenuCard(
                icon: Icons.receipt_long,
                iconColor: config.primary,
                title: 'রিপোর্টস',
                subtitle: 'বিক্রয় এবং স্টক রিপোর্ট দেখুন',
                onTap: () => _navigateTo(ReportsScreen(businessType: widget.businessType)),
              ),
              _buildMenuCard(
                icon: Icons.assignment_return,
                iconColor: const Color(0xFFFF3B30),
                title: 'রিটার্ন',
                subtitle: 'প্রোডাক্ট রিটার্ন প্রসেস করুন',
                onTap: () => _navigateTo(ReturnScreen(businessType: widget.businessType)),
              ),
              _buildMenuCard(
                icon: Icons.backup,
                iconColor: const Color(0xFF34C759),
                title: 'ব্যাকআপ এবং রিস্টোর',
                subtitle: 'ডেটা ব্যাকআপ ও রিস্টোর করুন',
                onTap: () => _navigateTo(const BackupRestoreScreen()),
              ),
              _buildMenuCard(
                icon: Icons.storefront,
                iconColor: const Color(0xFF5856D6),
                title: 'মাল্টি-শপ',
                subtitle: 'একাধিক দোকান ম্যানেজ করুন',
                onTap: () => _navigateTo(const ShopListScreen()),
              ),
              _buildMenuCard(
                icon: Icons.people,
                iconColor: const Color(0xFF007AFF),
                title: 'স্টাফ ম্যানেজমেন্ট',
                subtitle: 'স্টাফ এবং অনুমতি নিয়ন্ত্রণ',
                onTap: () => _navigateTo(const StaffListScreen()),
              ),
              _buildMenuCard(
                icon: Icons.account_balance_wallet,
                iconColor: const Color(0xFFFF9500),
                title: 'খরচে হিসাব',
                subtitle: 'দৈনিক খরচ ট্র্যাক করুন',
                onTap: () => _navigateTo(const ExpenseListScreen()),
              ),
              _buildMenuCard(
                icon: Icons.local_shipping,
                iconColor: const Color(0xFF34C759),
                title: 'সাপ্লায়ার',
                subtitle: 'সাপ্লায়ার এবং পেমেন্ট ট্র্যাকিং',
                onTap: () => _navigateTo(const SupplierListScreen()),
              ),
              _buildMenuCard(
                icon: Icons.description,
                iconColor: const Color(0xFFFF3B30),
                title: 'GST রিটার্ন ফাইলিং',
                subtitle: 'GSTR-1 JSON এক্সপোর্ট',
                onTap: () => _showGSTExportSheet(context),
              ),
              const SizedBox(height: 20),

              // Settings
              _buildSectionHeader('সেটিংস', const Color(0xFF8E8E93)),
              _buildMenuCard(
                icon: Icons.business,
                iconColor: config.primary,
                title: 'ব্যবসার তথ্য',
                subtitle: business.shopName.isEmpty ? 'সেটআপ করুন' : business.shopName,
                onTap: () => _navigateTo(const SettingsScreen()),
              ),
              _buildMenuCard(
                icon: Icons.language,
                iconColor: const Color(0xFF5856D6),
                title: 'ভাষা',
                subtitle: _getLanguageLabel(language.locale.languageCode),
                onTap: () => _showLanguagePicker(language),
              ),
              _buildMenuCard(
                icon: theme.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                iconColor: const Color(0xFFFF9500),
                title: 'থিম',
                subtitle: theme.isDarkMode ? 'ডার্ক মোড' : 'লাইট মোড',
                onTap: () => theme.toggleTheme(),
              ),
              _buildMenuCard(
                icon: Icons.settings,
                iconColor: const Color(0xFF8E8E93),
                title: 'আরও সেটিংস',
                subtitle: 'প্রিন্টার, শপ তথ্য, অন্যান্য',
                onTap: () => _navigateTo(const SettingsScreen()),
              ),
              const SizedBox(height: 32),

              // App info
              Center(
                child: Column(
                  children: [
                    Text(
                      'StockBill Pro',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: config.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v1.0.0 • Multi-Business Edition',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Built with Flutter',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BusinessConfig config, BusinessProvider business) {
    return GlassCard(
      borderColor: config.primary.withOpacity(0.2),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: config.cardGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                business.shopName.isNotEmpty ? business.shopName[0].toUpperCase() : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.shopName.isNotEmpty ? business.shopName : 'আপনার দোকান',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  business.ownerName.isNotEmpty ? business.ownerName : 'মালিকের নাম',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: config.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    config.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: config.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderColor: color.withOpacity(0.2),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderColor: iconColor.withOpacity(0.1),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [iconColor, iconColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  String _getLanguageLabel(String code) {
    switch (code) {
      case 'bn':
        return 'বাংলা';
      case 'hi':
        return 'हिंदी';
      case 'en':
        return 'English';
      default:
        return 'বাংলা';
    }
  }

  void _showLanguagePicker(LanguageProvider language) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ভাষা নির্বাচন করুন',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            _buildLanguageOption('বাংলা', 'bn', language),
            _buildLanguageOption('हिंदी', 'hi', language),
            _buildLanguageOption('English', 'en', language),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String label, String code, LanguageProvider language) {
    final isSelected = language.locale.languageCode == code;
    return GestureDetector(
      onTap: () {
        language.setLocale(code);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x1A007AFF) : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: const Color(0xFF007AFF), width: 1.5)
              : Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF007AFF) : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF007AFF), size: 22),
          ],
        ),
      ),
    );
  }
}
