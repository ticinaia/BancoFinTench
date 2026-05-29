import '../../../../core/utils/br_formatters.dart';
import '../../domain/validators/pix_key_validator.dart';

class ParsedPixPayload {
  const ParsedPixPayload({
    required this.key,
    required this.keyType,
    this.valorCentavos,
  });

  final String key;
  final String keyType;
  final int? valorCentavos;
}

class PixPayloadParser {
  const PixPayloadParser._();

  static ParsedPixPayload parse(String payload) {
    final text = payload.trim();
    final emvPayload = _parseEmvPixPayload(text);
    if (emvPayload != null) return emvPayload;

    final uri = Uri.tryParse(text);
    final key = uri?.queryParameters['pixKey'] ??
        uri?.queryParameters['chave'] ??
        uri?.queryParameters['key'];
    final amount = uri?.queryParameters['amount'] ??
        uri?.queryParameters['valor'] ??
        uri?.queryParameters['value'];

    if (key != null && key.isNotEmpty) {
      return ParsedPixPayload(
        key: key,
        keyType: detectKeyType(key),
        valorCentavos: amount == null ? null : _parsePixAmount(amount),
      );
    }

    return ParsedPixPayload(
      key: text,
      keyType: detectKeyType(text),
    );
  }

  static String detectKeyType(String key) {
    if (PixKeyValidator.isValid(type: 'E-mail', value: key)) return 'E-mail';
    if (PixKeyValidator.isValid(type: 'CPF', value: key)) return 'CPF';
    if (PixKeyValidator.isValid(type: 'Telefone', value: key)) {
      return 'Telefone';
    }
    return 'Aleatória';
  }

  static ParsedPixPayload? _parseEmvPixPayload(String payload) {
    if (!payload.startsWith('000201')) return null;

    final root = _parseTlv(payload);
    final merchantAccount = root['26'];
    final key =
        merchantAccount == null ? null : _parseTlv(merchantAccount)['01'];
    final amount = root['54'];

    if (key == null || key.isEmpty) return null;

    return ParsedPixPayload(
      key: key,
      keyType: detectKeyType(key),
      valorCentavos: amount == null ? null : _parsePixAmount(amount),
    );
  }

  static int _parsePixAmount(String amount) {
    final text = amount.trim();
    final normalized = text.replaceAll(RegExp(r'[^\d,.-]'), '');
    final usesDecimalDot = RegExp(r'^\d+\.\d{1,2}$').hasMatch(normalized);

    if (usesDecimalDot) {
      final value = double.tryParse(normalized) ?? 0;
      return (value * 100).round();
    }

    return BrFormatters.parseCurrencyToCentavos(text);
  }

  static Map<String, String> _parseTlv(String payload) {
    final result = <String, String>{};
    var index = 0;

    while (index + 4 <= payload.length) {
      final id = payload.substring(index, index + 2);
      final length = int.tryParse(payload.substring(index + 2, index + 4));
      if (length == null) break;

      final valueStart = index + 4;
      final valueEnd = valueStart + length;
      if (valueEnd > payload.length) break;

      result[id] = payload.substring(valueStart, valueEnd);
      index = valueEnd;
    }

    return result;
  }
}
