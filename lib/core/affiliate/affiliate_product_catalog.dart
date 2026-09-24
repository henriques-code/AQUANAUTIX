/// Catálogo demo — loja afiliada AQUANAUTIX (mockup Jul 2026).
class AffiliateProduct {
  const AffiliateProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.priceLabel,
    required this.imageSource,
    required this.category,
    required this.partner,
    required this.tag,
  });

  final String id;
  final String name;
  final String brand;
  final String priceLabel;
  final String imageSource;
  final String category;
  final String partner;
  final String tag;
}

abstract final class AffiliateProductCatalog {
  static const categories = <String>[
    'TODOS',
    'CANAS',
    'MOLINETES',
    'ISCOS',
    'VESTUÁRIO',
  ];

  static const products = <AffiliateProduct>[
    AffiliateProduct(
      id: 'cana-spin-240',
      name: 'Cana Spinning 2.40m',
      brand: 'CAPERLAN',
      priceLabel: '€49,99',
      imageSource:
          'https://images.unsplash.com/photo-1544552866-d3ed42536cfd?auto=format&fit=crop&w=600&q=80',
      category: 'CANAS',
      partner: 'Decathlon',
      tag: 'COSTA',
    ),
    AffiliateProduct(
      id: 'molinete-3000',
      name: 'Molinete 3000 FD',
      brand: 'MITCHELL',
      priceLabel: '€34,99',
      imageSource:
          'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=600&q=80',
      category: 'MOLINETES',
      partner: 'Decathlon',
      tag: 'VERSÁTIL',
    ),
    AffiliateProduct(
      id: 'soft-lures',
      name: 'Pack Soft Lures 12un',
      brand: 'SAVAGE GEAR',
      priceLabel: '€12,90',
      imageSource: 'assets/marketing/catches/robalo.jpg',
      category: 'ISCOS',
      partner: 'Amazon',
      tag: 'ROBALO',
    ),
    AffiliateProduct(
      id: 'tackle-box',
      name: 'Caixa Tackle Pro M',
      brand: 'FLAMBEAU',
      priceLabel: '€29,99',
      imageSource:
          'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=600&q=80',
      category: 'ISCOS',
      partner: 'Decathlon',
      tag: 'ORGANIZAÇÃO',
    ),
    AffiliateProduct(
      id: 'jacket-rain',
      name: 'Casaco Impermeável',
      brand: 'SIMOND',
      priceLabel: '€59,99',
      imageSource:
          'https://images.unsplash.com/photo-1559827260-dc66d52bef19?auto=format&fit=crop&w=600&q=80',
      category: 'VESTUÁRIO',
      partner: 'Decathlon',
      tag: 'INVERNO',
    ),
    AffiliateProduct(
      id: 'polarized-glasses',
      name: 'Óculos Polarizados',
      brand: 'WATERTIGHT',
      priceLabel: '€24,50',
      imageSource: 'assets/marketing/catches/dourada.jpg',
      category: 'VESTUÁRIO',
      partner: 'Amazon',
      tag: 'SOL',
    ),
    AffiliateProduct(
      id: 'jig-pack',
      name: 'Jigs Costeiros 5un',
      brand: 'HART',
      priceLabel: '€18,50',
      imageSource: 'assets/marketing/catches/sargo.jpg',
      category: 'ISCOS',
      partner: 'Decathlon',
      tag: 'JIGGING',
    ),
    AffiliateProduct(
      id: 'feeder-rod',
      name: 'Cana Feeder 3.60m',
      brand: 'CAPERLAN',
      priceLabel: '€44,99',
      imageSource: 'assets/marketing/spots/peniche.jpg',
      category: 'CANAS',
      partner: 'Decathlon',
      tag: 'RIO',
    ),
  ];

  static List<AffiliateProduct> forCategory(String category) {
    if (category == 'TODOS') return products;
    return products.where((p) => p.category == category).toList();
  }
}
