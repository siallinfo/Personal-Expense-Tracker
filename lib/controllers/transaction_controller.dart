import 'package:flutter/foundation.dart';

import '../data/transaction_repository.dart';
import '../models/transaction_record.dart';

class TransactionController extends ChangeNotifier {
  TransactionController(this._repository);

  final TransactionRepository _repository;
  List<TransactionRecord> _transactions = [];
  bool _isLoading = true;
  Object? _loadError;
  bool _isDisposed = false;

  List<TransactionRecord> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  Object? get loadError => _loadError;

  double get totalIncome => _transactions
      .where((transaction) => transaction.kind == TransactionKind.income)
      .fold(0, (total, transaction) => total + transaction.amount);

  double get totalExpense => _transactions
      .where((transaction) => transaction.kind == TransactionKind.expense)
      .fold(0, (total, transaction) => total + transaction.amount);

  double get balance => totalIncome - totalExpense;

  Future<void> loadTransactions() async {
    _isLoading = true;
    _loadError = null;
    _notifyIfActive();

    try {
      _transactions = await _repository.getAll();
    } catch (error) {
      _loadError = error;
    } finally {
      _isLoading = false;
      _notifyIfActive();
    }
  }

  Future<void> saveTransaction(TransactionRecord transaction) async {
    if (transaction.id == null) {
      await _repository.insert(transaction);
    } else {
      await _repository.update(transaction);
    }
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await _repository.delete(id);
    await loadTransactions();
  }

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
