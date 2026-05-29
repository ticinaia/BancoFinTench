import '../../../auth/domain/validators/br_auth_validators.dart';

class PixKeyValidator {
  PixKeyValidator._();

  static bool isValid({
    required String type,
    required String value,
  }) {
    final text = value.trim();
    switch (type) {
      case 'E-mail':
        return BrAuthValidators.isValidEmail(text);
      case 'CPF':
        return BrAuthValidators.isValidCpf(text);
      case 'Telefone':
        return BrAuthValidators.isValidBrPhone(text);
      case 'Aleatória':
        return RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
        ).hasMatch(text);
      default:
        return false;
    }
  }

  static String messageFor(String type) {
    switch (type) {
      case 'E-mail':
        return 'Informe um e-mail válido com @ e .com';
      case 'CPF':
        return 'Informe um CPF válido';
      case 'Telefone':
        return 'Informe um celular com 9 dígitos';
      case 'Aleatória':
        return 'Informe uma chave aleatória UUID válida';
      default:
        return 'Informe uma chave válida';
    }
  }
}
