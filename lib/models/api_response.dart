import 'package:certipath_app/features/home/data/models/product_model.dart';

class ApiResponse {
  final String code;
  final List<Product> data;
  final String message;
  final Meta meta;

  ApiResponse({
    required this.code,
    required this.data,
    required this.message,
    required this.meta,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List;
    List<Product> products = dataList
        .map((item) => Product.fromJson(item))
        .toList();
    return ApiResponse(
      code: json['code'],
      data: products,
      message: json['message'],
      meta: Meta.fromJson(json['meta']),
    );
  }
}

class Meta {
  final int limit;
  final int page;
  final int totalData;
  final int totalPage;

  Meta({
    required this.limit,
    required this.page,
    required this.totalData,
    required this.totalPage,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      limit: json['limit'],
      page: json['page'],
      totalData: json['total_data'],
      totalPage: json['total_page'],
    );
  }
}
