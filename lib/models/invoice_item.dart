class InvoiceItem {
  const InvoiceItem({
    required this.itemId,
    required this.description,
    required this.quantity,
    required this.unitPriceCents,
    required this.lineTotalCents,
    required this.displayOrder,
  });

  final String itemId;
  final String description;
  final int quantity;
  final int unitPriceCents;
  final int lineTotalCents;
  final int displayOrder;

  factory InvoiceItem.fromMap(Map<String, dynamic> map, {String? itemId}) {
    return InvoiceItem(
      itemId: itemId ?? map['itemId'] as String? ?? '',
      description: map['description'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 0,
      unitPriceCents: map['unitPrice'] as int? ?? 0,
      lineTotalCents: map['lineTotal'] as int? ?? 0,
      displayOrder: map['displayOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPriceCents,
      'lineTotal': lineTotalCents,
      'displayOrder': displayOrder,
    };
  }

  InvoiceItem copyWith({
    String? description,
    int? quantity,
    int? unitPriceCents,
    int? lineTotalCents,
    int? displayOrder,
  }) {
    return InvoiceItem(
      itemId: itemId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      lineTotalCents: lineTotalCents ?? this.lineTotalCents,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}

/// Draft line used in forms before persistence.
class InvoiceLineInput {
  const InvoiceLineInput({
    required this.description,
    required this.quantity,
    required this.unitPriceCents,
  });

  final String description;
  final int quantity;
  final int unitPriceCents;
}
