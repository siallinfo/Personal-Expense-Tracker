import 'package:flutter/material.dart';

import '../controllers/app_settings_controller.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction_record.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    required this.transactionController,
  });

  final AppSettingsController controller;
  final TransactionController transactionController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TransactionKind? _categoryKind;
  bool _isSaving = false;

  Future<void> _showAddCategoryDialog() async {
    final kind = _categoryKind;
    if (kind == null) return;

    final category = await showDialog<String>(
      context: context,
      builder: (_) => _AddCategoryDialog(kind: kind),
    );
    if (category == null || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await widget.controller.addCategory(kind, category);
    } catch (error) {
      if (mounted) _showError('Could not add category: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeCategory(TransactionKind kind, String category) async {
    final inUse = widget.transactionController.transactions.any(
      (transaction) =>
          transaction.kind == kind && transaction.category == category,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove category?'),
        content: Text(
          inUse
              ? 'Existing transactions will keep this category, but it will no longer be available for new transactions.'
              : 'This category will no longer be available for new transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await widget.controller.removeCategory(kind, category);
    } catch (error) {
      if (mounted) _showError('Could not remove category: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changeCurrency(String? code) async {
    if (code == null) return;
    setState(() => _isSaving = true);
    try {
      await widget.controller.setCurrency(code);
    } catch (error) {
      if (mounted) _showError('Could not save currency: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              'Preferences',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Currency',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: widget.controller.currencyCode,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.currency_exchange_rounded),
                      ),
                      items: currencyOptions
                          .map(
                            (option) => DropdownMenuItem(
                              value: option.code,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                      onChanged: _isSaving ? null : _changeCurrency,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Changing currency only changes how amounts are displayed.',
                      style: TextStyle(color: Color(0xFF71807B), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.controller.loadError != null) ...[
              const SizedBox(height: 8),
              Card(
                color: const Color(0xFFFFF1E8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Could not load saved preferences: '
                    '${widget.controller.loadError}',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Categories',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose a transaction type before adding a category.',
              style: TextStyle(color: Color(0xFF71807B)),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<TransactionKind>(
              initialValue: _categoryKind,
              decoration: const InputDecoration(
                labelText: 'Transaction type',
                prefixIcon: Icon(Icons.swap_vert_rounded),
              ),
              items: TransactionKind.values
                  .map(
                    (kind) =>
                        DropdownMenuItem(value: kind, child: Text(kind.label)),
                  )
                  .toList(),
              onChanged: (kind) {
                setState(() => _categoryKind = kind);
              },
            ),
            const SizedBox(height: 12),
            if (_categoryKind == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Select Expense or Income to manage categories.'),
                ),
              )
            else ...[
              FilledButton.tonalIcon(
                onPressed: _isSaving ? null : _showAddCategoryDialog,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'Add ${_categoryKind!.label.toLowerCase()} category',
                ),
              ),
              const SizedBox(height: 8),
              ...widget.controller
                  .categoriesFor(_categoryKind!)
                  .map(
                    (category) => Card(
                      child: ListTile(
                        leading: Icon(
                          _categoryKind == TransactionKind.income
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                        ),
                        title: Text(category),
                        trailing: IconButton(
                          tooltip: 'Remove $category',
                          onPressed: _isSaving
                              ? null
                              : () => _removeCategory(_categoryKind!, category),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFD05C4B),
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog({required this.kind});

  final TransactionKind kind;

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.kind.label} category'),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Category name',
          hintText: 'e.g. Rent or Bonus',
        ),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _nameController.text),
          child: const Text('Add category'),
        ),
      ],
    );
  }
}
