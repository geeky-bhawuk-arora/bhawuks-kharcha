import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
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

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(
          top: BorderSide(color: Color(0xFF1F1F1F), width: 1),
          left: BorderSide(color: Color(0xFF1F1F1F), width: 1),
          right: BorderSide(color: Color(0xFF1F1F1F), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'EXECUTE: EDIT_TRANS' : 'EXECUTE: NEW_TRANS',
                  style: GoogleFonts.jetbrainsMono(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                IconButton(
                  onPressed: handleSave,
                  icon: const Icon(Icons.terminal_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Amount Input
            TextField(
              controller: amountController,
              autofocus: !isEditing,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: -2,
              ),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: GoogleFonts.robotoMono(color: const Color(0xFF1F1F1F)),
                prefixText: '$ ',
                prefixStyle: GoogleFonts.robotoMono(color: const Color(0xFF888888), fontSize: 32),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: Color(0xFF1F1F1F)),
            const SizedBox(height: 24),
            // Place Input
            _TerminalInput(
              controller: placeController,
              label: 'SOURCE/LOCATION',
              hint: 'ENTER_DESTINATION',
            ),
            const SizedBox(height: 24),
            Text(
              '> CLASSIFICATION',
              style: GoogleFonts.jetbrainsMono(
                color: const Color(0xFF888888),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = category.value == cat;
                return GestureDetector(
                  onTap: () => category.value = cat,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? Colors.white : const Color(0xFF1F1F1F),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      cat.toUpperCase(),
                      style: GoogleFonts.jetbrainsMono(
                        color: isSelected ? Colors.black : const Color(0xFF888888),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
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
                          primary: Colors.white,
                          onPrimary: Colors.black,
                          surface: Color(0xFF0A0A0A),
                          onSurface: Colors.white,
                        ),
                        dialogBackgroundColor: const Color(0xFF0A0A0A),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) date.value = picked;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF000000),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF1F1F1F)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Color(0xFF888888), size: 16),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('yyyy.MM.dd').format(date.value),
                      style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      '[ CHANGE ]',
                      style: GoogleFonts.jetbrainsMono(color: const Color(0xFF1F1F1F), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Notes Input
            _TerminalInput(
              controller: notesController,
              label: 'METADATA/NOTES',
              hint: 'ADDITIONAL_RECORDS',
              maxLines: 2,
            ),
            const SizedBox(height: 40),
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? 'UPDATE_ENTRY' : 'COMMIT_ENTRY',
                  style: GoogleFonts.jetbrainsMono(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TerminalInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  const _TerminalInput({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '> $label',
          style: GoogleFonts.jetbrainsMono(
            color: const Color(0xFF888888),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF000000),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF1F1F1F)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.jetbrainsMono(color: Colors.white, fontSize: 14),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.jetbrainsMono(color: const Color(0xFF1F1F1F)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
