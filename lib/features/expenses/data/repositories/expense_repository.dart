import 'dart:async';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pocket_ledger/features/expenses/data/models/expense_model.dart';
import 'package:pocket_ledger/main.dart';
import 'package:uuid/uuid.dart';

final expenseRepositoryProvider = Provider((ref) {
  final box = ref.watch(expenseBoxProvider);
  final supabase = sb.Supabase.instance.client;
  return ExpenseRepository(box, supabase);
});

class ExpenseRepository {
  final Box<Expense> _box;
  final sb.SupabaseClient _supabase;

  ExpenseRepository(this._box, this._supabase);

  Stream<List<Expense>> watchExpenses() async* {
    // 1. Emit local data immediately
    yield getExpenses();

    // 2. Full sync from Supabase (reconcile local ↔ remote, remove stale local entries)
    await fullSyncFromSupabase();
    yield getExpenses();

    // 3. Set up a real-time listener for changes from other devices
    final user = _supabase.auth.currentUser;
    if (user != null) {
      // Create a StreamController to merge Hive + real-time events
      final controller = StreamController<List<Expense>>();
      
      // Listen to Supabase real-time changes
      final channel = _supabase.channel('expenses_realtime')
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          filter: sb.PostgresChangeFilter(
            type: sb.PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) async {
            // On any remote change, do a full re-sync
            await fullSyncFromSupabase();
            if (!controller.isClosed) {
              controller.add(getExpenses());
            }
          },
        )
        .subscribe();

      // Also listen to local Hive changes
      final hiveSubscription = _box.watch().listen((_) {
        if (!controller.isClosed) {
          controller.add(getExpenses());
        }
      });

      yield* controller.stream;

      // Cleanup
      hiveSubscription.cancel();
      controller.close();
      _supabase.removeChannel(channel);
    } else {
      // Fallback: just watch Hive if no user
      await for (final _ in _box.watch()) {
        yield getExpenses();
      }
    }
  }

  /// Full reconciliation: pull all remote records, update local, and remove
  /// any local entries that no longer exist on the server (deleted from another device).
  Future<void> fullSyncFromSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Push unsynced local entries first
      await syncOfflineExpenses();

      // 2. Fetch all remote records
      final List<dynamic> data = await _supabase
          .from('expenses')
          .select()
          .eq('user_id', user.id);

      // Build a set of remote IDs
      final remoteIds = <String>{};
      for (var item in data) {
        remoteIds.add(item['id'] as String);
      }

      // 3. Update or insert remote records into Hive
      for (var item in data) {
        final remoteId = item['id'] as String;
        final existingIndex = _box.values.toList().indexWhere((e) => e.remoteId == remoteId);

        final expense = Expense(
          remoteId: remoteId,
          amount: (item['amount'] as num).toDouble(),
          category: item['category'],
          place: item['place'] ?? 'Unknown',
          date: DateTime.parse(item['date']),
          notes: item['notes'] ?? '',
          userId: item['user_id'],
          synced: true,
        );

        if (existingIndex != -1) {
          await _box.putAt(existingIndex, expense);
        } else {
          await _box.add(expense);
        }
      }

      // 4. Remove local entries that don't exist on the server anymore
      //    This is the KEY fix for multi-device sync!
      final localEntries = _box.values.toList();
      for (int i = localEntries.length - 1; i >= 0; i--) {
        final localEntry = localEntries[i];
        // Only remove synced entries that are missing from remote
        // Keep unsynced entries (they haven't been pushed yet)
        if (localEntry.synced && !remoteIds.contains(localEntry.remoteId)) {
          await _box.deleteAt(i);
        }
      }
    } catch (e) {
      print('PocketLedger Sync Error: $e');
    }
  }

  List<Expense> getExpenses() {
    final list = _box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
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

    await _box.add(expense);

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
      await expense.save();
    } catch (e) {
      // Will be synced later via syncOfflineExpenses
    }
  }

  Future<void> updateExpense({
    required int index,
    required String remoteId,
    required double amount,
    required String category,
    required String place,
    required DateTime date,
    required String notes,
  }) async {
    final expense = _box.getAt(index);
    if (expense == null) return;

    expense.amount = amount;
    expense.category = category;
    expense.place = place;
    expense.date = date;
    expense.notes = notes;
    expense.synced = false;

    await expense.save();

    try {
      await _supabase.from('expenses').update({
        'amount': amount,
        'category': category,
        'place': place,
        'date': date.toIso8601String(),
        'notes': notes,
      }).match({'id': remoteId});

      expense.synced = true;
      await expense.save();
    } catch (e) {}
  }

  Future<void> deleteExpense(int localIndex, String remoteId) async {
    await _box.deleteAt(localIndex);
    try {
      await _supabase.from('expenses').delete().match({'id': remoteId});
    } catch (_) {}
  }

  Future<void> syncOfflineExpenses() async {
    final unsynced = _box.values.where((e) => !e.synced).toList();
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
        await expense.save();
      } catch (_) {}
    }
  }
}
