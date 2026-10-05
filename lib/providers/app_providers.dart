import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'business_provider.dart';
import 'theme_provider.dart';
import 'language_provider.dart';
import 'product_provider.dart';
import 'bill_provider.dart';
import 'customer_provider.dart';
import 'shop_provider.dart';
import 'staff_provider.dart';
import 'expense_provider.dart';
import 'supplier_provider.dart';

class AppProviders extends StatelessWidget {
  final Widget child;
  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers (app-wide singletons)
        ChangeNotifierProvider<BusinessProvider>(
          create: (_) => BusinessProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
        ),
        // Feature providers (created fresh or as needed)
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => ProductProvider(),
        ),
        ChangeNotifierProvider<BillProvider>(
          create: (_) => BillProvider(),
        ),
        ChangeNotifierProvider<CustomerProvider>(
          create: (_) => CustomerProvider(),
        ),
        ChangeNotifierProvider<ShopProvider>(
          create: (_) => ShopProvider(),
        ),
        ChangeNotifierProvider<StaffProvider>(
          create: (_) => StaffProvider(),
        ),
        ChangeNotifierProvider<ExpenseProvider>(
          create: (_) => ExpenseProvider(),
        ),
        ChangeNotifierProvider<SupplierProvider>(
          create: (_) => SupplierProvider(),
        ),
      ],
      child: child,
    );
  }
}

/// Extension methods for easy access
extension ProviderExtensions on BuildContext {
  BusinessProvider get business => read<BusinessProvider>();
  ThemeProvider get theme => read<ThemeProvider>();
  LanguageProvider get language => read<LanguageProvider>();
  ProductProvider get products => read<ProductProvider>();
  BillProvider get bill => read<BillProvider>();

  BusinessProvider get watchBusiness => watch<BusinessProvider>();
  ThemeProvider get watchTheme => watch<ThemeProvider>();
  LanguageProvider get watchLanguage => watch<LanguageProvider>();
  ProductProvider get watchProducts => watch<ProductProvider>();
  BillProvider get watchBill => watch<BillProvider>();
}
