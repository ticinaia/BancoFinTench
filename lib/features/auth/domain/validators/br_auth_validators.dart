class BrAuthValidators {
  BrAuthValidators._();

  static String onlyDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static bool isValidEmail(String value) {
    final email = value.trim().toLowerCase();
    final pattern = RegExp(
      r'^[a-z0-9.!#$%&*+/=?^_`{|}~-]+@[a-z0-9-]+(\.[a-z0-9-]+)*\.(com|com\.br)$',
    );
    return pattern.hasMatch(email);
  }

  static bool isValidCpf(String value) {
    final cpf = onlyDigits(value);
    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

    final numbers = cpf.split('').map(int.parse).toList();

    var sum = 0;
    for (var i = 0; i < 9; i++) {
      sum += numbers[i] * (10 - i);
    }
    var firstDigit = 11 - (sum % 11);
    if (firstDigit >= 10) firstDigit = 0;
    if (numbers[9] != firstDigit) return false;

    sum = 0;
    for (var i = 0; i < 10; i++) {
      sum += numbers[i] * (11 - i);
    }
    var secondDigit = 11 - (sum % 11);
    if (secondDigit >= 10) secondDigit = 0;

    return numbers[10] == secondDigit;
  }

  static bool isValidBrPhone(String value) {
    final phone = onlyDigits(value);
    if (phone.length != 9) return false;
    if (!phone.startsWith('9')) return false;

    return !RegExp(r'^(\d)\1*$').hasMatch(phone);
  }
}
