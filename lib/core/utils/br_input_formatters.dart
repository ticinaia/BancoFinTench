import 'package:flutter/services.dart';

class BrInputFormatters {
  BrInputFormatters._();

  static final cpf = _PatternInputFormatter(
    pattern: '###.###.###-##',
    maxDigits: 11,
  );

  static final brMobilePhone = _PatternInputFormatter(
    pattern: '#####-####',
    maxDigits: 9,
  );
}

class _PatternInputFormatter extends TextInputFormatter {
  _PatternInputFormatter({
    required this.pattern,
    required this.maxDigits,
  });

  final String pattern;
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitedDigits =
        digits.length > maxDigits ? digits.substring(0, maxDigits) : digits;

    final buffer = StringBuffer();
    var digitIndex = 0;

    for (final char in pattern.split('')) {
      if (digitIndex >= limitedDigits.length) break;
      if (char == '#') {
        buffer.write(limitedDigits[digitIndex]);
        digitIndex++;
      } else {
        buffer.write(char);
      }
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
