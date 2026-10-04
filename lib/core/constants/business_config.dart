import 'package:flutter/material.dart';

enum BusinessType {
  grocery,
  pharmacy,
  automobile,
  garments,
  electronics,
  hardware,
  general,
  custom,
}

class BusinessConfig {
  final BusinessType type;
  final String label;
  final String labelBn;
  final LinearGradient gradient;
  final LinearGradient cardGradient;
  final LinearGradient lightGradient;
  final Color primary;
  final Color secondary;
  final Color accent;

  const BusinessConfig({
    required this.type,
    required this.label,
    required this.labelBn,
    required this.gradient,
    required this.cardGradient,
    required this.lightGradient,
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  static const Map<BusinessType, BusinessConfig> configs = {
    BusinessType.grocery: BusinessConfig(
      type: BusinessType.grocery,
      label: 'Grocery',
      labelBn: 'মুদি দোকান',
      gradient: LinearGradient(
        colors: [Color(0xFF34C759), Color(0xFF30D158), Color(0xFF85E0A6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      cardGradient: LinearGradient(
        colors: [Color(0xFF34C759), Color(0xFF30D158)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      lightGradient: LinearGradient(
        colors: [Color(0xFFE8F5E9), Color(0xFFE0F7FA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      primary: Color(0xFF34C759),
      secondary: Color(0xFF30D158),
      accent: Color(0xFF85E0A6),
    ),
    BusinessType.pharmacy: BusinessConfig(
      type: BusinessType.pharmacy,
      label: 'Pharmacy',
      labelBn: 'ফার্মেসি',
      gradient: LinearGradient(
        colors: [Color(0xFF007AFF), Color(0xFF5856D6), Color(0xFFAF52DE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      cardGradient: LinearGradient(
        colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      lightGradient: LinearGradient(
        colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      primary: Color(0xFF007AFF),
      secondary: Color(0xFF5856D6),
      accent: Color(0xFFAF52DE),
    ),
    BusinessType.automobile: BusinessConfig(
      type: BusinessType.automobile,
      label: 'Auto Parts',
      labelBn: 'অটো পার্টস',
      gradient: LinearGradient(
        colors: [Color(0xFFFF3B30), Color(0xFFFF9500), Color(0xFFFFCC00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      cardGradient: LinearGradient(
        colors: [Color(0xFFFF3B30), Color(0xFFFF9500)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      lightGradient: LinearGradient(
        colors: [Color(0xFFFFEBEE), Color(0xFFFFF3E0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      primary: Color(0xFFFF3B30),
      secondary: Color(0xFFFF9500),
      accent: Color(0xFFFFCC00),
    ),
    BusinessType.garments: BusinessConfig(
      type: BusinessType.garments,
      label: 'Garments',
      labelBn: 'পশাক',
      gradient: LinearGradient(
        colors: [Color(0xFFAF52DE), Color(0xFFFF2D55), Color(0xFFFF9500)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      cardGradient: LinearGradient(
        colors: [Color(0xFFAF52DE), Color(0xFFFF2D55)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      lightGradient: LinearGradient(
        colors: [Color(0xFFF3E5F5), Color(0xFFFFE4E1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      primary: Color(0xFFAF52DE),
      secondary: Color(0xFFFF2D55),
      accent: Color(0xFFFF9500),
    ),
    BusinessType.electronics: BusinessConfig(
      type: BusinessType.electronics,
      label: 'Electronics',
      labelBn: 'ইলেকট্রনিক্স',
      gradient: LinearGradient(
        colors: [Color(0xFF5AC8FA), Color(0xFF007AFF), Color(0xFF5856D6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      cardGradient: LinearGradient(
        colors: [Color(0xFF5AC8FA), Color(0xFF007AFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      lightGradient: LinearGradient(
        colors: [Color(0xFFE0F7FA), Color(0xFFE3F2FD)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      primary: Color(0xFF5AC8FA),
      secondary: Color(0xFF007AFF),
      accent: Color(0xFF5856D6),
    ),
    BusinessType.hardware: BusinessConfig(
      type: BusinessType.hardware,
      label: 'Hardware',
      labelBn: 'হার্ডওয়্যার',
      gradient: LinearGradient(
        colors: [Color(0xFFFF9500), Color(0xFFFFCC00), Color(0xFF34C759)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      cardGradient: LinearGradient(
        colors: [Color(0xFFFF9500), Color(0xFFFFCC00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      lightGradient: LinearGradient(
        colors: [Color(0xFFFFF3E0), Color(0xFFE8F5E9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      primary: Color(0xFFFF9500),
      secondary: Color(0xFFFFCC00),
      accent: Color(0xFF34C759),
    ),
    BusinessType.general: BusinessConfig(
      type: BusinessType.general,
      label: 'General',
      labelBn: 'জেনারেল',
      gradient: LinearGradient(
        colors: [Color(0xFF8E8E93), Color(0xFF636366), Color(0xFF48484A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      cardGradient: LinearGradient(
        colors: [Color(0xFF8E8E93), Color(0xFF636366)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      lightGradient: LinearGradient(
        colors: [Color(0xFFF5F5F5), Color(0xFFEEEEEE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      primary: Color(0xFF8E8E93),
      secondary: Color(0xFF636366),
      accent: Color(0xFF48484A),
    ),
    BusinessType.custom: BusinessConfig(
      type: BusinessType.custom,
      label: 'Custom',
      labelBn: 'কাস্টম',
      gradient: LinearGradient(
        colors: [Color(0xFF5856D6), Color(0xFF007AFF), Color(0xFF34C759)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      cardGradient: LinearGradient(
        colors: [Color(0xFF5856D6), Color(0xFF007AFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      lightGradient: LinearGradient(
        colors: [Color(0xFFE8EAF6), Color(0xFFE3F2FD)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      primary: Color(0xFF5856D6),
      secondary: Color(0xFF007AFF),
      accent: Color(0xFF34C759),
    ),
  };

  static BusinessConfig of(BusinessType type) => configs[type]!;
}
