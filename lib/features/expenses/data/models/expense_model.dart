import 'package:isar/isar.dart';

part 'expense_model.g.dart';

@collection
class Expense {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  late double amount;
  late String category;
  late String place;
  late DateTime date;
  late String notes;
  
  @Index()
  late String userId;

  bool synced = false;

  Expense({
    required this.remoteId,
    required this.amount,
    required this.category,
    required this.place,
    required this.date,
    required this.notes,
    required this.userId,
    this.synced = false,
  });
}
