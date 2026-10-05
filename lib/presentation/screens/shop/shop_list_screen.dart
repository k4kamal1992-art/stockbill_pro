import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/business_config.dart';
import '../../../data/models/shop_model.dart';
import '../../../providers/shop_provider.dart';
import '../../../providers/business_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../onboarding/store_setup_screen.dart';

class ShopListScreen extends StatefulWidget {
  const ShopListScreen({super.key});

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ShopProvider>().loadShops();
  }

  void _switchShop(ShopModel shop) {
    context.read<ShopProvider>().selectShop(shop);
    context.read<BusinessProvider>().setBusinessType(
      BusinessType.values.firstWhere(
        (b) => b.name == shop.businessType,
        orElse: () => BusinessType.general,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${shop.name}'),
        backgroundColor: const Color(0xFF34C759),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = context.watch<ShopProvider>();
    final shops = shopProvider.shops;
    final currentShop = shopProvider.currentShop;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Shops', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: shopProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : shops.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: shops.length,
                  itemBuilder: (context, index) {
                    final shop = shops[index];
                    final isSelected = currentShop?.id == shop.id;
                    final config = BusinessConfig.of(
                      BusinessType.values.firstWhere(
                        (b) => b.name == shop.businessType,
                        orElse: () => BusinessType.general,
                      ),
                    );
                    return _buildShopCard(shop, config, isSelected);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StoreSetupScreen(businessType: BusinessType.general)),
          );
        },
        backgroundColor: const Color(0xFF5856D6),
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: const Text('Add Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildShopCard(ShopModel shop, BusinessConfig config, bool isSelected) {
    return GestureDetector(
      onTap: () => _switchShop(shop),
      child: GlassCard(
        borderColor: isSelected ? config.primary.withOpacity(0.5) : null,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: config.cardGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  shop.name.isNotEmpty ? shop.name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0x1A34C759),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF34C759),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    config.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: config.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (shop.address != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      shop.address!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'No shops yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first shop to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
