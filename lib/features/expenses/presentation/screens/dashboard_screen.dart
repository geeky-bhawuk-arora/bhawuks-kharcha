import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocket_ledger/features/expenses/data/models/expense_model.dart';
import 'package:pocket_ledger/features/expenses/data/repositories/expense_repository.dart';
import 'package:pocket_ledger/features/expenses/presentation/widgets/add_expense_sheet.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pocket_ledger/features/auth/presentation/auth_notifier.dart';

class DashboardScreen extends HookConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        centerTitle: false,
        title: Text(
          'POCKET_LEDGER // CORE',
          style: GoogleFonts.jetbrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF1F1F1F), height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Color(0xFF888888), size: 18),
            onPressed: () => ref.read(expenseRepositoryProvider).syncOfflineExpenses(),
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Color(0xFF888888), size: 18),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ArchitectedBalanceCard(expenses),
                    const SizedBox(height: 32),
                    _HeaderSection(label: 'SYSTEM_INSIGHTS'),
                    const SizedBox(height: 16),
                    _MonochromaticBentoGrid(expenses),
                    const SizedBox(height: 32),
                    _HeaderSection(label: 'RECENT_LOGS'),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (expenses.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    '> NO_RECORDS_FOUND',
                    style: GoogleFonts.jetbrainsMono(color: const Color(0xFF1F1F1F), fontSize: 12),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final expense = expenses[index];
                      return _ArchitectedTransactionItem(
                        expense: expense,
                        index: index,
                      );
                    },
                    childCount: expenses.length,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 64),
                child: Center(
                  child: Text(
                    'MADE WITH ❤️ BY BHAWUK\n[ VERSION 1.0.0 // STABLE ]',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetbrainsMono(
                      fontSize: 9,
                      color: const Color(0xFF1F1F1F),
                      letterSpacing: 2,
                      height: 1.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        loading: () => const _SystemLoader(),
        error: (err, _) => Center(
          child: Text(
            'CRITICAL_SYSTEM_ERROR: $err',
            style: GoogleFonts.jetbrainsMono(color: Colors.redAccent, fontSize: 12),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddExpenseSheet(),
          );
        },
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: const Icon(Icons.add, color: Colors.black, size: 24),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String label;
  const _HeaderSection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '[ $label ]',
          style: GoogleFonts.jetbrainsMono(
            color: const Color(0xFF888888),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: const Color(0xFF0A0A0A))),
      ],
    );
  }
}

class _SystemLoader extends StatelessWidget {
  const _SystemLoader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 1,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'INITIALIZING_CORE_SYSTEM...',
            style: GoogleFonts.jetbrainsMono(
              color: const Color(0xFF1F1F1F),
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

final expenseStreamProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchExpenses();
});

class _ArchitectedBalanceCard extends StatelessWidget {
  final List<Expense> expenses;
  const _ArchitectedBalanceCard(this.expenses);

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final indianRupeeFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: const Color(0xFF1F1F1F), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '> TOTAL_CAPITAL_EXPOSURE',
            style: GoogleFonts.jetbrainsMono(color: const Color(0xFF888888), fontSize: 9, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          Text(
            indianRupeeFormat.format(total),
            style: GoogleFonts.robotoMono(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _TerminalTag(label: 'NET_STATUS: STABLE', color: Colors.greenAccent),
              const SizedBox(width: 12),
              _TerminalTag(label: 'ENCRYPTION: AES-256', color: const Color(0xFF1F1F1F)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TerminalTag extends StatelessWidget {
  final String label;
  final Color color;
  const _TerminalTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetbrainsMono(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MonochromaticBentoGrid extends StatelessWidget {
  final List<Expense> expenses;
  const _MonochromaticBentoGrid(this.expenses);

  @override
  Widget build(BuildContext context) {
    final categoryTotals = <String, double>{};
    for (var e in expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final pieSections = sortedCategories.take(3).map((e) {
      final opacity = (1.0 - (sortedCategories.indexOf(e) * 0.3)).clamp(0.2, 1.0);
      return PieChartSectionData(
        value: e.value,
        color: Colors.white.withOpacity(opacity),
        radius: 4,
        showTitle: false,
      );
    }).toList();

    if (pieSections.isEmpty) {
      pieSections.add(PieChartSectionData(value: 1, color: const Color(0xFF1F1F1F), radius: 4, showTitle: false));
    }

    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => DateTime(now.year, now.month, now.day - (6 - i)));
    final dailyTotals = <DateTime, double>{};
    for (var date in last7Days) dailyTotals[date] = 0;
    
    for (var e in expenses) {
      final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
      if (dailyTotals.containsKey(expenseDate)) {
        dailyTotals[expenseDate] = dailyTotals[expenseDate]! + e.amount;
      }
    }

    final barGroups = dailyTotals.entries.map((e) {
      final index = dailyTotals.keys.toList().indexOf(e.key);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: e.value,
            color: index == 6 ? Colors.white : const Color(0xFF1F1F1F),
            width: 6,
            borderRadius: BorderRadius.circular(1),
          ),
        ],
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _BentoBox(
            title: 'SEGMENT_AUTH',
            child: PieChart(
              PieChartData(
                sections: pieSections,
                centerSpaceRadius: 20,
                sectionsSpace: 4,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: _BentoBox(
            title: 'VOLATILITY_LOG',
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BentoBox extends StatelessWidget {
  final String title;
  final Widget child;
  const _BentoBox({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: const Color(0xFF1F1F1F), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '> $title',
            style: GoogleFonts.jetbrainsMono(
              color: const Color(0xFF888888),
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ArchitectedTransactionItem extends ConsumerWidget {
  final Expense expense;
  final int index;
  const _ArchitectedTransactionItem({required this.expense, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indianRupeeFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(expense.remoteId),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          ref.read(expenseRepositoryProvider).deleteExpense(index, expense.remoteId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('> LOG_ENTRY_DELETED: ${expense.remoteId}'),
              backgroundColor: const Color(0xFF1F1F1F),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
          ),
          child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
        ),
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddExpenseSheet(expense: expense, index: index),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              border: Border.all(color: const Color(0xFF1F1F1F), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 24,
                  color: Colors.white.withOpacity(0.2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.place.toUpperCase(),
                        style: GoogleFonts.jetbrainsMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expense.category.toUpperCase(),
                        style: GoogleFonts.jetbrainsMono(color: const Color(0xFF888888), fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      indianRupeeFormat.format(expense.amount),
                      style: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd.MM.yy').format(expense.date),
                      style: GoogleFonts.robotoMono(color: const Color(0xFF1F1F1F), fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
