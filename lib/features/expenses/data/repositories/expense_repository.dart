import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pocket_ledger/features/expenses/data/models/expense_model.dart';
import 'package:pocket_ledger/main.dart';
import 'package:uuid/uuid.dart';

final expenseRepositoryProvider = Provider((ref) {
  final isar = ref.watch(isarProvider);
  final supabase = sb.Supabase.instance.client;
  return ExpenseRepository(isar, supabase);
});

class ExpenseRepository {
  final Isar _isar;
  final sb.SupabaseClient _supabase;

  ExpenseRepository(this._isar, this._supabase);

  Stream<List<Expense>> watchExpenses() {
    return _isar.expenses.where().sortByDateDesc().watch(fireImmediately: true);
  }

  Future<void> addExpense({
    required double amount,
    required String category,
    required String place,
    required DateTime date,
    required String notes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final remoteId = const Uuid().v4();
    final expense = Expense(
      remoteId: remoteId,
      amount: amount,
      category: category,
      place: place,
      date: date,
      notes: notes,
      userId: user.id,
    );

    await _isar.writeTxn(() async {
      await _isar.expenses.put(expense);
    });

    try {
      await _supabase.from('expenses').insert({
        'id': remoteId,
        'user_id': user.id,
        'amount': amount,
        'category': category,
        'place': place,
        'date': date.toIso8601String(),
        'notes': notes,
      });
      
      expense.synced = true;
      await _isar.writeTxn(() async {
        await _isar.expenses.put(expense);
      });
    } catch (e) {
      // Local copy remains with synced = false
    }
  }

  Future<void> deleteExpense(int localId, String remoteId) async {
    await _isar.writeTxn(() async {
      await _isar.expenses.delete(localId);
    });

    try {
      await _supabase.from('expenses').delete().match({'id': remoteId});
    } catch (e) {
      // Background delete or retry logic can be added here
    }
  }

  Future<void> syncOfflineExpenses() async {
    final unsynced = await _isar.expenses.filter().syncedEqualTo(false).findAll();
    if (unsynced.isEmpty) return;

    for (final expense in unsynced) {
      try {
        await _supabase.from('expenses').upsert({
          'id': expense.remoteId,
          'user_id': expense.userId,
          'amount': expense.amount,
          'category': expense.category,
          'place': expense.place,
          'date': expense.date.toIso8601String(),
          'notes': expense.notes,
        });
        expense.synced = true;
        await _isar.writeTxn(() => _isar.expenses.put(expense));
      } catch (_) {}
    }
  }
}
