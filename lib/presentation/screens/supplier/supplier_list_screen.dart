import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/supplier_model.dart';
import '../../../providers/supplier_provider.dart';
import '../../../providers/shop_provider.dart';
import '../../widgets/common/glass_card.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final shopId = context.read<ShopProvider>().currentShop?.id;
    await context.read<SupplierProvider>().loadSuppliers(shopId: shopId);
  }

  void _showAddSupplierSheet() {
    final nameController = TextEditingController();
    final companyController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final gstinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'নতুন সাপ্লায়ার',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: _inputDecoration('নাম *', Icons.person_outline),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: companyController,
                decoration: _inputDecoration('কোম্পানি', Icons.business),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('ফোন', Icons.phone),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: _inputDecoration('ঠিকানা', Icons.location_on_outlined),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gstinController,
                decoration: _inputDecoration('GSTIN', Icons.numbers),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5856D6), Color(0xFF007AFF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) return;
                      final shopId = context.read<ShopProvider>().currentShop?.id;
                      final supplier = SupplierModel(
                        id: const Uuid().v4(),
                        name: nameController.text.trim(),
                        company: companyController.text.trim().isEmpty ? null : companyController.text.trim(),
                        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                        address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                        gstin: gstinController.text.trim().isEmpty ? null : gstinController.text.trim(),
                        shopId: shopId,
                        createdAt: DateTime.now(),
                      );
                      await context.read<SupplierProvider>().addSupplier(supplier);
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'সাপ্লায়ার যোগ করুন',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
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

  void _showPaymentSheet(SupplierModel supplier) {
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'পেমেন্ট: ${supplier.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'ব্যালেন্স: INR ${supplier.balanceDue.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: _inputDecoration('পেমেন্ট পরিমাণ', Icons.currency_rupee),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF34C759), Color(0xFF30D158)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) return;
                    final shopId = context.read<ShopProvider>().currentShop?.id;
                    await context.read<SupplierProvider>().recordPayment(
                      supplier.id,
                      amount,
                      shopId: shopId,
                    );
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'পেমেন্ট নথিভুক্ত করুন',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.muted),
      filled: true,
      fillColor: const Color(0x1A8E8E93),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supplierProvider = context.watch<SupplierProvider>();
    final suppliers = supplierProvider.suppliers.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s.company?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    final totalDue = suppliers.fold<double>(0, (sum, s) => sum + s.balanceDue);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('সাপ্লায়ার', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: supplierProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Total due card
                GlassCard(
                  borderColor: const Color(0x1AFF3B30),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.local_shipping, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'মোট ব্যালেন্স দেনা',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.muted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'INR ${totalDue.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFF3B30),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'সাপ্লায়ার খুঁজুন',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.muted),
                    filled: true,
                    fillColor: const Color(0x1A8E8E93),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // Supplier list
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'সাপ্লায়ার তালিকা',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${suppliers.length} জন',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (suppliers.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('কোনো সাপ্লায়ার নেই', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  )
                else
                  ...suppliers.map((s) => _buildSupplierCard(s)),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSupplierSheet,
        backgroundColor: const Color(0xFF5856D6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('সাপ্লায়ার যোগ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildSupplierCard(SupplierModel supplier) {
    final hasDue = supplier.balanceDue > 0;
    return GlassCard(
      borderColor: hasDue ? const Color(0x1AFF3B30) : null,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasDue
                    ? [const Color(0xFFFF3B30), const Color(0xFFFF6B6B)]
                    : [const Color(0xFF34C759), const Color(0xFF30D158)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(supplier.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                if (supplier.company != null) ...[
                  const SizedBox(height: 2),
                  Text(supplier.company!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
                if (supplier.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(supplier.phone!, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'INR ${supplier.balanceDue.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: hasDue ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                ),
              ),
              const SizedBox(height: 4),
              if (hasDue)
                GestureDetector(
                  onTap: () => _showPaymentSheet(supplier),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34C759), Color(0xFF30D158)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'পেমেন্ট',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
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
