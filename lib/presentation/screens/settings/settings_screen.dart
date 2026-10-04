import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../backup/backup_restore_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  String _language = 'বাংলা';

  @override
  Widget build(BuildContext context) {
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
                ),
                _SettingsItem(
                  icon: Icons.business_outlined,
                  iconColor: const Color(0xFF34C759),
                  iconBg: const Color(0x1A34C759),
                  title: 'ব্যবসার ধরন পরিবর্তন',
                  trailing: _buildArrow(),
                ),
                _SettingsItem(
                  icon: Icons.receipt_long_outlined,
                  iconColor: const Color(0xFFFF9500),
                  iconBg: const Color(0x1AFF9500),
                  title: 'GST / Tax সেটআপ',
                  trailing: _buildArrow(),
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
                ),
                _SettingsItem(
                  icon: Icons.qr_code_scanner,
                  iconColor: const Color(0xFF5AC8FA),
                  iconBg: const Color(0x1A5AC8FA),
                  title: 'বারকোড স্ক্যানার',
                  trailing: _buildArrow(),
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
                ),
                _SettingsItem(
                  icon: Icons.people_outline,
                  iconColor: const Color(0xFF34C759),
                  iconBg: const Color(0x1A34C759),
                  title: 'ব্যবহারকারী',
                  trailing: _buildArrow(),
                ),
                _SettingsItem(
                  icon: Icons.lock_outline,
                  iconColor: const Color(0xFFFF3B30),
                  iconBg: const Color(0x1AFF3B30),
                  title: 'PIN পরিবর্তন',
                  trailing: _buildArrow(),
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
                        _language,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: AppTheme.muted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildArrow(),
                    ],
                  ),
                ),
                _SettingsItem(
                  icon: Icons.dark_mode_outlined,
                  iconColor: const Color(0xFFAF52DE),
                  iconBg: const Color(0x1AAF52DE),
                  title: 'ডার্ক মোড',
                  trailing: _buildToggle(_darkMode, (v) => setState(() => _darkMode = v)),
                ),
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  iconColor: const Color(0xFFFF3B30),
                  iconBg: const Color(0x1AFF3B30),
                  title: 'নোটিফিকেশন',
                  trailing: _buildToggle(_notifications, (v) => setState(() => _notifications = v)),
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

  _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.trailing,
  });
}
