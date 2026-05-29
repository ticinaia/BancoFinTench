import 'package:intl/intl.dart';

class BrFormatters {
  BrFormatters._();

  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  static final DateFormat _dateTimeFormatter = DateFormat(
    'dd/MM/yyyy HH:mm',
    'pt_BR',
  );

  static final DateFormat _dateFormatter = DateFormat(
    'dd/MM/yyyy',
    'pt_BR',
  );

  static int parseCurrencyToCentavos(String input) {
    final normalized = input
        .trim()
        .replaceAll(RegExp(r'[^\d,.-]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final value = double.tryParse(normalized) ?? 0;
    return (value * 100).round();
  }

  static String currencyFromCentavos(int centavos) {
    return _currencyFormatter.format(centavos / 100);
  }

  static String dateTime(DateTime date) {
    return _dateTimeFormatter.format(date);
  }

  static String date(DateTime date) {
    return _dateFormatter.format(date);
  }
}
