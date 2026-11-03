import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_record.dart';

class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.name,
    required this.unit,
  });

  final String code;
  final String name;
  final String unit;

  String get label => '$code - $name ($unit)';
}

const currencyOptions = [
  CurrencyOption(code: 'BDT', name: 'Bangladeshi Taka', unit: 'BDT'),
  CurrencyOption(code: 'USD', name: 'US Dollar', unit: '\u0024'),
  CurrencyOption(code: 'INR', name: 'Indian Rupee', unit: '\u20B9'),
  CurrencyOption(code: 'EUR', name: 'Euro', unit: '\u20AC'),
  CurrencyOption(code: 'GBP', name: 'British Pound', unit: '\u00A3'),
];

class AppSettingsController extends ChangeNotifier {
  static const _currencyKey = 'currency_code';
  static const _incomeCategoriesKey = 'income_categories';
  static const _expenseCategoriesKey = 'expense_categories';

  static const _defaultIncomeCategories = [
    'Salary',
    'Freelance',
    'Business',
    'Investment',
    'Gift',
    'Other',
  ];
  static const _defaultExpenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Entertainment',
    'Other',
  ];

  String _currencyCode = 'BDT';
  List<String> _incomeCategories = _defaultIncomeCategories;
  List<String> _expenseCategories = _defaultExpenseCategories;
  Object? _loadError;

  String get currencyCode => _currencyCode;
  String get currencyUnit =>
      currencyOptions.firstWhere((option) => option.code == _currencyCode).unit;
  Object? get loadError => _loadError;

  List<String> categoriesFor(TransactionKind kind) => List.unmodifiable(
    kind == TransactionKind.income ? _incomeCategories : _expenseCategories,
  );

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedCurrency = preferences.getString(_currencyKey);
      if (currencyOptions.any((option) => option.code == savedCurrency)) {
        _currencyCode = savedCurrency!;
      }
      _incomeCategories =
          preferences.getStringList(_incomeCategoriesKey) ??
          _defaultIncomeCategories;
      _expenseCategories =
          preferences.getStringList(_expenseCategoriesKey) ??
          _defaultExpenseCategories;
      _loadError = null;
    } catch (error) {
      _loadError = error;
    }
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    if (!currencyOptions.any((option) => option.code == code)) {
      throw ArgumentError.value(code, 'code', 'Unsupported currency');
    }
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(_currencyKey, code)) {
      throw StateError('Could not save currency preference');
    }
    _currencyCode = code;
    notifyListeners();
  }

  Future<void> addCategory(TransactionKind kind, String category) async {
    final normalizedCategory = category.trim();
    if (normalizedCategory.isEmpty) {
      throw ArgumentError.value(
        category,
        'category',
        'Category cannot be empty',
      );
    }

    final categories = List<String>.of(categoriesFor(kind));
    if (categories.any(
      (existing) => existing.toLowerCase() == normalizedCategory.toLowerCase(),
    )) {
      throw ArgumentError.value(
        category,
        'category',
        'Category already exists',
      );
    }
    categories.add(normalizedCategory);
    await _saveCategories(kind, categories);
  }

  Future<void> removeCategory(TransactionKind kind, String category) async {
    final categories = List<String>.of(categoriesFor(kind))..remove(category);
    await _saveCategories(kind, categories);
  }

  Future<void> _saveCategories(
    TransactionKind kind,
    List<String> categories,
  ) async {
    final key = kind == TransactionKind.income
        ? _incomeCategoriesKey
        : _expenseCategoriesKey;
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setStringList(key, categories)) {
      throw StateError('Could not save ${kind.label.toLowerCase()} categories');
    }
    if (kind == TransactionKind.income) {
      _incomeCategories = categories;
    } else {
      _expenseCategories = categories;
    }
    notifyListeners();
  }
}
