import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/business_config.dart';
import '../../../core/localization/localization.dart';
import '../../../data/services/return_service.dart';
import '../../../data/models/bill_model.dart';
import '../../widgets/common/glass_card.dart';

class ReturnProcessScreen extends StatefulWidget {
  final BillModel bill;
  final BusinessType businessType;

  const ReturnProcessScreen({
    super.key,
    required this.bill,
    required this.businessType,
  });

  @override
  State<ReturnProcessScreen> createState() => _ReturnProcessScreenState();
}

class _ReturnProcessScreenState extends State<ReturnProcessScreen> {
  final ReturnService _returnService = ReturnService();
  List<BillItemModel> _billItems = [];
  final Map<String, double> _returnQuantities = {};
  String _refundMethod = 'cash';
  final TextEditingController _noteController = TextEditingController();

  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, double> _refundPreview = {};

  @override
  void initState() {
    super.initState();
    _loadBillItems();
  }

  Future<void> _loadBillItems() async {
    final items = await _returnService.getBillItems(widget.bill.id!);
    if (mounted) {
      setState(() {
        _billItems = items;
        for (final item in items) {
          _returnQuantities[item.id!] = 0;
        }
        _isLoading = false;
      });
      _updateRefundPreview();
    }
  }

  void _updateRefundPreview() async {
    final refund = await _returnService.calculateRefund(
      billId: widget.bill.id!,
      returnItems: _returnQuantities,
    );
    if (mounted) {
      setState(() => _refundPreview = refund);
    }
  }

  void _updateQuantity(String itemId, double newQty) {
    final item = _billItems.firstWhere((i) => i.id == itemId);
    if (newQty < 0) newQty = 0;
    if (newQty > item.quantity) newQty = item.quantity;

    setState(() {
      _returnQuantities[itemId] = newQty;
    });
    _updateRefundPreview();
  }

  Future<void> _processReturn() async {
    final itemsToReturn = Map<String, double>.from(_returnQuantities)
      ..removeWhere((k, v) => v <= 0);

    if (itemsToReturn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('কমপক্ষে একটি আইটেম নির্বাচন করুন'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final returnBillNumber = await _returnService.processReturn(
      billId: widget.bill.id!,
      returnItems: itemsToReturn,
      refundMethod: _refundMethod,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    setState(() => _isProcessing = false);

    if (mounted) {
      if (returnBillNumber != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF34C759),
                  size: 72,
                ),
                const SizedBox(height: 20),
                const Text(
                  'রিটার্ন সফল!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'রিটার্ন বিল: $returnBillNumber',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ফেরত: INR ${_refundPreview['total']?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF34C759),
                  ),
                ),
              ],
            ),
            actions: [
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
                    onPressed: () {
                      Navigator.of(context).pop(); // close dialog
                      Navigator.of(context).pop(); // back to return screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'ঠিক আছে',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('রিটার্ন ব্যর্থ হয়েছে'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final config = BusinessConfig.of(widget.businessType);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
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
                          'রিটার্ন প্রসেস',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.bill.billNumber} • ${_formatDate(widget.bill.billDate)}',
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

            // Customer info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                borderColor: config.primary.withOpacity(0.2),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [config.primary, config.accent],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.bill.customerName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.bill.customerPhone != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.bill.customerPhone!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'INR ${widget.bill.totalAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: config.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.bill.items.length} আইটেম',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Items header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    'রিটার্ন করার আইটেম নির্বাচন করুন'.toUpperCase(),
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
            const SizedBox(height: 12),

            // Items list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _billItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'কোনো আইটেম নেই',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _billItems.length,
                          itemBuilder: (context, index) {
                            return _buildReturnItemCard(_billItems[index], config);
                          },
                        ),
            ),

            // Refund summary
            if (_refundPreview['total'] != null && _refundPreview['total']! > 0)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    _buildSummaryRow('মোট', 'INR ${_refundPreview['subtotal']?.toStringAsFixed(2) ?? '0.00'}'),
                    const SizedBox(height: 4),
                    _buildSummaryRow('GST', 'INR ${_refundPreview['gst']?.toStringAsFixed(2) ?? '0.00'}'),
                    const Divider(height: 16),
                    _buildSummaryRow(
                      'মোট ফেরত',
                      'INR ${_refundPreview['total']?.toStringAsFixed(2) ?? '0.00'}',
                      isTotal: true,
                      color: const Color(0xFFFF3B30),
                    ),
                  ],
                ),
              ),

            // Refund method
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ফেরতের মাধ্যম',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMethodChip('cash', 'ক্যাশ', Icons.money),
                      const SizedBox(width: 8),
                      _buildMethodChip('upi', 'UPI', Icons.payment),
                      const SizedBox(width: 8),
                      _buildMethodChip('card', 'কার্ড', Icons.credit_card),
                    ],
                  ),
                ],
              ),
            ),

            // Note field
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'রিটার্নের কারণ (ঐচ্ছিক)',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // Process return button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3B30).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _processReturn,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.assignment_return, color: Colors.white),
                    label: Text(
                      _isProcessing ? 'প্রসেসিং...' : 'রিটার্ন কনফার্ম করুন',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnItemCard(BillItemModel item, BusinessConfig config) {
    final returnQty = _returnQuantities[item.id] ?? 0;
    final isSelected = returnQty > 0;
    final itemRefund = item.unitPrice * returnQty * (1 + item.gstPercent / 100);

    return GlassCard(
      borderColor: isSelected ? config.primary.withOpacity(0.4) : null,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? config.cardGradient
                      : LinearGradient(
                          colors: [Colors.grey[300]!, Colors.grey[400]!],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${item.quantity.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
                      item.productName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'MRP: INR ${item.unitPrice.toStringAsFixed(0)} • GST: ${item.gstPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Text(
                  'INR ${itemRefund.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: config.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'রিটার্ন পরিমাণ:',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              _buildQtyButton(
                Icons.remove,
                () => _updateQuantity(item.id!, returnQty - 1),
                config.primary,
              ),
              Container(
                width: 48,
                alignment: Alignment.center,
                child: Text(
                  returnQty.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _buildQtyButton(
                Icons.add,
                () => _updateQuantity(item.id!, returnQty + 1),
                config.primary,
              ),
              const Spacer(),
              if (returnQty == item.quantity)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFF3B30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'সব',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildMethodChip(String value, String label, IconData icon) {
    final isSelected = _refundMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _refundMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: const Color(0xFF007AFF), width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? const Color(0xFF007AFF) : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF007AFF) : Colors.grey[600],
              ),
            ),
          ],
        ),
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
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? color ?? Colors.black : Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal ? color ?? Colors.black : Colors.black87,
          ),
        ),
      ],
    );
  }
}
