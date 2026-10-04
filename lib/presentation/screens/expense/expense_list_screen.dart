import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/expense_model.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/shop_provider.dart';
import '../../widgets/common/glass_card.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String? _selectedCategory;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final shopId = context.read<ShopProvider>().currentShop?.id;
    await context.read<ExpenseProvider>().loadExpenses(shopId: shopId);
    await context.read<ExpenseProvider>().loadSummary(
      shopId: shopId,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  void _showAddExpenseSheet() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String category = ExpenseCategory.all.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'নতুন খরচ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: _inputDecoration('খরচের নাম', Icons.title),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('পরিমাণ (INR)', Icons.currency_rupee),
              ),
              const SizedBox(height: 12),
              const Text('ক্যাটেগরি:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ExpenseCategory.all.map((cat) {
                  final isSelected = category == cat;
                  return ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFF9500),
                    onSelected: (_) => setModalState(() => category = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: _inputDecoration('বিবরণ (ঐচ্ছিক)', Icons.notes),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9500), Color(0xFFFF6B35)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text);
                      if (titleController.text.isEmpty || amount == null || amount <= 0) return;
                      final shopId = context.read<ShopProvider>().currentShop?.id;
                      final expense = ExpenseModel(
                        id: const Uuid().v4(),
                        title: titleController.text.trim(),
                        category: category,
                        amount: amount,
                        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                        shopId: shopId,
                        expenseDate: DateTime.now(),
                        createdAt: DateTime.now(),
                      );
                      await context.read<ExpenseProvider>().addExpense(expense);
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'খরচ যোগ করুন',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.muted),
      filled: true,
      fillColor: const Color(0x1A8E8E93),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final expenses = expenseProvider.expenses;
    final summary = expenseProvider.summary;
    final total = expenseProvider.total;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('খরচের হিসাব', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: expenseProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Total expense card
                GlassCard(
                  borderColor: const Color(0x1AFF3B30),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'মোট খরচ (৩০ দিন)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.muted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'INR ${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFF3B30),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Category breakdown
                if (summary.isNotEmpty) ...[
                  const Text(
                    'ক্যাটেগরি অনুযায়ী',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ...summary.entries.map((e) => _buildCategoryRow(e.key, e.value, total)),
                  const SizedBox(height: 20),
                ],

                // Expense list
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'সাম্প্রতিক খরচ',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${expenses.length}টি',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (expenses.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('কোনো খরচ নেই', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  )
                else
                  ...expenses.map((e) => _buildExpenseCard(e)),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseSheet,
        backgroundColor: const Color(0xFFFF9500),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('খরচ যোগ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildCategoryRow(String category, double amount, double total) {
    final pct = total > 0 ? (amount / total * 100) : 0;
    final icon = ExpenseCategory.getIcon(category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(category, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Text(
                'INR ${amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? amount / total : 0,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF9500)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x1AFF3B30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_upward, color: Color(0xFFFF3B30), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${expense.category} • ${_formatDate(expense.expenseDate)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Text(
            '-INR ${expense.amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFF3B30),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
