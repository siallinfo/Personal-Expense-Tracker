import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_expense_tracker/controllers/app_settings_controller.dart';
import 'package:personal_expense_tracker/data/transaction_repository.dart';
import 'package:personal_expense_tracker/main.dart';
import 'package:personal_expense_tracker/models/transaction_record.dart';
import 'package:personal_expense_tracker/utils/currency_formatter.dart';
import 'package:personal_expense_tracker/utils/transaction_filters.dart';

void main() {
  test('saves currency and transaction-type-specific categories', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppSettingsController();
    await controller.load();
    await controller.setCurrency('USD');
    await controller.addCategory(TransactionKind.income, 'Bonus');

    expect(controller.currencyCode, 'USD');
    expect(controller.categoriesFor(TransactionKind.income), contains('Bonus'));
    expect(
      controller.categoriesFor(TransactionKind.expense),
      isNot(contains('Bonus')),
    );

    final reloaded = AppSettingsController();
    await reloaded.load();
    expect(reloaded.currencyCode, 'USD');
    expect(reloaded.categoriesFor(TransactionKind.income), contains('Bonus'));
    controller.dispose();
    reloaded.dispose();
  });

  test('formats BDT amounts using lakh and crore grouping', () {
    expect(formatBdtCurrency(1234.5), 'BDT 1,234.50');
    expect(formatBdtCurrency(123456.78), 'BDT 1,23,456.78');
    expect(formatBdtCurrency(123456789.01), 'BDT 12,34,56,789.01');
    expect(formatBdtCurrency(-123456.78), 'BDT -1,23,456.78');
    expect(
      formatBdtTransactionAmount(2500, isIncome: true),
      '(+) BDT 2,500.00',
    );
    expect(
      formatBdtTransactionAmount(2500, isIncome: false),
      '(-) BDT 2,500.00',
    );
  });

  test('filters transactions by inclusive date range and transaction type', () {
    final transactions = [
      TransactionRecord(
        id: 1,
        title: 'Before range',
        amount: 10,
        category: 'Food',
        kind: TransactionKind.expense,
        date: DateTime(2026, 10, 31, 23, 59),
      ),
      TransactionRecord(
        id: 2,
        title: 'Range start',
        amount: 20,
        category: 'Food',
        kind: TransactionKind.expense,
        date: DateTime(2026, 11, 1, 23, 59),
      ),
      TransactionRecord(
        id: 3,
        title: 'Range end',
        amount: 30,
        category: 'Salary',
        kind: TransactionKind.income,
        date: DateTime(2026, 11, 3, 12),
      ),
      TransactionRecord(
        id: 4,
        title: 'After range',
        amount: 40,
        category: 'Food',
        kind: TransactionKind.expense,
        date: DateTime(2026, 11, 4),
      ),
    ];

    final dateFiltered = filterTransactions(
      transactions: transactions,
      startDate: DateTime(2026, 11, 1),
      endDate: DateTime(2026, 11, 3),
    );
    expect(dateFiltered.map((transaction) => transaction.id), [2, 3]);

    final expenseFiltered = filterTransactions(
      transactions: transactions,
      kind: TransactionKind.expense,
      startDate: DateTime(2026, 11, 1),
      endDate: DateTime(2026, 11, 3),
    );
    expect(expenseFiltered.map((transaction) => transaction.id), [2]);
  });

  testWidgets('dashboard displays totals and recent transactions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = FakeTransactionRepository([
      TransactionRecord(
        id: 1,
        title: 'Monthly salary',
        amount: 1200,
        category: 'Salary',
        kind: TransactionKind.income,
        date: DateTime(2026, 11, 1),
      ),
      TransactionRecord(
        id: 2,
        title: 'Lunch',
        amount: 35,
        category: 'Food',
        kind: TransactionKind.expense,
        date: DateTime(2026, 11, 2),
      ),
    ]);

    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.text('BDT 1,200.00'), findsOneWidget);
    expect(find.text('BDT 35.00'), findsOneWidget);
    expect(find.text('BDT 1,165.00'), findsOneWidget);
    expect(find.text('Monthly salary'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
  });

  testWidgets(
    'transactions can be viewed in separate income and expense lists',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repository = FakeTransactionRepository([
        TransactionRecord(
          id: 1,
          title: 'Monthly salary',
          amount: 1200,
          category: 'Salary',
          kind: TransactionKind.income,
          date: DateTime(2026, 11, 1),
        ),
        TransactionRecord(
          id: 2,
          title: 'Lunch',
          amount: 35,
          category: 'Food',
          kind: TransactionKind.expense,
          date: DateTime(2026, 11, 2),
        ),
      ]);

      await tester.pumpWidget(MyApp(repository: repository));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transactions').last);
      await tester.pumpAndSettle();

      expect(find.text('Monthly salary'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);

      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Monthly salary'), findsNothing);

      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();
      expect(find.text('Monthly salary'), findsOneWidget);
      expect(find.text('Lunch'), findsNothing);

      await tester.tap(find.text('Filter by date'));
      await tester.pumpAndSettle();
      expect(find.text('Filter transactions by date'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Clear date filter'), findsOneWidget);
    },
  );

  testWidgets('date filter displays income and expense totals for the range', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final today = DateUtils.dateOnly(DateTime.now());
    final repository = FakeTransactionRepository([
      TransactionRecord(
        id: 1,
        title: 'Today income',
        amount: 2500,
        category: 'Salary',
        kind: TransactionKind.income,
        date: today,
      ),
      TransactionRecord(
        id: 2,
        title: 'Today expense',
        amount: 400,
        category: 'Food',
        kind: TransactionKind.expense,
        date: today,
      ),
      TransactionRecord(
        id: 3,
        title: 'Yesterday income',
        amount: 7000,
        category: 'Salary',
        kind: TransactionKind.income,
        date: today.subtract(const Duration(days: 1)),
      ),
    ]);

    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transactions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filter by date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Income total'), findsOneWidget);
    expect(find.text('Expense total'), findsOneWidget);
    expect(find.text('BDT 2,500.00'), findsOneWidget);
    expect(find.text('BDT 400.00'), findsOneWidget);
    expect(find.text('BDT 7,000.00'), findsNothing);
  });

  testWidgets('transaction form validates required fields', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MyApp(repository: FakeTransactionRepository([])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add transaction'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save transaction'));
    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a title'), findsOneWidget);
    expect(find.text('Enter a valid positive amount'), findsOneWidget);
    expect(find.text('Select a category'), findsOneWidget);
    expect(find.text('Select transaction type'), findsOneWidget);
  });

  testWidgets('drawer settings add a category after selecting its type', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MyApp(repository: FakeTransactionRepository([])));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(
      find.text('Select Expense or Income to manage categories.'),
      findsOneWidget,
    );
    expect(find.text('Add expense category'), findsNothing);

    final typeField = find.byType(DropdownButtonFormField<TransactionKind>);
    await tester.tap(typeField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Income').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add income category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bonus');
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).last, const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('Bonus'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
  });

  testWidgets('can create, edit, and delete a transaction', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = FakeTransactionRepository([]);
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add transaction'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Groceries');
    await tester.enterText(find.byType(TextFormField).at(1), '25');

    final typeField = find.byType(DropdownButtonFormField<TransactionKind>);
    await tester.ensureVisible(typeField);
    await tester.tap(typeField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expense').last);
    await tester.pumpAndSettle();

    final categoryField = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(categoryField);
    await tester.tap(categoryField);
    await tester.pumpAndSettle();
    expect(find.text('Salary'), findsNothing);
    expect(find.text('Food'), findsOneWidget);
    await tester.tap(find.text('Food').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save transaction'));
    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('(-) BDT 25.00'), findsOneWidget);
    expect(find.text('BDT 25.00'), findsOneWidget);

    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '40');
    await tester.ensureVisible(find.text('Save transaction'));
    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();
    expect(find.text('(-) BDT 40.00'), findsOneWidget);
    expect(find.text('BDT 40.00'), findsOneWidget);

    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();
    expect(find.text('Transaction details'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('BDT 0.00'), findsNWidgets(3));
  });
}

class FakeTransactionRepository implements TransactionRepository {
  FakeTransactionRepository(Iterable<TransactionRecord> transactions)
    : _transactions = transactions.toList();

  final List<TransactionRecord> _transactions;
  var _nextId = 1;

  @override
  Future<List<TransactionRecord>> getAll() async =>
      List.unmodifiable(_transactions);

  @override
  Future<int> insert(TransactionRecord transaction) async {
    final id = _nextId++;
    _transactions.add(transaction.copyWith(id: id));
    return id;
  }

  @override
  Future<void> update(TransactionRecord transaction) async {
    final index = _transactions.indexWhere((item) => item.id == transaction.id);
    if (index < 0) throw StateError('Transaction not found');
    _transactions[index] = transaction;
  }

  @override
  Future<void> delete(int id) async {
    _transactions.removeWhere((transaction) => transaction.id == id);
  }
}
