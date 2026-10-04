import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/business_config.dart';
import '../../../core/localization/localization.dart';
import '../../../data/services/barcode_service.dart';
import '../../../data/models/product_model.dart';
import '../../../providers/bill_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/icons/app_icons.dart';
import '../billing/billing_screen.dart';

/// BarcodeScannerScreen provides both camera scanning UI and manual entry.
/// When a barcode is found, it can either:
/// - Add product to cart (if from billing flow)
/// - Return product to caller (if from product/add flow)
class BarcodeScannerScreen extends StatefulWidget {
  final BusinessType businessType;

  /// If true, found product is added to cart directly
  final bool addToCartOnFound;

  /// If true, returns the barcode string on pop instead of navigating
  final bool returnBarcode;

  const BarcodeScannerScreen({
    super.key,
    required this.businessType,
    this.addToCartOnFound = false,
    this.returnBarcode = false,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  final BarcodeService _barcodeService = BarcodeService();
  final TextEditingController _manualController = TextEditingController();

  bool _isScanning = true;
  bool _isProcessing = false;
  bool _flashOn = false;
  bool _showManualEntry = false;
  ProductModel? _foundProduct;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @noverride
  void dispose() {
    _animationController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(String barcode) async {
    if (!_isScanning || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _foundProduct = null;
    });

    final product = await _barcodeService.findProductByBarcode(barcode);

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _isScanning = false;
    });

    if (product != null) {
      setState(() => _foundProduct = product);
      if (widget.addToCartOnFound) {
        _addToCart(product);
      } else if (widget.returnBarcode) {
        Navigator.of(context).pop(barcode);
      }
    } else {
      setState(() => _errorMessage = context.t('noProductsFound'));
    }
  }

  void _addToCart(ProductModel product) {
    if (product.stockQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('stockEmpty')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<BillProvider>().addToCart(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ${context.t('productAdded')}'),
        backgroundColor: const Color(0xFF34C759),
        action: SnackBarAction(
          label: context.t('bill'),
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => BillingScreen(businessType: widget.businessType),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onManualSubmit() {
    final barcode = _manualController.text.trim();
    if (barcode.isEmpty) return;
    _onBarcodeDetected(barcode);
  }

  void _resumeScanning() {
    setState(() {
      _isScanning = true;
      _foundProduct = null;
      _errorMessage = null;
      _manualController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = BusinessConfig.of(widget.businessType);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview placeholder (will be replaced with mobile_scanner)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black87,
            child: _buildScannerOverlay(config),
          ),

          // Top controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconButton(
                    Icons.arrow_back_ios_new,
                    () => Navigator.of(context).pop(),
                  ),
                  Text(
                    context.t('scanBarcode'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      _buildIconButton(
                        _flashOn ? Icons.flash_on : Icons.flash_off,
                        () => setState(() => _flashOn = !_flashOn),
                      ),
                      const SizedBox(width: 8),
                      _buildIconButton(
                        _showManualEntry ? Icons.qr_code_scanner : Icons.keyboard,
                        () => setState(() => _showManualEntry = !_showManualEntry),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Scanning frame + laser animation
          if (_isScanning && !_showManualEntry)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: config.primary.withOpacity(0.6),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // Corner markers
                        _buildCornerMarker(config.primary, true, true),
                        _buildCornerMarker(config.primary, false, true),
                        _buildCornerMarker(config.primary, true, false),
                        _buildCornerMarker(config.primary, false, false),
                        // Laser line animation
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Positioned(
                              top: 20 + (_animation.value * 200),
                              left: 10,
                              right: 10,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      config.primary.withOpacity(0),
                                      config.primary,
                                      config.primary.withOpacity(0),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: config.primary.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'বরকোড স্ক্যান করুন',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Manual entry panel
          if (_showManualEntry)
            _buildManualEntryPanel(config),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: config.primary),
                    const SizedBox(height: 16),
                    Text(
                      'সার্চ করছে...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Found product card
          if (_foundProduct != null && !_isProcessing)
            _buildProductFoundCard(config),

          // Error / Not found
          if (_errorMessage != null && !_isProcessing)
            _buildErrorPanel(config),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BusinessConfig config) {
    return GestureDetector(
      onTap: () {
        // Simulate scan for demo purposes
        // In production, this will be replaced with mobile_scanner onDetect
        _simulateScan();
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: config.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _simulateScan() {
    // Demo: simulate finding a product or show manual entry
    // In production, mobile_scanner will call _onBarcodeDetected
    _showDemoOptions();
  }

  void _showDemoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
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
            Text(
              'ডেমো: স্ক্যান সিমুলেশন',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Color(0xFF34C759)),
              title: const Text('প্রোডাক্ট পাওয়া গেছে (সফল)'),
              subtitle: const Text('Simulate: barcode found in database'),
              onTap: () {
                Navigator.pop(context);
                _onBarcodeDetected('DEMO123456');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Color(0xFFFF3B30)),
              title: const Text('প্রোডাক্ট পাওয়া যায়নি (ব্য্থ)'),
              subtitle: const Text('Simulate: barcode not found'),
              onTap: () {
                Navigator.pop(context);
                _onBarcodeDetected('UNKNOWN999');
              },
            ),
            ListTile(
              leading: const Icon(Icons.keyboard, color: Color(0xFF007AFF)),
              title: const Text('ম্যানুয়াল এন্ট্রি'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _showManualEntry = true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryPanel(BusinessConfig config) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
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
            Text(
              'বরকোড টাইপ করুন',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualController,
              keyboardType: TextInputType.text,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'উদাহরণ: 8901234567890',
                prefixIcon: const Icon(Icons.qr_code, color: AppTheme.muted),
                filled: true,
                fillColor: const Color(0x1A8E8E93),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
              onSubmitted: (_) => _onManualSubmit(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: config.cardGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton.icon(
                  onPressed: _onManualSubmit,
                  icon: const Icon(Icons.search, color: Colors.white, size: 20),
                  label: Text(
                    context.t('search'),
                    style: const TextStyle(
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
    );
  }

  Widget _buildProductFoundCard(BusinessConfig config) {
    final product = _foundProduct!;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
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
            const SizedBox(height: 16),
            Icon(
              Icons.check_circle,
              color: const Color(0xFF34C759),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'প্রোডাক্ট পাওয়া গেছে!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            GlassCard(
              borderColor: config.primary,
              child: Row(
                children: [
                  IconPill(
                    svgString: AppIcons.getBusinessSvg(widget.businessType.name),
                    size: 20,
                    gradient: config.cardGradient,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${product.category} • MRP: ₹${product.mrp.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stock: ${product.stockQuantity.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: product.isLowStock ? const Color(0xFFFF9500) : const Color(0xFF34C759),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.addToCartOnFound)
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: config.cardGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _addToCart(product);
                      _resumeScanning();
                    },
                    icon: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 20),
                    label: Text(
                      context.t('addToCart'),
                      style: const TextStyle(
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
            const SizedBox(height: 10),
            TextButton(
              onPressed: _resumeScanning,
              child: Text(
                'আবার স্ক্যান করুন',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPanel(BusinessConfig config) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
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
            const SizedBox(height: 16),
            const Icon(
              Icons.error_outline,
              color: Color(0xFFFF3B30),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              context.t('noProductsFound'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'এই বরকোডের কোনো প্রোডাক্ট নেই',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resumeScanning,
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: Text(context.t('scanBarcode')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: config.cardGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _resumeScanning();
                        setState(() => _showManualEntry = true);
                      },
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      label: Text(
                        context.t('newProduct'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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
          ],
        ),
      ),
    );
  }

  Widget _buildCornerMarker(Color color, bool top, bool left) {
    return Positioned(
      top: top ? 0 : null,
      bottom: !top ? 0 : null,
      left: left ? 0 : null,
      right: !left ? 0 : null,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: top ? BorderSide(color: color, width: 3) : BorderSide.none,
            bottom: !top ? BorderSide(color: color, width: 3) : BorderSide.none,
            left: left ? BorderSide(color: color, width: 3) : BorderSide.none,
            right: !left ? BorderSide(color: color, width: 3) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(16) : Radius.zero,
            topRight: top && !left ? const Radius.circular(16) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(16) : Radius.zero,
            bottomRight: !top && !left ? const Radius.circular(16) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
