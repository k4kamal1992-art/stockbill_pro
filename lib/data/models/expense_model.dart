import 'package:flutter/material.dart';

class ExpenseModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final String? description;
  final String? shopId;
  final String? staffId;
  final DateTime expenseDate;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    this.description,
    this.shopId,
    this.staffId,
    required this.expenseDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'description': description,
      'shopId': shopId,
      'staffId': staffId,
      'expenseDate': expenseDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String?,
      shopId: map['shopId'] as String?,
      staffId: map['staffId'] as String?,
      expenseDate: DateTime.parse(map['expenseDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

class ExpenseCategory {
  static const String rent = 'ভাড়া';
  static const String electricity = 'বিদ্যুৎ';
  static const String salary = 'বেতন';
  static const String transport = 'পরিবহন';
  static const String maintenance = 'মেরামত';
  static const String supplies = 'সাপ্লাই';
  static const String marketing = 'মার্কেটিং';
  static const String other = 'অন্যান্য';

  static const List<String> all = [
    rent, electricity, salary, transport, maintenance, supplies, marketing, other,
  ];

  static IconData getIcon(String category) {
    switch (category) {
      case rent: return Icons.home_work;
      case electricity: return Icons.electrical_services;
      case salary: return Icons.people;
      case transport: return Icons.local_shipping;
      case maintenance: return Icons.build;
      case supplies: return Icons.inventory;
      case marketing: return Icons.campaign;
      default: return Icons.receipt;
    }
  }
}

