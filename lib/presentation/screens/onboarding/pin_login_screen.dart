import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/pin_service.dart';
import '../../../providers/business_provider.dart';
import '../dashboard/dashboard_screen.dart';

enum _PinMode { loading, setup, confirm, login }

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  String _pin = '';
  String _firstPin = '';
  _PinMode _mode = _PinMode.loading;
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    final has = await PinService.hasPin();
    if (!mounted) return;
    setState(() => _mode = has ? _PinMode.login : _PinMode.setup);
  }

  String get _title {
    switch (_mode) {
      case _PinMode.setup:
        return 'নতুন ৪ সংখ্যার PIN বানান';
      case _PinMode.confirm:
        return 'আবার একই PIN দিন';
      default:
        return 'PIN দিয়ে লগইন করুন';
    }
  }

  void _goToDashboard() {
    final businessType = context.read<BusinessProvider>().currentBusiness;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(businessType: businessType),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _onKeyTap(String value) {
    if (_mode == _PinMode.loading) return;
    if (_pin.length < 4) {
      setState(() => _pin += value);
      if (_pin.length == 4) {
        _validatePin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _validatePin() async {
    final entered = _pin;
    switch (_mode) {
      case _PinMode.setup:
        setState(() {
          _firstPin = entered;
          _pin = '';
          _mode = _PinMode.confirm;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('এবার নিশ্চিত করতে একই PIN আবার দিন'),
            backgroundColor: Color(0xFF34C759),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case _PinMode.confirm:
        if (entered == _firstPin) {
          await PinService.setPin(entered);
          if (mounted) _goToDashboard();
        } else {
          _showSnack('PIN মেলেনি! আবার নতুন PIN দিন');
          setState(() {
            _pin = '';
            _firstPin = '';
            _mode = _PinMode.setup;
          });
        }
        break;
      case _PinMode.login:
        if (await PinService.verify(entered)) {
          if (mounted) _goToDashboard();
        } else {
          _failedAttempts++;
          _showSnack(_failedAttempts >= 5
              ? 'অনেকবার ভুল! কিছুক্ষণ পর আবার চেষ্টা করুন'
              : 'ভুল PIN! আবার চেষ্টা করুন');
          if (mounted) setState(() => _pin = '');
          if (_failedAttempts >= 5) {
            // simple cool-down so the keypad can't be hammered
            final old = _mode;
            setState(() => _mode = _PinMode.loading);
            await Future.delayed(const Duration(seconds: 30));
            if (mounted) {
              _failedAttempts = 0;
              setState(() => _mode = old);
            }
          }
        }
        break;
      case _PinMode.loading:
        break;
    }
  }

  void _showForgotPinInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PIN ভুলে গেছেন?'),
        content: const Text(
          'নিরাপত্তার জন্য PIN রিসেট করার সরাসরি উপায় নেই। '
          'ফোনের Settings থেকে অ্যাপের ডেটা মুছলে PIN রিসেট হবে, কিন্তু তাতে সব বিল ও স্টক মুছে যাবে। '
          'তাই নিয়মিত ব্যাকআপ রাখুন।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Lock Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5856D6), Color(0xFFAF52DE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5856D6).withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.read<BusinessProvider>().displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 44),
                // PIN Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _pin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 9),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? Colors.white
                            : Colors.white.withOpacity(0.15),
                        border: isFilled
                            ? null
                            : Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 44),
                // Keypad
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map(
                        (key) => _buildKey(key),
                      ),
                      const SizedBox.shrink(),
                      _buildKey('0'),
                      _buildKey('⌫', onTap: _onBackspace),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _mode == _PinMode.login ? _showForgotPinInfo : null,
                  child: Text(
                    _mode == _PinMode.login ? 'Forgot PIN? Tap to reset' : '',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => _onKeyTap(label),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: label == '⌫'
              ? Icon(
                  Icons.backspace_outlined,
                  color: Colors.white.withOpacity(0.8),
                  size: 22,
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
        ),
      ),
    );
  }
}
