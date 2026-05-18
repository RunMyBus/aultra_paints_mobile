class Deal {
  final String id;
  final String title;
  final String dealImageUrl;
  final DateTime? expirationDate;
  final DateTime? updatedAt;

  const Deal({
    required this.id,
    required this.title,
    required this.dealImageUrl,
    this.expirationDate,
    this.updatedAt,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      dealImageUrl: json['dealImageUrl']?.toString() ?? '',
      expirationDate: json['expirationDate'] != null
          ? DateTime.tryParse(json['expirationDate'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  // Append `?v=<updatedAt-ms>` to bust the S3 cache when the admin updates
  // a deal's image (the URL itself doesn't change because the S3 key is fixed
  // to `${id}.png`).
  String get cacheBustedImageUrl {
    if (dealImageUrl.isEmpty) return '';
    if (updatedAt == null) return dealImageUrl;
    final separator = dealImageUrl.contains('?') ? '&' : '?';
    return '$dealImageUrl${separator}v=${updatedAt!.millisecondsSinceEpoch}';
  }
}
