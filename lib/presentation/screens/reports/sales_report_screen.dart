import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/business_config.dart';
import '../../../core/localization/localization.dart';
import '../../../data/services/report_service.dart';
import '../../widgets/common/glass_card.dart';

class SalesReportScreen extends StatefulWidget {
  final BusinessType businessType;
  const SalesReportScreen({super.key, required this.businessType});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final ReportService _reportService = ReportService();

  bool _isLoading = true;
  String _period = 'week'; // week, month
  Map<String, dynamic> _summary = {};
  Map<String, double> _dailySales = {};
  Map<String, double> _monthlySales = {};
  List<Map<String, dynamic>> _topProducts = [];
  Map<String, double> _paymentBreakdown = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final summary = await _reportService.getSalesSummary(widget.businessType.name);
    final daily = await _reportService.getDailySales(
      businessType: widget.businessType.name,
      days: 7,
    );
    final monthly = await _reportService.getMonthlySales(
      businessType: widget.businessType.name,
      months: 6,
    );
    final topProducts = await _reportService.getTopSellingProducts(
      businessType: widget.businessType.name,
      limit: 5,
    );
    final paymentBreakdown = await _reportService.getPaymentMethodBreakdown(
      businessType: widget.businessType.name,
      period: 'month',
    );

    if (mounted) {
      setState(() {
        _summary = summary;
        _dailySales = daily;
        _monthlySales = monthly;
        _topProducts = topProducts;
        _paymentBreakdown = paymentBreakdown;
        _isLoading = false;
      });
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
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
          // Summary cards
          SliverToBoxAdapter(
            child: SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSummaryCard(
                    'আজকের বিক্রি',
                    '₹${_formatAmount(_summary['todaySales'] ?? 0)}',
                    '${_summary['todayBills'] ?? 0} বিল',
                    config.primary,
                    Icons.trending_up,
                  ),
                  _buildSummaryCard(
                    'মাসিক বিক্রি',
                    '₹${_formatAmount(_summary['monthSales'] ?? 0)}',
                    '${_summary['monthBills'] ?? 0} বিল',
                    config.secondary,
                    Icons.calendar_month,
                  ),
                  _buildSummaryCard(
                    'মোট বিক্রি',
                    '₹${_formatAmount(_summary['totalSales'] ?? 0)}',
                    '${_summary['totalBills'] ?? 0} বিল',
                    config.accent,
                    Icons.paid,
                  ),
                ],
              ),
            ),
          ),

          // Period toggle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPeriodChip('week', 'সপ্তাহ'),
                        _buildPeriodChip('month', 'মাস'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSalesChart(config),
            ),
          ),

          // Payment breakdown
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
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
                    'পমেন্ট মাধ্যম'.toUpperCase(),
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
            child: _buildPaymentBreakdown(config),
          ),

          // Top products
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
                    'টপ সেলিং প্রোডাক্ট'.toUpperCase(),
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
          _topProducts.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text(
                            'এখনো কোনো বিক্রি নেই',
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
                      (context, index) => _buildTopProductItem(index, config),
                      childCount: _topProducts.length,
                    ),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, String subtitle, Color color, IconData icon) {
    return Container(
      width: 140,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _period == value;
    return GestureDetector(
      onTap: () => setState(() => _period = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black87 : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesChart(BusinessConfig config) {
    final data = _period == 'week' ? _dailySales : _monthlySales;
    if (data.isEmpty) return const SizedBox.shrink();

    final entries = data.entries.toList();
    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2;
    final interval = maxY > 0 ? maxY / 4 : 1;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _period == 'week' ? 'গত ৭ দিনের বিক্রি' : 'গত ৬ মাসের বিক্রি',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY > 0 ? maxY : 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final key = entries[groupIndex].key;
                      final value = entries[groupIndex].value;
                      String label;
                      if (_period == 'week') {
                        final date = DateTime.parse(key);
                        final days = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি'];
                        label = days[date.weekday % 7];
                      } else {
                        final parts = key.split('-');
                        final months = ['জানু', 'ফেব', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগ', 'সেপ্ট', 'অক্টো', 'নভে', 'ডিসে'];
                        label = '${months[int.parse(parts[1]) - 1]} ${parts[0]}';
                      }
                      return BarTooltipItem(
                        '$label
₹${value.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                        final key = entries[index].key;
                        String label;
                        if (_period == 'week') {
                          final date = DateTime.parse(key);
                          final days = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি'];
                          label = days[date.weekday % 7];
                        } else {
                          final parts = key.split('-');
                          final months = ['জানু', 'ফেব', 'মার্চ', 'এপ্রিল', 'মে', 'জুন'];
                          label = months[int.parse(parts[1]) - 1];
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval.toDouble(),
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${_formatAmount(value)}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval.toDouble(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(entries.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: entries[index].value,
                        width: _period == 'week' ? 22 : 28,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        gradient: LinearGradient(
                          colors: [config.primary, config.accent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(BusinessConfig config) {
    if (_paymentBreakdown.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: GlassCard(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'কোনো পেমেন্ট ডেটা নেই',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    }

    final total = _paymentBreakdown.values.fold(0.0, (a, b) => a + b);
    final colors = {
      'cash': const Color(0xFF34C759),
      'upi': const Color(0xFF007AFF),
      'card': const Color(0xFFFF9500),
      'credit': const Color(0xFFFF3B30),
    };

    final labels = {
      'cash': 'ক্যাশ',
      'upi': 'UPI',
      'card': 'কার্ড',
      'credit': 'বাকি',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        child: Column(
          children: _paymentBreakdown.entries.map((entry) {
            final percentage = total > 0 ? (entry.value / total * 100) : 0;
            final color = colors[entry.key] ?? config.primary;
            final label = labels[entry.key] ?? entry.key;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? entry.value / total : 0,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopProductItem(int index, BusinessConfig config) {
    final product = _topProducts[index];
    final name = product['productName'] as String? ?? 'Unknown';
    final qty = (product['totalQty'] as num?)?.toDouble() ?? 0;
    final revenue = (product['totalRevenue'] as num?)?.toDouble() ?? 0;
    final maxQty = (_topProducts.first['totalQty'] as num?)?.toDouble() ?? 1;

    final rankColors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];

    return GlassCard(
      borderColor: index < 3 ? rankColors[index].withOpacity(0.5) : null,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: index < 3 ? rankColors[index].withOpacity(0.15) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: index < 3 ? rankColors[index] : Colors.grey[500],
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: qty / maxQty,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(config.primary.withOpacity(0.6)),
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
                '${qty.toStringAsFixed(0)} sold',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: config.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '₹${revenue.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
