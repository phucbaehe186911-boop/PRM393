import 'dart:convert';

/// Model đại diện cho sân thể thao
class Court {
  final int id;
  final String name;
  final String type; // 'badminton' | 'pickleball' | 'football' | 'tennis'
  final String address;
  final double lat;
  final double lng;
  final double pricePerHour; // giá off-peak (VNĐ)
  final double peakPricePerHour; // giá peak 17:00-21:00
  final String? description;
  final List<String> images; // danh sách URL ảnh
  final double rating;
  final int reviewCount;
  final int? ownerId;

  const Court({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.lat,
    required this.lng,
    required this.pricePerHour,
    required this.peakPricePerHour,
    this.description,
    required this.images,
    required this.rating,
    required this.reviewCount,
    this.ownerId,
  });

  factory Court.fromMap(Map<String, dynamic> map) => Court(
        id: map['id'] as int,
        name: map['name'] as String,
        type: map['type'] as String,
        address: map['address'] as String,
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
        pricePerHour: (map['price_per_hour'] as num).toDouble(),
        peakPricePerHour: (map['peak_price_per_hour'] as num).toDouble(),
        description: map['description'] as String?,
        images: List<String>.from(jsonDecode(map['images'] ?? '[]')),
        rating: (map['rating'] as num).toDouble(),
        reviewCount: map['review_count'] as int,
        ownerId: map['owner_id'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type,
        'address': address,
        'lat': lat,
        'lng': lng,
        'price_per_hour': pricePerHour,
        'peak_price_per_hour': peakPricePerHour,
        'description': description,
        'images': jsonEncode(images),
        'rating': rating,
        'review_count': reviewCount,
        if (ownerId != null) 'owner_id': ownerId,
      };

  factory Court.fromFirestore(Map<String, dynamic> data) => Court(
        id: data['id'] as int,
        name: data['name'] as String,
        type: data['type'] as String,
        address: data['address'] as String,
        lat: (data['lat'] as num).toDouble(),
        lng: (data['lng'] as num).toDouble(),
        pricePerHour: (data['pricePerHour'] as num).toDouble(),
        peakPricePerHour: (data['peakPricePerHour'] as num).toDouble(),
        description: data['description'] as String?,
        images: List<String>.from(data['images'] ?? []),
        rating: (data['rating'] as num).toDouble(),
        reviewCount: data['reviewCount'] as int,
        ownerId: data['ownerId'] as int?,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'type': type,
        'address': address,
        'lat': lat,
        'lng': lng,
        'pricePerHour': pricePerHour,
        'peakPricePerHour': peakPricePerHour,
        'description': description,
        'images': images,
        'rating': rating,
        'reviewCount': reviewCount,
        if (ownerId != null) 'ownerId': ownerId,
      };

  Court copyWith({
    int? id,
    String? name,
    String? type,
    String? address,
    double? lat,
    double? lng,
    double? pricePerHour,
    double? peakPricePerHour,
    String? description,
    List<String>? images,
    double? rating,
    int? reviewCount,
    int? ownerId,
  }) =>
      Court(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        address: address ?? this.address,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        pricePerHour: pricePerHour ?? this.pricePerHour,
        peakPricePerHour: peakPricePerHour ?? this.peakPricePerHour,
        description: description ?? this.description,
        images: images ?? this.images,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        ownerId: ownerId ?? this.ownerId,
      );

  /// Lấy tên loại sân dạng hiển thị tiếng Việt
  String get typeLabel {
    switch (type) {
      case 'pickleball':
        return 'Pickleball';
      case 'badminton':
        return 'Cầu lông';
      case 'football':
        return 'Bóng đá';
      case 'tennis':
        return 'Tennis';
      default:
        return type;
    }
  }
}
