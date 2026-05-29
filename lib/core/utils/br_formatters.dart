class BrFormatters {
  BrFormatters._();

  static int parseCurrencyToCentavos(String input) {
    final normalized = input.trim().replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized) ?? 0;
    return (value * 100).round();
  }

  static String currencyFromCentavos(int centavos) {
    final reais = centavos ~/ 100;
    final cents = (centavos % 100).toString().padLeft(2, '0');
    return 'R\$ ${_formatThousands(reais)},$cents';
  }

  static String dateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  static String date(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  static String _formatThousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buffer.write(digits[i]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }
}
