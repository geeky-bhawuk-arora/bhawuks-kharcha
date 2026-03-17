import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pocket_ledger/features/expenses/data/models/expense_model.dart';
import 'package:pocket_ledger/features/expenses/data/repositories/expense_repository.dart';

class AddExpenseSheet extends HookConsumerWidget {
  final Expense? expense;
  final int? index;

  const AddExpenseSheet({super.key, this.expense, this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = expense != null;
    final amountController = useTextEditingController(text: isEditing ? expense!.amount.toString() : '');
    final placeController = useTextEditingController(text: isEditing ? expense!.place : '');
    final notesController = useTextEditingController(text: isEditing ? expense!.notes : '');
    final date = useState(isEditing ? expense!.date : DateTime.now());
    final category = useState(isEditing ? expense!.category : 'Food');

    final categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health'];

    void handleSave() async {
      final amount = double.tryParse(amountController.text);
      if (amount == null || amount <= 0) return;

      if (isEditing) {
        await ref.read(expenseRepositoryProvider).updateExpense(
              index: index!,
              remoteId: expense!.remoteId,
              amount: amount,
              category: category.value,
              place: placeController.text.isEmpty ? 'Unknown' : placeController.text,
              date: date.value,
              notes: notesController.text,
            );
      } else {
        await ref.read(expenseRepositoryProvider).addExpense(
              amount: amount,
              category: category.value,
              place: placeController.text.isEmpty ? 'Unknown' : placeController.text,
              date: date.value,
              notes: notesController.text,
            );
      }
      
      if (context.mounted) Navigator.pop(context);
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Transaction' : 'New Transaction',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: handleSave,
                    icon: const Icon(Icons.check_circle, color: Colors.blueAccent, size: 32),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Amount Input
              TextField(
                controller: amountController,
                autofocus: !isEditing,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                  prefixIcon: const Icon(Icons.attach_money, color: Colors.blueAccent, size: 36),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 10),
              // Place Input
              _GlassInput(
                controller: placeController,
                hint: 'Where did you spend?',
                icon: Icons.store_rounded,
              ),
              const SizedBox(height: 20),
              const Text('Category', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = category.value == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) category.value = cat;
                    },
                    selectedColor: Colors.blueAccent,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.white12),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date.value,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Colors.blueAccent,
                            surface: Color(0xFF1E1B4B),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) date.value = picked;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(date.value),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Notes Input
              _GlassInput(
                controller: notesController,
                hint: 'Add a note...',
                icon: Icons.notes_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _GlassInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: Icon(icon, color: Colors.blueAccent.withOpacity(0.7), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
