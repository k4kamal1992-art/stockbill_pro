import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/business_config.dart';
import '../../../core/localization/localization.dart';
import '../../../data/services/report_service.dart';
import '../../widgets/common/glass_card.dart';

class StockReportScreen extends StatefulWidget {
  final BusinessType businessType;
  const StockReportScreen({super.key, required this.businessType});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  final ReportService _reportService = ReportService();

  bool _isLoading = true;
  Map<String, int> _stockStatus = {};
  List<Map<String, dynamic>> _categoryData = [];
  Map<String, double> _valuation = {};
  List<Map<String, dynamic>> _expiringProducts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final status = await _reportService.getStockStatusSummary(widget.businessType.name);
    final categories = await _reportService.getStockByCategory(
      businessType: widget.businessType.name,
    );
    final valuation = await _reportService.getStockValuation(widget.businessType.name);
    final expiring = await _reportService.getExpiringProducts(
      businessType: widget.businessType.name,
      daysThreshold: 30,
    );

    if (mounted) {
      setState(() {
        _stockStatus = status;
        _categoryData = categories;
        _valuation = valuation;
        _expiringProducts = expiring;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = BusinessConfig.of(widget.businessType);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: config.primary,
      child: CustomScrollView(
        slivers: [
          // Stock Status Cards
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildStatusCard(
                    'স্বাভাবিক',
                    _stockStatus['normal'] ?? 0,
                    const Color(0xFF34C759),
                    Icons.check_circle_outline,
                  ),
                  _buildStatusCard(
                    'কম স্টক',
                    _stockStatus['low'] ?? 0,
                    const Color(0xFFFF9500),
                    Icons.warning_amber_outlined,
                  ),
                  _buildStatusCard(
                    'শেষ',
                    _stockStatus['out'] ?? 0,
                    const Color(0xFFFF3B30),
                    Icons.cancel_outlined,
                  ),
                ],
              ),
            ),
          ),

          // Stock Valuation
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: config.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'স্টক মূল্যায়ন'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: config.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildValuationCard(config),
          ),

          // Category Breakdown
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: config.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ক্যাটেগরি অনুযাযী'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: config.secondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _categoryData.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.category_outlined, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text(
                            'কোনো ক্যাটেগরি ডেটা নেই',
                            style: TextStyle(color: Colors.grey[500]),
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
                      (context, index) => _buildCategoryItem(index, config),
                      childCount: _categoryData.length,
                    ),
                  ),
                ),

          // Expiring Products (for pharmacy/grocery)
          if (widget.businessType == BusinessType.pharmacy ||
              widget.businessType == BusinessType.grocery) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'মেয়াদোত্তীর্ণের তালিকা'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF3B30),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _expiringProducts.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text(
                              'কোনো মেয়াদোত্তীর্ণ প্রোডাক্ট নেই',
                              style: TextStyle(color: Colors.grey[500]),
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
                        (context, index) => _buildExpiringItem(index),
                        childCount: _expiringProducts.length,
                      ),
                    ),
                  ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String label, int count, Color color, IconData icon) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
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
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValuationCard(BusinessConfig config) {
    final purchaseValue = _valuation['purchaseValue'] ?? 0;
    final sellingValue = _valuation['sellingValue'] ?? 0;
    final profit = _valuation['potentialProfit'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        borderColor: config.primary.withOpacity(0.2),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildValuationColumn(
                    'ক্রয় মূল্য',
                    '₹${purchaseValue.toStringAsFixed(0)}',
                    const Color(0xFF007AFF),
                  ),
                ),
                Container(width: 1, height: 50, color: Colors.grey[200]),
                Expanded(
                  child: _buildValuationColumn(
                    'বিক্রয় মূল্য',
                    '₹${sellingValue.toStringAsFixed(0)}',
                    config.primary,
                  ),
                ),
                Container(width: 1, height: 50, color: Colors.grey[200]),
                Expanded(
                  child: _buildValuationColumn(
                    'সম্ভাব্য লাভ',
                    '₹${profit.toStringAsFixed(0)}',
                    const Color(0xFF34C759),
                  ),
                ),
              ],
            ),
            if (sellingValue > 0) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: purchaseValue > 0 ? purchaseValue / sellingValue : 0,
                  backgroundColor: const Color(0x1A34C759),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34C759)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Margin: ${sellingValue > 0 ? ((profit / sellingValue) * 100).toStringAsFixed(1) : '0'}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'ROI: ${purchaseValue > 0 ? ((profit / purchaseValue) * 100).toStringAsFixed(1) : '0'}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValuationColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(int index, BusinessConfig config) {
    final category = _categoryData[index];
    final name = category['category'] as String? ?? 'Unknown';
    final count = (category['productCount'] as num?)?.toInt() ?? 0;
    final stock = (category['totalStock'] as num?)?.toDouble() ?? 0;
    final value = (category['stockValue'] as num?)?.toDouble() ?? 0;

    final maxCount = _categoryData.isNotEmpty
        ? (_categoryData.map((c) => (c['productCount'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b))
        : 1;

    final colors = [
      const Color(0xFF34C759),
      const Color(0xFF007AFF),
      const Color(0xFFFF9500),
      const Color(0xFFAF52DE),
      const Color(0xFF5856D6),
      const Color(0xFF5AC8FA),
      const Color(0xFFFF3B30),
    ];
    final color = colors[index % colors.length];

    return GlassCard(
      borderColor: color.withOpacity(0.15),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '$count প্রোডাক্ট',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${stock.toStringAsFixed(0)} ইউনিট',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: count / maxCount,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.6)),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'stock value',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpiringItem(int index) {
    final product = _expiringProducts[index];
    final name = product['name'] as String? ?? 'Unknown';
    final category = product['category'] as String? ?? '';
    final expiryDate = product['expiryDate'] as String? ?? '';
    final stock = (product['stockQuantity'] as num?)?.toDouble() ?? 0;

    // Calculate days until expiry
    final expiry = DateTime.tryParse(expiryDate);
    final daysLeft = expiry != null ? expiry.difference(DateTime.now()).inDays : 0;

    Color urgencyColor;
    if (daysLeft <= 7) {
      urgencyColor = const Color(0xFFFF3B30);
    } else if (daysLeft <= 15) {
      urgencyColor = const Color(0xFFFF9500);
    } else {
      urgencyColor = const Color(0xFF007AFF);
    }

    return GlassCard(
      borderColor: urgencyColor.withOpacity(0.3),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: urgencyColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medication_outlined,
              color: urgencyColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$daysLeft দিন বাকি',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: urgencyColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${stock.toStringAsFixed(0)} ইউনিট',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
