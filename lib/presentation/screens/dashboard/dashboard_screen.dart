import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/providers.dart';
import '../../../core/constants/business_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/widgets/icons/app_icons.dart';
import '../../../presentation/widgets/cards/vibrant_card.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/section_header.dart';
import '../billing/billing_screen.dart';
import '../bill/bills_screen.dart';
import '../profile/profile_screen.dart';
import '../product/stock_view_screen.dart';
import '../reports/reports_screen.dart';
import '../return/return_screen.dart';
import '../settings/settings_screen.dart';
import '../../../data/services/billing_service.dart';

class DashboardScreen extends StatefulWidget {
  final BusinessType businessType;
  const DashboardScreen({super.key, required this.businessType});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  double _todaySales = 0;
  double _monthlySales = 0;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final billingService = BillingService();
    final today = await billingService.getTodaySales(widget.businessType.name);
    final monthly = await billingService.getMonthlySales(widget.businessType.name);

    if (mounted) {
      setState(() {
        _todaySales = today;
        _monthlySales = monthly;
        _statsLoading = false;
      });
    }

    // Load products for this business
    context.read<ProductProvider>().loadProducts(widget.businessType.name);
    context.read<ProductProvider>().loadLowStock(widget.businessType.name);
    context.read<ProductProvider>().loadStockSummary(widget.businessType.name);
  }

  @override
  Widget build(BuildContext context) {
    final config = BusinessConfig.of(widget.businessType);
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _selectedIndex == 0
            ? _buildDashboard(config, lang)
            : _selectedIndex == 3
                ? const SettingsScreen()
                : const Center(child: Text('Coming Soon')),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BillingScreen(businessType: widget.businessType),
                  ),
                );
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: config.cardGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: config.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(config, lang),
    );
  }

  Widget _buildDashboard(BusinessConfig config, LanguageProvider lang) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: config.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getFormattedDate(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.watch<BusinessProvider>().storeName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 30,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  VibrantCard(
                    gradient: config.cardGradient,
                    label: lang.translate('todaySales'),
                    value: '₹${_todaySales.toStringAsFixed(0)}',
                    changeText: '↑ 12% গতকালের তুলনায়',
                    icon: _buildMiniIcon(config.primary),
                  ),
                  const SizedBox(width: 12),
                  VibrantCard(
                    gradient: LinearGradient(
                      colors: [config.secondary, config.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    label: lang.translate('monthlySales'),
                    value: '₹${_formatAmount(_monthlySales)}',
                    changeText: '↑ 8% এই মাসে',
                    icon: _buildMiniIcon(config.secondary),
                  ),
                ],
              ),
            ),
          ),
          // Stock Summary Cards
          SliverToBoxAdapter(
            child: _buildStockSummaryCards(config),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: _getListTitle(),
              icon: IconPill(
                svgString: AppIcons.getBusinessSvg(widget.businessType.name),
                size: 14,
                gradient: config.cardGradient,
              ),
            ),
          ),
          // Low Stock / Alerts List
          _buildAlertsList(config),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: lang.translate('todaySales'),
              icon: IconPill(
                svgString: AppIcons.getBusinessSvg(widget.businessType.name),
                size: 14,
                gradient: config.cardGradient,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildChart(config),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildStockSummaryCards(BusinessConfig config) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final summary = productProvider.stockSummary;
        if (productProvider.isLoading && summary.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildSummaryPill('স্বাভাবিক', summary['normal'] ?? 0, const Color(0xFF34C759)),
              _buildSummaryPill('কম স্টক', summary['low'] ?? 0, const Color(0xFFFF9500)),
              _buildSummaryPill('শেষ', summary['out'] ?? 0, const Color(0xFFFF3B30)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryPill(String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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

  Widget _buildAlertsList(BusinessConfig config) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading && productProvider.lowStockProducts.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final items = productProvider.lowStockProducts;
        if (items.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'সব স্টক স্বাভাবিক',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = items[index];
                final isOut = product.isOutOfStock;
                final isLow = product.isLowStock && !isOut;
                final color = isOut ? const Color(0xFFFF3B30) : const Color(0xFFFF9500);

                return GlassCard(
                  borderColor: color,
                  child: Row(
                    children: [
                      IconPill(
                        svgString: AppIcons.getBusinessSvg(widget.businessType.name),
                        size: 18,
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${product.category} • MRP: ₹${product.mrp.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${product.stockQuantity.toStringAsFixed(0)} left',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: items.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniIcon(Color color) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.trending_up, color: Colors.white, size: 14),
    );
  }

  Widget _buildChart(BusinessConfig config) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 140,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 100,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final labels = ['শু', 'সো', 'ম', 'বু', 'বৃ', 'শু', 'শ'];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[value.toInt() % labels.length],
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
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(7, (index) {
              final heights = [40.0, 65.0, 50.0, 80.0, 60.0, 90.0, 75.0];
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: heights[index],
                    width: 14,
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
    );
  }

  Widget _buildBottomNav(BusinessConfig config, LanguageProvider lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: ClipRRect(
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: config.primary,
          unselectedItemColor: AppTheme.muted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: [
            _buildNavItem(Icons.home_outlined, lang.translate('home'), config.primary),
            _buildNavItem(Icons.receipt_outlined, lang.translate('bill'), AppTheme.muted),
            _buildNavItem(Icons.inventory_2_outlined, lang.translate('stock'), AppTheme.muted),
            _buildNavItem(Icons.person_outline, lang.translate('profile'), AppTheme.muted),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, Color color) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 22),
      ),
      label: label,
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final days = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহস্পতি', 'শুক্র', 'শনি'];
    final months = ['জানুয়ারি', 'ফেবরুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]}';
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }

  String _getListTitle() {
    switch (widget.businessType) {
      case BusinessType.pharmacy:
        return 'Expiry Timeline';
      case BusinessType.automobile:
        return 'Top Vehicles';
      case BusinessType.garments:
        return 'Low Stock Variants';
      default:
        return 'Low Stock';
    }
  }
}
