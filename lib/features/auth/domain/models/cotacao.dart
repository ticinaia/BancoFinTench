class Cotacao {
  final String name;
  final String code;
  final double buyPrice;
  final double sellPrice;
  final double variation;
  final DateTime updatedAt;

  Cotacao({
    required this.name,
    required this.code,
    required this.buyPrice,
    required this.sellPrice,
    required this.variation,
    required this.updatedAt,
  });

  factory Cotacao.fromJson(Map<String, dynamic> json) {
    final timestamp = int.tryParse(json['timestamp']?.toString() ?? '');

    return Cotacao(
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      buyPrice: double.tryParse(json['bid']?.toString() ?? '0') ?? 0.0,
      sellPrice: double.tryParse(json['ask']?.toString() ?? '0') ?? 0.0,
      variation: double.tryParse(json['pctChange']?.toString() ?? '0') ?? 0.0,
      updatedAt: timestamp == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
    );
  }
}
