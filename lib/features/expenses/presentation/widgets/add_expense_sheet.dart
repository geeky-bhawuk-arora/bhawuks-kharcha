import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pocket_ledger/features/expenses/data/repositories/expense_repository.dart';

class AddExpenseSheet extends HookConsumerWidget {
  const AddExpenseSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountController = useTextEditingController();
    final placeController = useTextEditingController();
    final notesController = useTextEditingController();
    final date = useState(DateTime.now());
    final category = useState('Food');

    final categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health'];

    void saveExpense() async {
      final amount = double.tryParse(amountController.text);
      if (amount == null || amount <= 0) return;

      await ref.read(expenseRepositoryProvider).addExpense(
            amount: amount,
            category: category.value,
            place: placeController.text.isEmpty ? 'Unknown' : placeController.text,
            date: date.value,
            notes: notesController.text,
          );
      
      if (context.mounted) Navigator.pop(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        actions: [
          IconButton(
            onPressed: saveExpense,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: Theme.of(context).textTheme.headlineLarge,
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixIcon: Icon(Icons.attach_money),
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            TextField(
              controller: placeController,
              decoration: const InputDecoration(
                labelText: 'Place / Store',
                prefixIcon: Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: categories.map((cat) {
                final isSelected = category.value == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) category.value = cat;
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat.yMMMd().format(date.value)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date.value,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) date.value = picked;
              },
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.note_add),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
