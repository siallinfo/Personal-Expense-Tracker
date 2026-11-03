import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/app_settings_controller.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction_record.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({
    super.key,
    required this.controller,
    required this.settingsController,
    this.transaction,
  });

  final TransactionController controller;
  final AppSettingsController settingsController;
  final TransactionRecord? transaction;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late DateTime _date;
  String? _category;
  TransactionKind? _kind;
  bool _isSaving = false;

  bool get _isEditing => widget.transaction != null;

  List<String> get _availableCategories {
    final kind = _kind;
    if (kind == null) return const [];
    final categories = widget.settingsController.categoriesFor(kind);
    final currentCategory = widget.transaction?.category;
    if (currentCategory != null && !categories.contains(currentCategory)) {
      return [...categories, currentCategory];
    }
    return categories;
  }

  @override
  void initState() {
    super.initState();
    widget.settingsController.addListener(_onSettingsChanged);
    final transaction = widget.transaction;
    _titleController = TextEditingController(text: transaction?.title ?? '');
    _amountController = TextEditingController(
      text: transaction?.amount.toString() ?? '',
    );
    _date = transaction?.date ?? DateTime.now();
    _category = transaction?.category;
    _kind = transaction?.kind;
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.settingsController.removeListener(_onSettingsChanged);
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final transaction = TransactionRecord(
      id: widget.transaction?.id,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      category: _category!,
      kind: _kind!,
      date: DateTime(_date.year, _date.month, _date.day),
    );
    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await widget.controller.saveTransaction(transaction);
      } else {
        await widget.controller.saveTransaction(transaction);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save transaction: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit transaction' : 'Add transaction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const Text(
              'Transaction details',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172B27),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Keep track of where your money comes from and goes.',
              style: TextStyle(color: Color(0xFF71807B)),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Weekly groceries',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter a title'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                prefixText: '${widget.settingsController.currencyUnit} ',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                if (amount == null || !amount.isFinite || amount <= 0) {
                  return 'Enter a valid positive amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TransactionKind>(
              initialValue: _kind,
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
              onChanged: (value) {
                setState(() {
                  if (_kind != value) _category = null;
                  _kind = value;
                });
              },
              validator: (value) =>
                  value == null ? 'Select transaction type' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey('category-${_kind?.name}-${_category ?? ''}'),
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              hint: Text(
                _kind == null ? 'Select a type first' : 'Select a category',
              ),
              items: _availableCategories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: _kind == null
                  ? null
                  : (value) => setState(() => _category = value),
              validator: (value) => value == null ? 'Select a category' : null,
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: InkWell(
                onTap: _chooseDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(_date),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_isSaving ? 'Saving...' : 'Save transaction'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
