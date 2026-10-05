import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/localization.dart';
import '../../../data/services/backup_service.dart';
import '../../widgets/common/glass_card.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final BackupService _backupService = BackupService();

  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _isLoadingStats = true;
  bool _isLoadingBackups = true;

  Map<String, int> _dbStats = {};
  List<BackupFileInfo> _backups = [];
  DateTime? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadStats(),
      _loadBackups(),
      _loadLastBackupDate(),
    ]);
  }

  Future<void> _loadStats() async {
    final stats = await _backupService.getDatabaseStats();
    if (mounted) {
      setState(() {
        _dbStats = stats;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _loadBackups() async {
    final backups = await _backupService.listBackups();
    if (mounted) {
      setState(() {
        _backups = backups;
        _isLoadingBackups = false;
      });
    }
  }

  Future<void> _loadLastBackupDate() async {
    final date = await _backupService.getLastBackupDate();
    if (mounted) {
      setState(() => _lastBackupDate = date);
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isBackingUp = true);

    final path = await _backupService.backupAll();

    setState(() => _isBackingUp = false);

    if (mounted) {
      if (path != null) {
        await _loadBackups();
        await _loadLastBackupDate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ব্যাকআপ সফল: ${path.split('/').last}'),
            backgroundColor: const Color(0xFF34C759),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ব্যাকআপ ব্যর্থ হয়েছে'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup(String filePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.restore, color: Color(0xFFFF9500)),
            SizedBox(width: 10),
            Text('রিস্টোর কনফার্ম'),
          ],
        ),
        content: const Text(
          'বর্তমান সব ডেটা মুছে যাবে এবং ব্যাকআপ থেকে পুনরুদ্ধার হবে। আপনি কি নিশ্চিত?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('বাতিল'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9500), Color(0xFFFF6B00)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'রিস্টোর করুন',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);

    final success = await _backupService.restoreFromFile(filePath);

    setState(() => _isRestoring = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'রিস্টোর সফল!' : 'রিস্টোর ব্যর্থ হয়েছে',
          ),
          backgroundColor: success ? const Color(0xFF34C759) : Colors.red,
        ),
      );
      if (success) await _loadStats();
    }
  }

  Future<void> _deleteBackup(String filePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Color(0xFFFF3B30)),
            SizedBox(width: 10),
            Text('মুছে ফেলুন'),
          ],
        ),
        content: const Text(
          'এই ব্যাকআপ ফাইল মুছে ফেলতে চান?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('বাতিল'),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'মুছুন',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _backupService.deleteBackup(filePath);
    if (success && mounted) {
      await _loadBackups();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ব্যাকআপ মুছে ফেলা হয়েছে'),
          backgroundColor: Color(0xFF8E8E93),
        ),
      );
    }
  }

  String _formatLastBackup() {
    if (_lastBackupDate == null) return 'কোনো ব্যাকআপ নেই';
    return '${_lastBackupDate!.day.toString().padLeft(2, '0')}/'
        '${_lastBackupDate!.month.toString().padLeft(2, '0')}/${_lastBackupDate!.year} '
        '${_lastBackupDate!.hour.toString().padLeft(2, '0')}:'
        '${_lastBackupDate!.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF007AFF),
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ব্যাকআপ ও রিস্টোর',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Database Stats
              SliverToBoxAdapter(
                child: _buildStatsSection(),
              ),

              // Last backup info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        'শেষ ব্যাকআপ: ${_formatLastBackup()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Create Backup Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34C759), Color(0xFF30D158)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF34C759).withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isBackingUp ? null : _createBackup,
                      icon: _isBackingUp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.backup, color: Colors.white, size: 22),
                      label: Text(
                        _isBackingUp ? 'ব্যাকআপ হচ্ছে...' : 'নতুন ব্যাকআপ তৈরি করুন',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Backup files header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF007AFF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ব্যাকআপ ফাইলস',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF007AFF),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      if (_backups.isNotEmpty)
                        Text(
                          '${_backups.length}টি ফাইল',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Backup files list
              _isLoadingBackups
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  : _backups.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'কোনো ব্যাকআপ নেই',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'উপরের বাটনে ট্যাপ করে ব্যাকআপ তৈরি করুন',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final backup = _backups[index];
                                return _buildBackupCard(backup);
                              },
                              childCount: _backups.length,
                            ),
                          ),
                        ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final stats = [
      {'label': 'প্রোডাক্ট', 'value': _dbStats['products'] ?? 0, 'color': const Color(0xFF34C759)},
      {'label': 'বিল', 'value': _dbStats['bills'] ?? 0, 'color': const Color(0xFF007AFF)},
      {'label': 'কাস্টমার', 'value': _dbStats['customers'] ?? 0, 'color': const Color(0xFFFF9500)},
      {'label': 'স্টক ট্রানজাকশন', 'value': _dbStats['stock_transactions'] ?? 0, 'color': const Color(0xFFAF52DE)},
    ];

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: stats.map((stat) {
          return Container(
            width: 110,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (stat['color'] as Color).withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: stat['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${stat['value']}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: stat['color'] as Color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBackupCard(BackupFileInfo backup) {
    return GlassCard(
      borderColor: const Color(0x1A007AFF),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0x1A007AFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.backup,
              color: Color(0xFF007AFF),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  backup.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      backup.formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.data_usage, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      backup.formattedSize,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Restore button
              GestureDetector(
                onTap: _isRestoring ? null : () => _restoreBackup(backup.path),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFF9500),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _isRestoring
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF9500),
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restore, color: Color(0xFFFF9500), size: 16),
                            SizedBox(width: 4),
                            Text(
                              'রিস্টোর',
                              style: TextStyle(
                                color: Color(0xFFFF9500),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 8),
              // Delete button
              GestureDetector(
                onTap: () => _deleteBackup(backup.path),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFF3B30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFFF3B30),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
