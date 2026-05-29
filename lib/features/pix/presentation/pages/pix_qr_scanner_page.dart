import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PixQrScannerPage extends StatefulWidget {
  const PixQrScannerPage({super.key});

  @override
  State<PixQrScannerPage> createState() => _PixQrScannerPageState();
}

class _PixQrScannerPageState extends State<PixQrScannerPage> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    if (capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    _handled = true;
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ler QR Code PIX'),
      ),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}
