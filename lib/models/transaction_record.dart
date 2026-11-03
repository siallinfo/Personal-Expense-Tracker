enum TransactionKind {
  income,
  expense;

  String get label => this == income ? 'Income' : 'Expense';
}

class TransactionRecord {
  const TransactionRecord({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.kind,
    required this.date,
  });

  final int? id;
  final String title;
  final double amount;
  final String category;
  final TransactionKind kind;
  final DateTime date;

  TransactionRecord copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    TransactionKind? kind,
    DateTime? date,
  }) {
    return TransactionRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      kind: kind ?? this.kind,
      date: date ?? this.date,
    );
  }

  Map<String, Object?> toDatabaseMap() => {
    'title': title,
    'amount': amount,
    'category': category,
    'type': kind.name,
    'date': date.toIso8601String(),
  };

  factory TransactionRecord.fromDatabaseMap(Map<String, Object?> map) {
    return TransactionRecord(
      id: map['id'] as int,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      kind: TransactionKind.values.byName(map['type'] as String),
      date: DateTime.parse(map['date'] as String),
    );
  }
}
