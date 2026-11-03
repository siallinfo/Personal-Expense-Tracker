import 'package:flutter/material.dart';

import '../controllers/app_settings_controller.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction_record.dart';
import '../utils/currency_formatter.dart';
import 'transaction_form_screen.dart';

class TransactionDetailsScreen extends StatefulWidget {
  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
    required this.controller,
    required this.settingsController,
  });

  final TransactionRecord transaction;
  final TransactionController controller;
  final AppSettingsController settingsController;

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  bool _isDeleting = false;

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(
          controller: widget.controller,
          settingsController: widget.settingsController,
          transaction: widget.transaction,
        ),
      ),
    );
    if (saved == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text(
          'This transaction will be permanently removed from your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD05C4B),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final id = widget.transaction.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This transaction cannot be deleted.')),
      );
      return;
    }
    setState(() => _isDeleting = true);
    try {
      await widget.controller.deleteTransaction(id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete transaction: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final isIncome = transaction.kind == TransactionKind.income;
    final color = isIncome ? const Color(0xFF167A5C) : const Color(0xFFD05C4B);
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: color.withValues(alpha: 0.1),
                    foregroundColor: color,
                    child: Icon(
                      isIncome
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    transaction.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatTransactionAmount(
                      transaction.amount,
                      isIncome: isIncome,
                      currencyUnit: widget.settingsController.currencyUnit,
                    ),
                    style: TextStyle(
                      color: color,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _DetailRow(label: 'Category', value: transaction.category),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _DetailRow(label: 'Type', value: transaction.kind.label),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _DetailRow(
                  label: 'Date',
                  value: MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(transaction.date),
                ),
                if (transaction.id != null) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _DetailRow(
                    label: 'Transaction ID',
                    value: '${transaction.id}',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isDeleting ? null : _edit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEF8A24),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isDeleting ? null : _confirmDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD05C4B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF71807B))),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
