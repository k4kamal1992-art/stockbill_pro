import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/providers.dart';
import '../../../core/constants/business_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/widgets/icons/app_icons.dart';
import '../../widgets/common/glass_card.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/bill_model.dart';
import '../scanner/barcode_scanner_screen.dart';
import '../printer/bill_print_preview_screen.dart';

class BillingScreen extends StatefulWidget {
  final BusinessType businessType;
  const BillingScreen({super.key, required this.businessType});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load products for search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts(widget.businessType.name);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = BusinessConfig.of(widget.businessType);
    final lang = context.watch<LanguageProvider>();
    final billProvider = context.watch<BillProvider>();
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                    lang.translate('newBill'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: config.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${widget.businessType.name.substring(0, 1).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8, 12)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: config.primary,
                      ),
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
                  hintText: lang.translate('searchProduct'),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.muted),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Barcode scan button
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BarcodeScannerScreen(
                                businessType: widget.businessType,
                                addToCartOnFound: true,
                              ),
                            ),
                          );
                          // If product was added, cart will update via provider
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: config.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.qr_code_scanner,
                            color: config.primary,
                            size: 20,
                          ),
                        ),
                      ),
                      // Clear button
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            productProvider.clearSearch();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.clear, color: AppTheme.muted, size: 20),
                          ),
                        ),
                    ],
                  ),
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
            // Search Results or Quick Chips
            if (productProvider.isLoading && _searchController.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_searchController.text.isNotEmpty && productProvider.products.isNotEmpty)
              _buildSearchResults(productProvider.products, config)
            else if (_searchController.text.isNotEmpty && productProvider.products.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'কোনো প্রোডাক্ট পাওয়া যায়নি',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildQuickChips(config),
            // Bill Items (Cart)
            Expanded(
              child: billProvider.cart.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'কার্ট খালি',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'প্রোডাক্ট সার্চ করে যোগ করুন',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: billProvider.cart.length,
                      itemBuilder: (context, index) {
                        final item = billProvider.cart[index];
                        return GlassCard(
                          borderColor: config.primary,
                          child: Row(
                            children: [
                              IconPill(
                                svgString: AppIcons.getBusinessSvg(widget.businessType.name),
                                size: 18,
                                gradient: config.cardGradient,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'MRP: ₹${item.product.mrp.toStringAsFixed(0)} • GST: ${item.product.gstPercent.toStringAsFixed(0)}%',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity controls
                              Row(
                                children: [
                                  _buildQtyButton(
                                    Icons.remove,
                                    () => context.read<BillProvider>().updateQuantity(
                                      item.product.id,
                                      item.quantity - 1,
                                    ),
                                    config.primary,
                                  ),
                                  Container(
                                    width: 40,
                                    alignment: Alignment.center,
                                    child: Text(
                                      item.quantity.toStringAsFixed(0),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  _buildQtyButton(
                                    Icons.add,
                                    () => context.read<BillProvider>().updateQuantity(
                                      item.product.id,
                                      item.quantity + 1,
                                    ),
                                    config.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${item.finalTotal.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity.toStringAsFixed(0)} × ₹${item.unitPrice.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            // Summary
            if (billProvider.cart.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(lang.translate('total'), '₹${billProvider.subtotal.toStringAsFixed(0)}'),
                    const SizedBox(height: 6),
                    _buildSummaryRow('GST', '₹${billProvider.gstAmount.toStringAsFixed(0)}'),
                    const Divider(height: 20),
                    _buildSummaryRow(
                      lang.translate('grandTotal'),
                      '₹${billProvider.totalAmount.toStringAsFixed(0)}',
                      isTotal: true,
                      color: config.primary,
                    ),
                  ],
                ),
              ),
              // Payment buttons
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPaymentButton(
                        lang.translate('cash'),
                        Icons.money,
                        Colors.grey[100]!,
                        Colors.black87,
                        () => context.read<BillProvider>().setPaymentMethod('cash'),
                        billProvider.paymentMethod == 'cash',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPaymentButton(
                        lang.translate('upi'),
                        Icons.payment,
                        Colors.grey[100]!,
                        Colors.black87,
                        () => context.read<BillProvider>().setPaymentMethod('upi'),
                        billProvider.paymentMethod == 'upi',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: config.cardGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: config.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: billProvider.isProcessing
                              ? null
                              : () => _processCheckout(context),
                          icon: billProvider.isProcessing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.print, color: Colors.white, size: 18),
                          label: Text(
                            lang.translate('print'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<ProductModel> products, BusinessConfig config) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            leading: IconPill(
              svgString: AppIcons.getBusinessSvg(widget.businessType.name),
              size: 16,
              gradient: config.cardGradient,
            ),
            title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Stock: ${product.stockQuantity.toStringAsFixed(0)} • ₹${product.sellingPrice.toStringAsFixed(0)}'),
            trailing: TextButton(
              onPressed: () {
                if (product.stockQuantity > 0) {
                  context.read<BillProvider>().addToCart(product);
                  _searchController.clear();
                  context.read<ProductProvider>().clearSearch();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} যোগ হয়েছে'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: config.primary,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('স্টক শেষ!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                '+ যোগ করুন',
                style: TextStyle(
                  color: config.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickChips(BusinessConfig config) {
    final chips = ['Rice', 'Dal', 'Oil', 'Biscuit', 'Sugar'];
    final colors = [
      const Color(0xFF34C759),
      const Color(0xFF007AFF),
      const Color(0xFFFF9500),
      const Color(0xFFAF52DE),
      const Color(0xFF5856D6),
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: List.generate(chips.length, (index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  chips[index],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 17 : 15,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? color ?? Colors.black : Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal ? color ?? Colors.black : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton(
    String label,
    IconData icon,
    Color bg,
    Color fg,
    VoidCallback onTap,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : bg,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: const Color(0xFF007AFF), width: 1.5)
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF007AFF) : fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF007AFF) : fg,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processCheckout(BuildContext context) async {
    final billProvider = context.read<BillProvider>();
    final success = await billProvider.checkout(widget.businessType.name);

    if (success && mounted) {
      // Get the created bill from the billing service
      final billRepo = context.read<BillProvider>();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('বিল সফলভাবে তৈরি হয়েছে!'),
          backgroundColor: const Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Navigate to print preview
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BillPrintPreviewScreen(
            bill: BillModel(
              billNumber: billRepo.cart.isNotEmpty 
                  ? 'B-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}'
                  : 'B-001',
              customerName: billProvider.customerName.isEmpty 
                  ? 'Walk-in Customer' 
                  : billProvider.customerName,
              customerPhone: billProvider.customerPhone.isEmpty 
                  ? null 
                  : billProvider.customerPhone,
              items: billRepo.cart.map((item) => BillItemModel(
                productId: item.product.id,
                productName: item.product.name,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                gstPercent: item.product.gstPercent,
                totalPrice: item.finalTotal,
                batchNumber: item.product.batchNumber,
                imei: item.product.imei,
                size: item.product.size,
                color: item.product.color,
              )).toList(),
              subtotal: billProvider.subtotal,
              gstAmount: billProvider.gstAmount,
              totalAmount: billProvider.totalAmount,
              discount: billProvider.discount,
              paymentMethod: billProvider.paymentMethod,
              amountPaid: billProvider.amountPaid,
              amountDue: billProvider.amountDue,
              businessType: widget.businessType.name,
            ),
            businessType: widget.businessType,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(billProvider.error ?? 'বিল তৈরি ব্যর্থ'),
          backgroundColor: Colors.red,
        ),
      );
      billProvider.clearError();
    }
  }
}
