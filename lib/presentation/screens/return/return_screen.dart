import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/business_config.dart';
import '../../../core/localization/localization.dart';
import '../../../data/services/return_service.dart';
import '../../../data/models/bill_model.dart';
import '../../widgets/common/glass_card.dart';
import 'return_process_screen.dart';

class ReturnScreen extends StatefulWidget {
  final BusinessType businessType;
  const ReturnScreen({super.key, required this.businessType});

  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  final ReturnService _returnService = ReturnService();
  final TextEditingController _billSearchController = TextEditingController();
  final TextEditingController _phoneSearchController = TextEditingController();

  List<BillModel> _recentBills = [];
  List<BillModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadRecentBills();
  }

  Future<void> _loadRecentBills() async {
    setState(() => _isLoading = true);
    final bills = await _returnService.getRecentBills(
      businessType: widget.businessType.name,
      days: 30,
    );
    if (mounted) {
      setState(() {
        _recentBills = bills;
        _isLoading = false;
      });
    }
  }

  Future<void> _searchByBillNumber() async {
    final query = _billSearchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    final bill = await _returnService.findBillByNumber(query);

    if (mounted) {
      setState(() => _isSearching = false);
      if (bill != null) {
        _navigateToReturnProcess(bill);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('বিল পাওয়া যায়নি'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchByPhone() async {
    final phone = _phoneSearchController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isSearching = true);
    final bills = await _returnService.getBillsByCustomerPhone(phone);

    if (mounted) {
      setState(() {
        _searchResults = bills;
        _isSearching = false;
      });
    }
  }

  void _navigateToReturnProcess(BillModel bill) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReturnProcessScreen(
          bill: bill,
          businessType: widget.businessType,
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

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
                    context.t('returnReport'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadRecentBills,
                color: config.primary,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Search by bill number
                    _buildSectionHeader('বিল নম্বর দিয়ে খুঁজুন', config.primary),
                    TextField(
                      controller: _billSearchController,
                      decoration: InputDecoration(
                        hintText: 'উদাহরণ: B-123456',
                        prefixIcon: const Icon(Icons.receipt_outlined, color: AppTheme.muted),
                        suffixIcon: _isSearching
                            ? Container(
                                margin: const EdgeInsets.all(12),
                                child: const CircularProgressIndicator(strokeWidth: 2),
                              )
                            : GestureDetector(
                                onTap: _searchByBillNumber,
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: config.cardGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.search, color: Colors.white, size: 20),
                                ),
                              ),
                        filled: true,
                        fillColor: const Color(0x1A8E8E93),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      onSubmitted: (_) => _searchByBillNumber(),
                    ),
                    const SizedBox(height: 20),

                    // Search by phone
                    _buildSectionHeader('ফোন নম্বর দিয়ে খুঁজুন', const Color(0xFF007AFF)),
                    TextField(
                      controller: _phoneSearchController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'উদাহরণ: 9876543210',
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.muted),
                        suffixIcon: _isSearching
                            ? Container(
                                margin: const EdgeInsets.all(12),
                                child: const CircularProgressIndicator(strokeWidth: 2),
                              )
                            : GestureDetector(
                                onTap: _searchByPhone,
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.search, color: Colors.white, size: 20),
                                ),
                              ),
                        filled: true,
                        fillColor: const Color(0x1A8E8E93),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      onSubmitted: (_) => _searchByPhone(),
                    ),
                    const SizedBox(height: 20),

                    // Phone search results
                    if (_searchResults.isNotEmpty) ...[
                      _buildSectionHeader('সার্চ রেজাল্ট', const Color(0xFFFF9500)),
                      ..._searchResults.map((bill) => _buildBillCard(bill, config)),
                      const SizedBox(height: 20),
                    ],

                    // Recent bills
                    _buildSectionHeader('সাম্প্রতিক বিল (৩০ দিন)', config.secondary),
                    const SizedBox(height: 8),
                    if (_isLoading && _recentBills.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_recentBills.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
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
                        ),
                      )
                    else
                      ..._recentBills.map((bill) => _buildBillCard(bill, config)),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
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

  Widget _buildBillCard(BillModel bill, BusinessConfig config) {
    return GestureDetector(
      onTap: () => _navigateToReturnProcess(bill),
      child: GlassCard(
        borderColor: config.primary.withOpacity(0.15),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [config.primary, config.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.receipt,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.billNumber,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
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
                  'INR ${bill.totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: config.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: config.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${bill.items.length} আইটেম',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: config.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
