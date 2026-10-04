import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/business_config.dart';
import '../../../core/localization/localization.dart';
import '../../../providers/product_provider.dart';
import '../../../data/models/product_model.dart';
import '../../widgets/common/glass_card.dart';
import 'add_product_screen.dart';

class StockViewScreen extends StatefulWidget {
  final BusinessType businessType;
  const StockViewScreen({super.key, required this.businessType});

  @override
  State<StockViewScreen> createState() => _StockViewScreenState();
}

class _StockViewScreenState extends State<StockViewScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // all, normal, low, out
  String? _selectedCategory;
  List<String> _categories = [];
  ProductModel? _editingProduct;
  final _stockAdjustController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _stockAdjustController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<ProductProvider>().loadProducts(widget.businessType.name);
    await context.read<ProductProvider>().loadStockSummary(widget.businessType.name);
    _extractCategories();
  }

  void _extractCategories() {
    final products = context.read<ProductProvider>().products;
    final cats = products.map((p) => p.category).toSet().toList()..sort();
    if (mounted) {
      setState(() => _categories = cats);
    }
  }

  List<ProductModel> _getFilteredProducts(List<ProductModel> products) {
    return products.where((p) {
      // Category filter
      if (_selectedCategory != null && p.category != _selectedCategory) {
        return false;
      }
      // Stock status filter
      switch (_selectedFilter) {
        case 'normal':
          return p.stockQuantity > p.minStockLevel && p.stockQuantity > 0;
        case 'low':
          return p.stockQuantity <= p.minStockLevel && p.stockQuantity > 0;
        case 'out':
          return p.stockQuantity <= 0;
        default:
          return true;
      }
    }).toList();
  }

  void _showStockAdjustSheet(ProductModel product) {
    _stockAdjustController.text = product.stockQuantity.toStringAsFixed(0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
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
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: BusinessConfig.of(widget.businessType).cardGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.inventory_2, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${product.category} • MRP: INR ${product.mrp.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _stockAdjustController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'নতুন স্টক পরিমাণ',
                  prefixIcon: const Icon(Icons.inventory_2_outlined, color: AppTheme.muted),
                  filled: true,
                  fillColor: const Color(0x1A8E8E93),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'বর্তমান: ${product.stockQuantity.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'ন্যূনতম: ${product.minStockLevel.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: BusinessConfig.of(widget.businessType).cardGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final newQty = double.tryParse(_stockAdjustController.text);
                      if (newQty == null || newQty < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('সঠিক পরিমাণ দিন'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      final success = await context.read<ProductProvider>().updateStock(
                        product.id!,
                        newQty,
                      );
                      if (success && mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} স্টক আপডেট হয়েছে'),
                            backgroundColor: const Color(0xFF34C759),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      'স্টক আপডেট করুন',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStockColor(ProductModel product) {
    if (product.isOutOfStock) return const Color(0xFFFF3B30);
    if (product.isLowStock) return const Color(0xFFFF9500);
    return const Color(0xFF34C759);
  }

  String _getStockLabel(ProductModel product) {
    if (product.isOutOfStock) return 'শেষ';
    if (product.isLowStock) return 'কম';
    return 'স্বাভাবিক';
  }

  @override
  Widget build(BuildContext context) {
    final config = BusinessConfig.of(widget.businessType);
    final productProvider = context.watch<ProductProvider>();
    final allProducts = productProvider.products;
    final filteredProducts = _getFilteredProducts(allProducts);
    final summary = productProvider.stockSummary;

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t('stock'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${filteredProducts.length} প্রোডাক্ট',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  productProvider.searchProducts(value, businessType: widget.businessType.name);
                },
                decoration: InputDecoration(
                  hintText: context.t('searchProduct'),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.muted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            productProvider.clearSearch();
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

            // Stock filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip('all', 'সব', null, filteredProducts.length),
                  _buildFilterChip('normal', 'স্বাভাবিক', const Color(0xFF34C759), summary['normal'] ?? 0),
                  _buildFilterChip('low', 'কম', const Color(0xFFFF9500), summary['low'] ?? 0),
                  _buildFilterChip('out', 'শেষ', const Color(0xFFFF3B30), summary['out'] ?? 0),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Category filter
            if (_categories.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryChip(null, 'সব ক্যাটেগরি'),
                    ..._categories.map((cat) => _buildCategoryChip(cat, cat)),
                  ],
                ),
              ),
            const SizedBox(height: 8),

            // Product list
            Expanded(
              child: productProvider.isLoading && allProducts.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'কোনো প্রোডাক্ট নেই',
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
                          onRefresh: _loadData,
                          color: config.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              return _buildProductCard(filteredProducts[index], config);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddProductScreen(businessType: widget.businessType.name),
            ),
          );
        },
        backgroundColor: config.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          context.t('newProduct'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color? color, int count) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? config.primary).withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: color ?? config.primary, width: 1.5)
              : Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? (color ?? config.primary) : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? (color ?? config.primary).withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? (color ?? config.primary) : Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  Widget _buildProductCard(ProductModel product, BusinessConfig config) {
    final stockColor = _getStockColor(product);
    final stockLabel = _getStockLabel(product);

    return GlassCard(
      borderColor: stockColor.withOpacity(0.3),
      child: Row(
        children: [
          // Stock indicator circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [stockColor, stockColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.stockQuantity.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'stock',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.category}${product.brand != null ? ' • ${product.brand}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'MRP: INR ${product.mrp.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: config.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ক্রয়: INR ${product.purchasePrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                // Business-specific info
                if (product.expiryDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 11, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        'Exp: ${product.expiryDate}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
                if (product.imei != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_android, size: 11, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        'IMEI: ${product.imei}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
                if (product.size != null || product.color != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${product.size ?? ''}${product.size != null && product.color != null ? ' • ' : ''}${product.color ?? ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Stock status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: stockColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  stockLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: stockColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Adjust stock button
              GestureDetector(
                onTap: () => _showStockAdjustSheet(product),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: config.cardGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'স্টক',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
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
