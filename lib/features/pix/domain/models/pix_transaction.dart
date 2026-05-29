class PixTransaction {
  final String recipientName;
  final String pixKey;
  final double amount;
  final DateTime createdAt;

  PixTransaction({
    required this.recipientName,
    required this.pixKey,
    required this.amount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'recipientName': recipientName,
      'pixKey': pixKey,
      'amount': amount,
      'createdAt': createdAt,
    };
  }

  factory PixTransaction.fromMap(Map<String, dynamic> map) {
    return PixTransaction(
      recipientName: map['recipientName'],
      pixKey: map['pixKey'],
      amount: (map['amount'] as num).toDouble(),
      createdAt: map['createdAt'].toDate(),
    );
  }
}
