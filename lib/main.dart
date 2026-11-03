import 'package:flutter/material.dart';

import 'controllers/app_settings_controller.dart';
import 'controllers/transaction_controller.dart';
import 'data/transaction_repository.dart';
import 'models/transaction_record.dart';
import 'screens/transaction_details_screen.dart';
import 'screens/transaction_form_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/currency_formatter.dart';
import 'utils/transaction_filters.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.repository});

  final TransactionRepository? repository;

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF176B5B);
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          surface: const Color(0xFFF7F8F5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5EAE7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5EAE7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: seedColor, width: 1.5),
          ),
        ),
        useMaterial3: true,
      ),
      home: ExpenseHomePage(
        repository: repository ?? SqfliteTransactionRepository(),
      ),
    );
  }
}

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({
    super.key,
    required this.repository,
    this.settingsController,
  });

  final TransactionRepository repository;
  final AppSettingsController? settingsController;

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  late final TransactionController _controller;
  late final AppSettingsController _settingsController;
  int _selectedTab = 0;
  _TransactionFilter _transactionFilter = _TransactionFilter.all;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _controller = TransactionController(widget.repository);
    _controller.addListener(_onControllerChanged);
    _settingsController = widget.settingsController ?? AppSettingsController();
    _settingsController.addListener(_onControllerChanged);
    _controller.loadTransactions();
    _settingsController.load();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _settingsController
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _addTransaction() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(
          controller: _controller,
          settingsController: _settingsController,
        ),
      ),
    );
  }

  Future<void> _openTransaction(TransactionRecord transaction) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionDetailsScreen(
          transaction: transaction,
          controller: _controller,
          settingsController: _settingsController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Open navigation menu',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Expense Tracker',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      drawer: _buildDrawer(),
      body: _controller.loadError != null
          ? _LoadErrorView(onRetry: _controller.loadTransactions)
          : _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedTab == 0
          ? _buildDashboard()
          : _buildTransactionList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTransaction,
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() => _selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Transactions',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return NavigationDrawer(
      selectedIndex: _selectedTab,
      onDestinationSelected: (index) {
        Navigator.of(context).pop();
        if (index < 2) {
          setState(() => _selectedTab = index);
        } else if (index == 2) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SettingsScreen(
                controller: _settingsController,
                transactionController: _controller,
              ),
            ),
          );
        } else {
          showAboutDialog(
            context: context,
            applicationName: 'Expense Tracker',
            applicationVersion: '1.0.0',
            applicationIcon: const Icon(Icons.account_balance_wallet_rounded),
            children: const [
              Text('Track your income and expenses, all in one place.'),
            ],
          );
        }
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 16, 16),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE2F1EC),
                foregroundColor: Color(0xFF176B5B),
                child: Icon(Icons.account_balance_wallet_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Tracker',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Personal finance',
                      style: TextStyle(color: Color(0xFF71807B), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(indent: 20, endIndent: 20),
        const NavigationDrawerDestination(
          icon: Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(Icons.space_dashboard_rounded),
          label: Text('Dashboard'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: Text('Transactions'),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 20, 16, 8),
          child: Text(
            'PREFERENCES',
            style: TextStyle(
              color: Color(0xFF71807B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: Text('Settings'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.info_outline_rounded),
          label: Text('About'),
        ),
      ],
    );
  }

  Widget _buildDashboard() {
    final transactions = _controller.transactions;
    final recentTransactions = transactions.take(5).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text(
          'Your finances, at a glance',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: const Color(0xFF687773)),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 380;
            return Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Income',
                    amount: _controller.totalIncome,
                    currencyUnit: _settingsController.currencyUnit,
                    icon: Icons.south_west_rounded,
                    color: const Color(0xFF167A5C),
                    compact: compact,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Expense',
                    amount: _controller.totalExpense,
                    currencyUnit: _settingsController.currencyUnit,
                    icon: Icons.north_east_rounded,
                    color: const Color(0xFFD05C4B),
                    compact: compact,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Balance',
                    amount: _controller.balance,
                    currencyUnit: _settingsController.currencyUnit,
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF395F91),
                    compact: compact,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 30),
        _SectionHeading(
          title: 'Recent transactions',
          actionLabel: 'See all',
          onAction: () => setState(() => _selectedTab = 1),
        ),
        const SizedBox(height: 10),
        if (recentTransactions.isEmpty)
          const _EmptyTransactions()
        else
          ...recentTransactions.map(
            (transaction) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TransactionTile(
                transaction: transaction,
                currencyUnit: _settingsController.currencyUnit,
                onTap: () => _openTransaction(transaction),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionList() {
    final allTransactions = _controller.transactions;
    final dateRangeTransactions = _dateRange == null
        ? const <TransactionRecord>[]
        : filterTransactions(
            transactions: allTransactions,
            startDate: _dateRange!.start,
            endDate: _dateRange!.end,
          );
    final dateRangeIncome = dateRangeTransactions
        .where((transaction) => transaction.kind == TransactionKind.income)
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    final dateRangeExpense = dateRangeTransactions
        .where((transaction) => transaction.kind == TransactionKind.expense)
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    final filteredTransactions = filterTransactions(
      transactions: allTransactions,
      kind: switch (_transactionFilter) {
        _TransactionFilter.all => null,
        _TransactionFilter.income => TransactionKind.income,
        _TransactionFilter.expense => TransactionKind.expense,
      },
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: SegmentedButton<_TransactionFilter>(
            segments: const [
              ButtonSegment(value: _TransactionFilter.all, label: Text('All')),
              ButtonSegment(
                value: _TransactionFilter.income,
                label: Text('Income'),
                icon: Icon(Icons.south_west_rounded),
              ),
              ButtonSegment(
                value: _TransactionFilter.expense,
                label: Text('Expense'),
                icon: Icon(Icons.north_east_rounded),
              ),
            ],
            selected: {_transactionFilter},
            onSelectionChanged: (selection) {
              setState(() => _transactionFilter = selection.first);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: _chooseDateRange,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  _dateRange == null
                      ? 'Filter by date'
                      : _formatDateRange(_dateRange!),
                ),
              ),
              if (_dateRange != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear date filter',
                  onPressed: () => setState(() => _dateRange = null),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ],
          ),
        ),
        if (_dateRange != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 380;
                return Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Income total',
                        amount: dateRangeIncome,
                        currencyUnit: _settingsController.currencyUnit,
                        icon: Icons.south_west_rounded,
                        color: const Color(0xFF167A5C),
                        compact: compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Expense total',
                        amount: dateRangeExpense,
                        currencyUnit: _settingsController.currencyUnit,
                        icon: Icons.north_east_rounded,
                        color: const Color(0xFFD05C4B),
                        compact: compact,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        Expanded(
          child: filteredTransactions.isEmpty
              ? _EmptyTransactions(message: _emptyFilterMessage)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = filteredTransactions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TransactionTile(
                        transaction: transaction,
                        currencyUnit: _settingsController.currencyUnit,
                        onTap: () => _openTransaction(transaction),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _chooseDateRange() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange ?? DateTimeRange(start: today, end: today),
      helpText: 'Filter transactions by date',
      saveText: 'Apply',
    );
    if (dateRange != null && mounted) {
      setState(() => _dateRange = dateRange);
    }
  }

  String get _emptyFilterMessage {
    final typeMessage = switch (_transactionFilter) {
      _TransactionFilter.all => 'No transactions',
      _TransactionFilter.income => 'No income transactions',
      _TransactionFilter.expense => 'No expense transactions',
    };
    if (_dateRange != null) return '$typeMessage for the selected date range.';
    return switch (_transactionFilter) {
      _TransactionFilter.all =>
        'Add your first income or expense to get started.',
      _TransactionFilter.income => 'No income transactions yet.',
      _TransactionFilter.expense => 'No expense transactions yet.',
    };
  }
}

enum _TransactionFilter { all, income, expense }

String _formatDateRange(DateTimeRange range) {
  final start = DateUtils.dateOnly(range.start);
  final end = DateUtils.dateOnly(range.end);
  if (start == end) return _shortDate(start);
  return '${_shortDate(start)} – ${_shortDate(end)}';
}

String _shortDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.currencyUnit,
    required this.icon,
    required this.color,
    required this.compact,
  });

  final String label;
  final double amount;
  final String currencyUnit;
  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 11 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(height: 13),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF71807B), fontSize: 12),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatCurrency(amount, currencyUnit: currencyUnit),
                style: TextStyle(
                  color: color,
                  fontSize: compact ? 15 : 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.currencyUnit,
    required this.onTap,
  });

  final TransactionRecord transaction;
  final String currencyUnit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.kind == TransactionKind.income;
    final color = isIncome ? const Color(0xFF167A5C) : const Color(0xFFD05C4B);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          child: Icon(_categoryIcon(transaction.category), size: 20),
        ),
        title: Text(
          transaction.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${transaction.category} · ${_formatDate(transaction.date)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          formatTransactionAmount(
            transaction.amount,
            isIncome: isIncome,
            currencyUnit: currencyUnit,
          ),
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({
    this.message = 'Add your first income or expense to get started.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 38,
              color: Color(0xFF91A19B),
            ),
            const SizedBox(height: 10),
            Text(
              'No transactions yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF71807B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadErrorView extends StatelessWidget {
  const _LoadErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text('Could not load your transactions.'),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final localDate = date.toLocal();
  return '${_monthName(localDate.month)} ${localDate.day}, ${localDate.year}';
}

String _monthName(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];

IconData _categoryIcon(String category) => switch (category) {
  'Food' => Icons.restaurant_outlined,
  'Transport' => Icons.directions_car_outlined,
  'Shopping' => Icons.shopping_bag_outlined,
  'Bills' => Icons.receipt_outlined,
  'Health' => Icons.favorite_border,
  'Salary' || 'Freelance' => Icons.payments_outlined,
  'Entertainment' => Icons.movie_outlined,
  _ => Icons.category_outlined,
};
