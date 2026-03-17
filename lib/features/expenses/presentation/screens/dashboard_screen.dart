import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pocket_ledger/features/expenses/data/models/expense_model.dart';
import 'package:pocket_ledger/features/expenses/data/repositories/expense_repository.dart';
import 'package:pocket_ledger/features/expenses/presentation/widgets/add_expense_sheet.dart';
import 'package:animations/animations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pocket_ledger/features/auth/presentation/auth_notifier.dart';

class DashboardScreen extends HookConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseStreamProvider);
    final searchQuery = useState('');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('SpendWise'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authProvider.notifier).signOut(),
              ),
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () => ref.read(expenseRepositoryProvider).syncOfflineExpenses(),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _SummaryCards(expensesAsync.value ?? []),
                  const SizedBox(height: 16),
                  _CategoryPieChart(expensesAsync.value ?? []),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Transactions', style: Theme.of(context).textTheme.titleLarge),
                      TextButton(onPressed: () {}, child: const Text('See All')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          expensesAsync.when(
            data: (expenses) {
              final displayed = expenses.take(10).toList();
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final expense = displayed[index];
                    return Dismissible(
                      key: Key(expense.remoteId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        ref.read(expenseRepositoryProvider).deleteExpense(expense.id, expense.remoteId);
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(_getCategoryIcon(expense.category), size: 20),
                        ),
                        title: Text(expense.place),
                        subtitle: Text('${expense.category} • ${DateFormat.yMMMd().format(expense.date)}'),
                        trailing: Text(
                          NumberFormat.simpleCurrency().format(expense.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                  childCount: displayed.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (err, _) => SliverToBoxAdapter(child: Text('Error: $err')),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const AddExpenseSheet(),
          );
        },
        label: const Text('Add Expense'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food': return Icons.restaurant;
      case 'transport': return Icons.directions_bus;
      case 'shopping': return Icons.shopping_bag;
      case 'bills': return Icons.receipt_long;
      case 'entertainment': return Icons.movie;
      case 'health': return Icons.medical_services;
      default: return Icons.category;
    }
  }
}

final expenseStreamProvider = StreamProvider((ref) {
  return ref.watch(expenseRepositoryProvider).watchExpenses();
});

class _SummaryCards extends StatelessWidget {
  final List<Expense> expenses;
  const _SummaryCards(this.expenses);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayTotal = expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day)
        .fold(0.0, (sum, e) => sum + e.amount);

    final monthTotal = expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Today',
            amount: todayTotal,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'This Month',
            amount: monthTotal,
            color: Theme.of(context).colorScheme.secondaryContainer,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  const _SummaryCard({required this.title, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              NumberFormat.simpleCurrency().format(amount),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final List<Expense> expenses;
  const _CategoryPieChart(this.expenses);

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) return const SizedBox.shrink();

    final totals = <String, double>{};
    for (var e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }

    return SizedBox(
      height: 180,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: totals.entries.map((e) {
            return PieChartSectionData(
              value: e.value,
              title: e.key,
              radius: 50,
              titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              color: _getColor(e.key),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getColor(String category) {
    switch (category.toLowerCase()) {
      case 'food': return Colors.orange;
      case 'transport': return Colors.blue;
      case 'shopping': return Colors.purple;
      case 'bills': return Colors.red;
      case 'entertainment': return Colors.green;
      default: return Colors.grey;
    }
  }
}
