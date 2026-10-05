import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/providers.dart';
import '../../../core/constants/business_config.dart';
import '../scanner/barcode_scanner_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/product_model.dart';

class AddProductScreen extends StatefulWidget {
  final String? businessType;
  const AddProductScreen({super.key, this.businessType});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nameBnController = TextEditingController();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _mrpController = TextEditingController();
  final _gstController = TextEditingController(text: '5');
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController(text: '10');
  final _expiryController = TextEditingController();
  final _batchController = TextEditingController();
  final _genericController = TextEditingController();
  final _companyController = TextEditingController();
  final _imeiController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nameBnController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _mrpController.dispose();
    _gstController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _expiryController.dispose();
    _batchController.dispose();
    _genericController.dispose();
    _companyController.dispose();
    _imeiController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final businessType = widget.businessType ??
        context.read<BusinessProvider>().currentBusiness.name;

    final product = ProductModel(
      name: _nameController.text.trim(),
      nameBn: _nameBnController.text.trim().isEmpty
          ? null
          : _nameBnController.text.trim(),
      category: _categoryController.text.trim(),
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0,
      sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0,
      mrp: double.tryParse(_mrpController.text) ?? 0,
      gstPercent: double.tryParse(_gstController.text) ?? 0,
      stockQuantity: double.tryParse(_stockController.text) ?? 0,
      minStockLevel: double.tryParse(_minStockController.text) ?? 0,
      expiryDate: _expiryController.text.trim().isEmpty
          ? null
          : _expiryController.text.trim(),
      batchNumber: _batchController.text.trim().isEmpty
          ? null
          : _batchController.text.trim(),
      businessType: businessType,
      genericName: _genericController.text.trim().isEmpty
          ? null
          : _genericController.text.trim(),
      company: _companyController.text.trim().isEmpty
          ? null
          : _companyController.text.trim(),
      imei: _imeiController.text.trim().isEmpty
          ? null
          : _imeiController.text.trim(),
      size: _sizeController.text.trim().isEmpty
          ? null
          : _sizeController.text.trim(),
      color: _colorController.text.trim().isEmpty
          ? null
          : _colorController.text.trim(),
    );

    final success = await context.read<ProductProvider>().addProduct(product);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('প্রোডাক্ট ফলভাবে সেভ হয়েছে!'),
          backgroundColor: Color(0xFF34C759),
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      final error = context.read<ProductProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'সেভ ব্যর্থ হয়েছে'),
          backgroundColor: Colors.red,
        ),
      );
      context.read<ProductProvider>().clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessProvider>().config;
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Header
                Row(
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
                      lang.translate('newProduct'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Basic Info Section
                _buildSectionHeader('Basic Info', const Color(0xFF34C759)),
                _buildFormCard([
                  _buildTextField(
                    controller: _nameController,
                    label: 'প্রোডাক্টের নাম *',
                    icon: Icons.label_outline,
                    iconColor: const Color(0xFF34C759),
                    validator: (v) => v?.isEmpty ?? true ? 'নাম আবশ্যক' : null,
                  ),
                  _buildTextField(
                    controller: _nameBnController,
                    label: 'নাম (বাংলা)',
                    icon: Icons.translate,
                    iconColor: const Color(0xFF34C759),
                  ),
                  _buildTextField(
                    controller: _categoryController,
                    label: 'ক্যাটেগরি *',
                    icon: Icons.category_outlined,
                    iconColor: const Color(0xFF34C759),
                    validator: (v) => v?.isEmpty ?? true ? 'ক্যাটেগরি আবশ্যক' : null,
                  ),
                  _buildTextField(
                    controller: _brandController,
                    label: 'ব্র্যান্ড',
                    icon: Icons.branding_watermark_outlined,
                    iconColor: const Color(0xFF34C759),
                  ),
                  _buildBarcodeField(),
                ]),
                const SizedBox(height: 20),
                // Pricing Section
                _buildSectionHeader('Pricing', const Color(0xFF007AFF)),
                _buildFormCard([
                  _buildTextField(
                    controller: _purchasePriceController,
                    label: 'ক্রয় মূল্য *',
                    icon: Icons.currency_rupee,
                    iconColor: const Color(0xFF007AFF),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'ক্রয় মূল্য আবশ্যক' : null,
                  ),
                  _buildTextField(
                    controller: _sellingPriceController,
                    label: 'বিক্রয় মূল্য *',
                    icon: Icons.sell_outlined,
                    iconColor: const Color(0xFF007AFF),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'বিক্রয় মূল্য আবশ্যক' : null,
                  ),
                  _buildTextField(
                    controller: _mrpController,
                    label: 'MRP *',
                    icon: Icons.confirmation_number_outlined,
                    iconColor: const Color(0xFF007AFF),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'MRP আবশ্যক' : null,
                  ),
                  _buildTextField(
                    controller: _gstController,
                    label: 'GST %',
                    icon: Icons.percent,
                    iconColor: const Color(0xFF007AFF),
                    keyboardType: TextInputType.number,
                  ),
                ]),
                const SizedBox(height: 20),
                // Stock Section
                _buildSectionHeader('Stock', const Color(0xFFFF9500)),
                _buildFormCard([
                  _buildTextField(
                    controller: _stockController,
                    label: 'স্টক *',
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xFFFF9500),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'স্টক আবশ্যক' : null,
                  ),
                  _buildTextField(
                    controller: _minStockController,
                    label: 'ন্যূনতম স্টক',
                    icon: Icons.warning_amber_outlined,
                    iconColor: const Color(0xFFFF9500),
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    controller: _expiryController,
                    label: 'এক্সপায়ারি (YYYY-MM-DD)',
                    icon: Icons.calendar_today_outlined,
                    iconColor: const Color(0xFFFF9500),
                  ),
                  _buildTextField(
                    controller: _batchController,
                    label: 'ব্যাচ নম্বর',
                    icon: Icons.numbers_outlined,
                    iconColor: const Color(0xFFFF9500),
                  ),
                ]),
                const SizedBox(height: 20),
                // Business-specific fields
                _buildBusinessSpecificFields(),
                const SizedBox(height: 24),
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34C759), Color(0xFF30D158)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF34C759).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveProduct,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check, color: Colors.white),
                      label: Text(
                        lang.translate('save'),
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessSpecificFields() {
    final businessType = widget.businessType ??
        context.read<BusinessProvider>().currentBusiness;

    switch (businessType) {
      case BusinessType.pharmacy:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Pharmacy Info', const Color(0xFF007AFF)),
            _buildFormCard([
              _buildTextField(
                controller: _genericController,
                label: 'জেনেরিক নাম',
                icon: Icons.medication_outlined,
                iconColor: const Color(0xFF007AFF),
              ),
              _buildTextField(
                controller: _companyController,
                label: 'কোম্পানি',
                icon: Icons.business_outlined,
                iconColor: const Color(0xFF007AFF),
              ),
            ]),
          ],
        );
      case BusinessType.electronics:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Device Info', const Color(0xFF5AC8FA)),
            _buildFormCard([
              _buildTextField(
                controller: _imeiController,
                label: 'IMEI / Serial',
                icon: Icons.phone_android_outlined,
                iconColor: const Color(0xFF5AC8FA),
              ),
            ]),
          ],
        );
      case BusinessType.garments:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Size & Color', const Color(0xFFAF52DE)),
            _buildFormCard([
              _buildTextField(
                controller: _sizeController,
                label: 'সাইজ',
                icon: Icons.straighten_outlined,
                iconColor: const Color(0xFFAF52DE),
              ),
              _buildTextField(
                controller: _colorController,
                label: 'রঙ',
                icon: Icons.color_lens_outlined,
                iconColor: const Color(0xFFAF52DE),
              ),
            ]),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
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

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          return Column(
            children: [
              child,
              if (index < children.length - 1)
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBarcodeField() {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0x1A34C759),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.qr_code_scanner,
          color: Color(0xFF34C759),
          size: 20,
        ),
      ),
      title: TextFormField(
        controller: _barcodeController,
        decoration: InputDecoration(
          labelText: 'বরকোড',
          labelStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      trailing: GestureDetector(
        onTap: () {
          // TODO: Implement barcode scanner
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('বারকোড স্ক্যানার শীঘ্রই আসছে')),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0x1A34C759),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_scanner, color: Color(0xFF34C759), size: 16),
              SizedBox(width: 4),
              Text(
                'Scan',
                style: TextStyle(
                  color: Color(0xFF34C759),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
