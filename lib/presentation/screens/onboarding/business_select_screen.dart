import 'package:flutter/material.dart';
import '../../../core/constants/business_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/widgets/icons/app_icons.dart';
import 'store_setup_screen.dart';

class BusinessSelectScreen extends StatefulWidget {
  const BusinessSelectScreen({super.key});

  @override
  State<BusinessSelectScreen> createState() => _BusinessSelectScreenState();
}

class _BusinessSelectScreenState extends State<BusinessSelectScreen> {
  BusinessType? _selected;

  final List<BusinessType> _types = [
    BusinessType.grocery,
    BusinessType.pharmacy,
    BusinessType.automobile,
    BusinessType.garments,
    BusinessType.electronics,
    BusinessType.hardware,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'স্বাগতম',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.muted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'আপনার ব্যবসা
নির্বাচন করুন',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 30,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: _types.map((type) => _buildBusinessCard(type)).toList(),
                ),
              ),
              _buildNextButton(),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'পরে সেটিংস থেকে পরিবর্তন করা যাবে',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: AppTheme.muted,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessCard(BusinessType type) {
    final config = BusinessConfig.of(type);
    final isSelected = _selected == type;

    return GestureDetector(
      onTap: () => setState(() => _selected = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? config.primary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? config.primary.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 20 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: config.cardGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: config.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: SvgIcon(
                  svgString: AppIcons.getBusinessSvg(type.name),
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              config.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: config.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              )
            else
              const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final canProceed = _selected != null;
    final config = canProceed ? BusinessConfig.of(_selected!) : null;

    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: canProceed
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StoreSetupScreen(businessType: _selected!),
                    ),
                  )
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: config?.primary ?? Colors.grey[400],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: canProceed ? 4 : 0,
            shadowColor: config?.primary.withOpacity(0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'পরবর্তী',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
