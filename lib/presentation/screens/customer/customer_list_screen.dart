import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/business_config.dart';
import '../../../core/localization/localization.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/providers.dart';
import '../../../data/models/customer_model.dart';
import '../../widgets/common/glass_card.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';
import 'due_list_screen.dart';

class CustomerListScreen extends StatefulWidget {
  final BusinessType businessType;
  const CustomerListScreen({super.key, required this.businessType});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
      context.read<CustomerProvider>().calculateTotalDue();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF007AFF),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFFFF3B30),
      const Color(0xFFAF52DE),
      const Color(0xFF5856D6),
      const Color(0xFF5AC8FA),
    ];
    return colors[name.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final config = BusinessConfig.of(widget.businessType);
    final customerProvider = context.watch<CustomerProvider>();

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t('customers'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${customerProvider.customers.length} জন কাস্টমার • মোট বাকি: ₹${customerProvider.totalDue.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Due list button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DueListScreen(businessType: widget.businessType),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x1AFF3B30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              color: Color(0xFFFF3B30), size: 16),
                          SizedBox(width: 4),
                          Text(
                            'বাকি',
                            style: TextStyle(
                              color: Color(0xFFFF3B30),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
                  customerProvider.searchCustomers(value);
                },
                decoration: InputDecoration(
                  hintText: context.t('searchCustomer'),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.muted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            customerProvider.clearSearch();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: const Icon(Icons.clear, color: AppTheme.muted, size: 20),
                          ),
                        )
                      : null,
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

            // Customer list
            Expanded(
              child: customerProvider.isLoading && customerProvider.customers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : customerProvider.customers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'কোনো কাস্টমার নেই',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'নতুন কাস্টমার যোগ করুন',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => customerProvider.loadCustomers(),
                          color: config.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: customerProvider.customers.length,
                            itemBuilder: (context, index) {
                              final customer = customerProvider.customers[index];
                              return _buildCustomerCard(customer, config);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddCustomerScreen(businessType: widget.businessType),
            ),
          );
        },
        backgroundColor: config.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          context.t('addCustomer'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer, BusinessConfig config) {
    final hasDue = customer.totalDue > 0;
    final avatarColor = _getAvatarColor(customer.name);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomerDetailScreen(
              customer: customer,
              businessType: widget.businessType,
            ),
          ),
        );
      },
      child: GlassCard(
        borderColor: hasDue ? const Color(0xFFFF3B30).withOpacity(0.3) : null,
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [avatarColor, avatarColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(customer.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (customer.phone != null && customer.phone!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.phone, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  if (customer.address != null && customer.address!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer.address!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Due badge
            if (hasDue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x1AFF3B30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '₹${customer.totalDue.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFFFF3B30),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
