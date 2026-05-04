class Product {
  final int id;
  final String name;
  final String code;
  final int price;
  final int stock;
  final String image;
  final String merkleRoot;
  final String blockchainTx;

  Product({
    required this.id,
    required this.name,
    required this.code,
    required this.price,
    required this.stock,
    required this.image,
    required this.merkleRoot,
    required this.blockchainTx,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      price: json['price'],
      stock: json['stock'],
      image: json['image'] ?? '',
      merkleRoot: json['merkle_root'] ?? '',
      blockchainTx: json['blockchain_tx'] ?? '',
    );
  }
}
