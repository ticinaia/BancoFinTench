import 'package:banco_fin_tech/features/pix/presentation/utils/pix_payload_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses EMV QR Code amount with decimal dot', () {
    const payload =
        '00020126380014br.gov.bcb.pix0116teste@pix.com.br520400005303986540512.505802BR5913CLIENTE TESTE6009SAO PAULO62070503***6304ABCD';

    final parsed = PixPayloadParser.parse(payload);

    expect(parsed.key, 'teste@pix.com.br');
    expect(parsed.keyType, 'E-mail');
    expect(parsed.valorCentavos, 1250);
  });

  test('parses URI amount with decimal dot', () {
    final parsed = PixPayloadParser.parse(
      'pix://pay?pixKey=teste@pix.com.br&amount=87.50',
    );

    expect(parsed.key, 'teste@pix.com.br');
    expect(parsed.valorCentavos, 8750);
  });
}
