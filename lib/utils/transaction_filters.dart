import '../models/transaction_record.dart';

List<TransactionRecord> filterTransactions({
  required Iterable<TransactionRecord> transactions,
  TransactionKind? kind,
  DateTime? startDate,
  DateTime? endDate,
}) {
  final start = startDate == null
      ? null
      : DateTime(startDate.year, startDate.month, startDate.day);
  final end = endDate == null
      ? null
      : DateTime(endDate.year, endDate.month, endDate.day);

  return transactions.where((transaction) {
    if (kind != null && transaction.kind != kind) return false;

    final date = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );
    if (start != null && date.isBefore(start)) return false;
    if (end != null && date.isAfter(end)) return false;
    return true;
  }).toList();
}
