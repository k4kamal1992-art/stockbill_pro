import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/business_config.dart';
import '../../../core/localization/localization.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/models/bill_model.dart';
import '../../widgets/common/glass_card.dart';

class BillsScreen extends StatefulWidget {
  final BusinessType businessType;
  const BillsScreen({super.key, required this.businessType});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  List<BillModel> _bills = [];
  List<BillModel> _filteredBills = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, today, week, month

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBills() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper().database;
    final maps = await db.query(
      'bills',
      where: 'businessType = ? AND isDeleted = 0',
      whereArgs: [widget.businessType.name],
      orderBy: 'billDate DESC',
    );
    final bills = maps.map((m) => BillModel.fromMap(m)).toList();

    // Load items for each bill
    for (final bill in bills) {
      final itemMaps = await db.query(
        'bill_items',
        where: 'billId = ?',
        whereArgs: [bill.id],
      );
      bill.items = itemMaps.map((m) => BillItemModel.fromMap(m)).toList();
    }

    if (mounted) {
      setState(() {
        _bills = bills;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<BillModel> result = _bills;

    // Date filter
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'today':
        result = result.where((b) {
          final date = DateTime.tryParse(b.billDate);
          return date != null &&
              date.day == now.day &&
              date.month == now.month &&
              date.year == now.year;
        }).toList();
        break;
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        result = result.where((b) {
          final date = DateTime.tryParse(b.billDate);
          return date != null && date.isAfter(weekAgo);
        }).toList();
        break;
      case 'month':
        final monthAgo = now.subtract(const Duration(days: 30));
        result = result.where((b) {
          final date = DateTime.tryParse(b.billDate);
          return date != null && date.isAfter(monthAgo);
        }).toList();
        break;
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((b) {
        return b.billNumber.toLowerCase().contains(q) ||
            b.customerName.toLowerCase().contains(q) ||
            (b.customerPhone?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    setState(() => _filteredBills = result);
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilters();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilters();
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  double get _totalSales {
    return _filteredBills
        .where((b) => b.totalAmount > 0)
        .fold(0, (sum, b) => sum + b.totalAmount);
  }

  double get _totalReturns {
    return _filteredBills
        .where((b) => b.totalAmount < 0)
        .fold(0, (sum, b) => sum + b.totalAmount.abs());
  }

  int get _billCount => _filteredBills.where((b) => b.totalAmount > 0).length;
  int get _returnCount => _filteredBills.where((b) => b.totalAmount < 0).length;

  @override
  Widget build(BuildContext context) {
    final config = BusinessConfig.of(widget.businessType);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Text(
                    context.t('bills'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Summary cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'মোট বিক্রয়',
                      'INR ${_totalSales.toStringAsFixed(0)}',
                      config.primary,
                      Icons.receipt,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'মোট রিটার্ন',
                      'INR ${_totalReturns.toStringAsFixed(0)}',
                      const Color(0xFFFF3B30),
                      Icons.assignment_return,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'বিল সংখ্যা',
                      _billCount.toString(),
                      const Color(0xFF007AFF),
                      Icons.receipt_long,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'রিটার্ন সংখ্যা',
                      _returnCount.toString(),
                      const Color(0xFFFF9500),
                      Icons.assignment_return_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'বিল নম্বর বা কাস্টমার খুঁজুন',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.muted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            child: const Icon(Icons.clear, color: AppTheme.muted, size: 20),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0x1A8E8E93),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Date filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildDateFilterChip('all', 'সব'),
                  _buildDateFilterChip('today', 'আজ'),
                  _buildDateFilterChip('week', 'সপ্তাহ'),
                  _buildDateFilterChip('month', 'মাস'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Bills list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredBills.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'কোনো বিল নেই',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadBills,
                          color: config.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredBills.length,
                            itemBuilder: (context, index) {
                              return _buildBillCard(_filteredBills[index], config);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return GlassCard(
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                    fontSize: 15,
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
    );
  }

  Widget _buildDateFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => _onFilterChanged(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? config.primary.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: config.primary, width: 1.5)
              : Border.all(color: Colors.grey[200]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? config.primary : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildBillCard(BillModel bill, BusinessConfig config) {
    final isReturn = bill.totalAmount < 0;
    final amountColor = isReturn ? const Color(0xFFFF3B30) : config.primary;
    final icon = isReturn ? Icons.assignment_return : Icons.receipt;

    return GlassCard(
      borderColor: amountColor.withOpacity(0.15),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [amountColor, amountColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bill.billNumber,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isReturn) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFF3B30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'RETURN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF3B30),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  bill.customerName,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(bill.billDate),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'INR ${bill.totalAmount.abs().toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: amountColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${bill.items.length} আইটেম',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                bill.paymentMethod.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BusinessConfig get config => BusinessConfig.of(widget.businessType);
}
