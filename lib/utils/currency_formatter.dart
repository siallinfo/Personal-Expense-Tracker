String formatBdtAmount(double amount) {
  final fixedAmount = amount.abs().toStringAsFixed(2);
  final decimalIndex = fixedAmount.indexOf('.');
  final integerPart = fixedAmount.substring(0, decimalIndex);
  final decimalPart = fixedAmount.substring(decimalIndex);

  final groups = <String>[];
  var end = integerPart.length;
  var groupSize = 3;
  while (end > 0) {
    final start = end > groupSize ? end - groupSize : 0;
    groups.insert(0, integerPart.substring(start, end));
    end = start;
    groupSize = 2;
  }

  final sign = amount < 0 ? '-' : '';
  return '$sign${groups.join(',')}$decimalPart';
}

String formatBdtTransactionAmount(double amount, {required bool isIncome}) {
  return formatTransactionAmount(amount, isIncome: isIncome);
}

String formatCurrency(double amount, {String currencyUnit = 'BDT'}) =>
    '$currencyUnit ${formatBdtAmount(amount)}';

String formatTransactionAmount(
  double amount, {
  required bool isIncome,
  String currencyUnit = 'BDT',
}) {
  final sign = isIncome ? '+' : '-';
  return '($sign) ${formatCurrency(amount.abs(), currencyUnit: currencyUnit)}';
}

String formatBdtCurrency(double amount) => formatCurrency(amount);
