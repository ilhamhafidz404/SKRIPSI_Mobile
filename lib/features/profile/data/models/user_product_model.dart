class UserProductResponse {
  final List<ProductItem> productItems;
  final dynamic user;

  UserProductResponse({required this.productItems, required this.user});

  factory UserProductResponse.fromJson(Map<String, dynamic> json) {
    return UserProductResponse(
      productItems: (json['data']['product_items'] as List)
          .map((i) => ProductItem.fromJson(i))
          .toList(),
      user: json['data']['user'],
    );
  }
}

class ProductItem {
  final String id;
  final String productId;
  final String serialNumber;
  final String claimedAt;

  ProductItem({
    required this.id,
    required this.productId,
    required this.serialNumber,
    required this.claimedAt,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'],
      productId: json['product_id'],
      serialNumber: json['serial_number'],
      claimedAt: json['claimed_at'],
    );
  }
}
