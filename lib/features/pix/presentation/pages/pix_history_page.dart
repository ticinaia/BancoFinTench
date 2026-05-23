import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class PixHistoryPage extends StatelessWidget {
  const PixHistoryPage({super.key});

  void compartilharComprovante({
    required String chave,
    required String valor,
  }) {
    Share.share(
      'Comprovante PIX\n\nChave: $chave\nValor: R\$ $valor',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico PIX'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pix')
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar histórico'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('Nenhuma transferência encontrada'),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data =
                  docs[index].data() as Map<String, dynamic>;

              final chave = data['chave'];
              final valor = data['valor'];

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  leading: const Icon(Icons.pix),
                  title: Text('R\$ $valor'),
                  subtitle: Text(chave),
                  trailing: IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      compartilharComprovante(
                        chave: chave,
                        valor: valor,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}