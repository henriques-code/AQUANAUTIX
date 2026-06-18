// lib/core/spots/bait_shop.dart

class BaitShop {
  static const defaultPhotoUrl =
      'https://images.unsplash.com/photo-1516939884455-1445c8652f83?w=160&q=70&auto=format';

  final String id;
  final String name;
  final double lat;
  final double lon;
  final String country;
  final String? region;
  final String? address;
  final String? phone;
  final String? hours;
  final List<String> speciality;
  final String? googleMapsUrl;

  const BaitShop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.country,
    this.region,
    this.address,
    this.phone,
    this.hours,
    this.speciality = const [],
    this.googleMapsUrl,
  });

  String get localLabel => region?.trim().isNotEmpty == true ? region! : country;

  String get mapsQuery {
    final url = googleMapsUrl?.trim();
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      final q = uri?.queryParameters['query'];
      if (q != null && q.isNotEmpty) return q;
    }
    return '$lat,$lon';
  }

  String get photoUrl => defaultPhotoUrl;

  bool get isOpen {
    final h = (hours ?? '').toLowerCase();
    if (h.contains('fechado') || h.contains('cerrado')) return false;
    return true;
  }

  factory BaitShop.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    return BaitShop(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0,
      country: (json['country'] as String? ?? 'PT').toUpperCase(),
      region: json['region'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      hours: json['hours'] as String?,
      speciality: strList(json['speciality']),
      googleMapsUrl: json['google_maps_url'] as String?,
    );
  }
}
