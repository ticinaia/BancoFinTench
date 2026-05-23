import 'package:flutter/material.dart';

import '../../data/repositories/pix_repository.dart';

class PixTransferPage extends StatefulWidget {
  const PixTransferPage({super.key});

  @override
  State<PixTransferPage> createState() => _PixTransferPageState();
}

class _PixTransferPageState extends State<PixTransferPage> {
  final TextEditingController chaveController = TextEditingController();
  final TextEditingController valorController = TextEditingController();

  void enviarPix() {
    final chave = chaveController.text;
    final valor = valorController.text;

    PixRepository().enviarPix(chave: chave, valor: valor);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('PIX enviado'),
        content: Text(
          'PIX de R\$ $valor enviado para:\n$chave',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferência PIX'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: chaveController,
              decoration: const InputDecoration(
                labelText: 'Chave PIX',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: valorController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: enviarPix,
                child: const Text('Enviar PIX'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}