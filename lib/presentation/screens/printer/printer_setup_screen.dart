import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/print_service.dart';
import '../../widgets/common/glass_card.dart';

class PrinterSetupScreen extends StatefulWidget {
  const PrinterSetupScreen({super.key});

  @override
  State<PrinterSetupScreen> createState() => _PrinterSetupScreenState();
}

class _PrinterSetupScreenState extends State<PrinterSetupScreen> {
  final PrintService _printService = PrintService();
  List<Map<String, dynamic>> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectedAddress;
  int _paperDots = 384;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadPaperWidth();
  }

  Future<void> _loadPaperWidth() async {
    final dots = await _printService.getPaperWidthDots();
    if (mounted) setState(() => _paperDots = dots);
  }

  Future<void> _setPaperWidth(int dots) async {
    await _printService.setPaperWidthDots(dots);
    if (mounted) setState(() => _paperDots = dots);
  }

  Future<void> _testPrint() async {
    final ok = await _printService.printTestPage();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'টেস্ট পেজ পাঠানো হয়েছে'
            : (_printService.lastError ?? 'টেস্ট প্রিন্ট ব্যর্থ হয়েছে')),
        backgroundColor: ok ? const Color(0xFF34C759) : Colors.red,
      ),
    );
  }

  void _checkConnection() {
    setState(() {
      _connectedAddress = _printService.connectedAddress;
    });
  }

  Future<void> _scanDevices() async {
    setState(() {
      _isScanning = true;
      _devices = [];
    });

    final devices = await _printService.scanDevices();

    if (mounted) {
      setState(() {
        _devices = devices;
        _isScanning = false;
      });
      final problem = _printService.lastError;
      if (problem != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(problem), backgroundColor: Colors.orange[800]),
        );
      }
    }
  }

  Future<void> _connectDevice(String address, String name) async {
    setState(() => _isConnecting = true);

    final success = await _printService.connectToDevice(address, name: name);

    if (mounted) {
      setState(() {
        _isConnecting = false;
        if (success) {
          _connectedAddress = address;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '$name সংযুক্ত হয়েছে'
                : (_printService.lastError ?? 'সংযোগ ব্যর্থ হয়েছে'),
          ),
          backgroundColor: success ? const Color(0xFF34C759) : Colors.red,
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    await _printService.disconnect();
    setState(() => _connectedAddress = null);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('প্রিন্টার সংযোগ বিচ্ছিন্ন হয়েছে'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'প্রিন্টার সেটআপ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // Connection status
            if (_printService.isConnected)
              GlassCard(
                borderColor: const Color(0xFF34C759),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0x1A34C759),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.print,
                        color: Color(0xFF34C759),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _printService.connectedDeviceName ?? 'প্রিন্টার',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34C759),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'সংযুক্ত',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF34C759),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _testPrint,
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text(
                        'টেস্ট',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _disconnect,
                      icon: const Icon(Icons.link_off, size: 18, color: Colors.red),
                      label: const Text(
                        'বিচ্ছিন্ন',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Paper width
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Text(
                    'কাগজের মাপ:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('58 mm'),
                    selected: _paperDots == 384,
                    onSelected: (_) => _setPaperWidth(384),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('80 mm'),
                    selected: _paperDots == 576,
                    onSelected: (_) => _setPaperWidth(576),
                  ),
                ],
              ),
            ),

            // Scan button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanDevices,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.bluetooth_searching, color: Colors.white, size: 20),
                    label: Text(
                      _isScanning ? 'সার্চ করছে...' : 'ব্লুটুথ প্রিন্টার সার্চ করুন',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
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

            // Device list
            Expanded(
              child: _devices.isEmpty && !_isScanning
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'কোনো প্রিন্টার পাওয়া যায়নি',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'আগে ফোনের Bluetooth সেটিংসে প্রিন্টার pair করুন,\nতারপর সার্চ বাটনে ট্যাপ করুন',
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
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        final isConnected = _connectedAddress == device['address'];

                        return GlassCard(
                          borderColor: isConnected ? const Color(0xFF34C759) : null,
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isConnected
                                      ? const Color(0x1A34C759)
                                      : const Color(0x1A007AFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.print,
                                  color: isConnected
                                      ? const Color(0xFF34C759)
                                      : const Color(0xFF007AFF),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device['name'] ?? 'অজানা প্রিন্টার',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      device['address'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isConnected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0x1A34C759),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'সংযুক্ত',
                                    style: TextStyle(
                                      color: Color(0xFF34C759),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: _isConnecting
                                      ? null
                                      : () => _connectDevice(
                                            device['address']!,
                                            device['name'] ?? 'প্রিন্টার',
                                          ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF007AFF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: _isConnecting
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'সংযুক্ত করুন',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
