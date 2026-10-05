import 'package:flutter/material.dart';
import '../../../core/constants/business_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/widgets/icons/app_icons.dart';
import '../../widgets/common/glass_card.dart';
import '../dashboard/dashboard_screen.dart';

class StoreSetupScreen extends StatefulWidget {
  final BusinessType businessType;
  const StoreSetupScreen({super.key, required this.businessType});

  @override
  State<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen> {
  final _storeNameController = TextEditingController(text: 'মা ভাবানী স্টোর');
  final _addressController = TextEditingController(text: '১২৩, মেন রোড');
  final _phoneController = TextEditingController(text: '98XXXX XXXX');
  final _gstinController = TextEditingController(text: '19XXXXXXXX1Z5');

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = BusinessConfig.of(widget.businessType);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
              Container(
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
                    value: _storeNameController.text,
                  ),
                  _FormItem(
                    icon: Icons.location_on_outlined,
                    label: 'ঠিকানা *',
                    value: _addressController.text,
                  ),
                  _FormItem(
                    icon: Icons.phone_outlined,
                    label: 'ফোন *',
                    value: _phoneController.text,
                  ),
                  _FormItem(
                    icon: Icons.bar_chart_outlined,
                    label: 'GSTIN',
                    value: _gstinController.text,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Complete Setup Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => DashboardScreen(
                          businessType: widget.businessType,
                        ),
                      ),
                    );
                  },
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
                  child: const Text(
                    'সেটআপ সম্পূর্ণ করুন',
                    style: TextStyle(
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
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: iconColor, size: 18),
                    ),
                    title: Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Text(
                      item.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: AppTheme.muted,
                      ),
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
  final String value;

  _FormItem({required this.icon, required this.label, required this.value});
}
