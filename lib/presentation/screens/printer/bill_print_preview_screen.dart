import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/business_config.dart';
import '../../../core/localization/localization.dart';
import '../../../data/models/bill_model.dart';
import '../../../data/services/print_service.dart';
import '../../../providers/business_provider.dart';
import 'printer_setup_screen.dart';

class BillPrintPreviewScreen extends StatefulWidget {
  final BillModel bill;
  final BusinessType businessType;

  const BillPrintPreviewScreen({
    super.key,
    required this.bill,
    required this.businessType,
  });

  @override
  State<BillPrintPreviewScreen> createState() => _BillPrintPreviewScreenState();
}

class _BillPrintPreviewScreenState extends State<BillPrintPreviewScreen> {
  final PrintService _printService = PrintService();
  bool _isPrinting = false;

  Future<void> _printBill() async {
    if (!_printService.isConnected) {
      // Show printer setup dialog
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.print, color: Color(0xFF007AFF)),
              SizedBox(width: 10),
              Text('প্রিন্টার সংযুক্ত নেই'),
            ],
          ),
          content: const Text(
            'প্রিন্ট করতে প্রথমে একটি ব্লুটুথ প্রিন্টার সংযুক্ত করুন।',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('বাতিল'),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'সেটআপ',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );

      if (result == true && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PrinterSetupScreen()),
        );
      }
      return;
    }

    setState(() => _isPrinting = true);

    final business = context.read<BusinessProvider>();
    final success = await _printService.printBill(
      bill: widget.bill,
      storeName: business.storeName,
      storeAddress: business.storeAddress.isEmpty ? null : business.storeAddress,
      storePhone: business.storePhone.isEmpty ? null : business.storePhone,
      gstin: business.gstin.isEmpty ? null : business.gstin,
      businessType: widget.businessType,
    );

    setState(() => _isPrinting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'বিল প্রিন্ট হয়েছে!' : 'প্রিন্ট ব্যর্থ হয়েছে',
          ),
          backgroundColor: success ? const Color(0xFF34C759) : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = BusinessConfig.of(widget.businessType);
    final business = context.watch<BusinessProvider>();

    final previewLines = _printService.generatePrintPreview(
      bill: widget.bill,
      storeName: business.storeName,
      storeAddress: business.storeAddress.isEmpty ? null : business.storeAddress,
      storePhone: business.storePhone.isEmpty ? null : business.storePhone,
      gstin: business.gstin.isEmpty ? null : business.gstin,
      businessType: widget.businessType,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
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
                  const Text(
                    'প্রিন্ট প্রিভিউ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  // Printer status
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PrinterSetupScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _printService.isConnected
                            ? const Color(0x1A34C759)
                            : const Color(0x1AFF9500),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _printService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                            size: 14,
                            color: _printService.isConnected
                                ? const Color(0xFF34C759)
                                : const Color(0xFFFF9500),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _printService.isConnected ? 'সংযুক্ত' : 'অফলাইন',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _printService.isConnected
                                  ? const Color(0xFF34C759)
                                  : const Color(0xFFFF9500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Receipt preview
            Expanded(
              child: Center(
                child: Container(
                  width: 340,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Column(
                      children: [
                        // Receipt edge decoration
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: config.primary.withOpacity(0.1),
                          ),
                          child: Row(
                            children: List.generate(20, (index) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        // Receipt content
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: previewLines.length,
                            itemBuilder: (context, index) {
                              final line = previewLines[index];
                              if (line['isDivider'] == true) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    line['text'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 1),
                                child: Text(
                                  line['text'] as String,
                                  style: TextStyle(
                                    fontSize: (line['isBold'] == true) ? 13 : 12,
                                    fontWeight: (line['isBold'] == true)
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                  textAlign: (line['isCenter'] == true)
                                      ? TextAlign.center
                                      : TextAlign.left,
                                ),
                              );
                            },
                          ),
                        ),
                        // Bottom edge decoration
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: config.primary.withOpacity(0.1),
                          ),
                          child: Row(
                            children: List.generate(20, (index) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.vertical(
                                      bottom: Radius.circular(6),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Print button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Row(
                children: [
                  // Share button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Share functionality can be added here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('শেয়ার ফিচার শীঘ্রই আসছে'),
                            backgroundColor: Color(0xFF007AFF),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('শেয়ার'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Print button
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
                        onPressed: _isPrinting ? null : _printBill,
                        icon: _isPrinting
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
                          _isPrinting ? 'প্রিন্ট হচ্ছে...' : context.t('print'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
        ),
      ),
    );
  }
}
