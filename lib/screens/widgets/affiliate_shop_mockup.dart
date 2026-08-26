import 'package:flutter/material.dart';

import '../../core/affiliate/affiliate_product_catalog.dart';
import '../_shared.dart';

const kAffiliateHeroAsset = 'assets/marketing/catches/oracle_hero_pescador.jpg';

/// Mockup da loja afiliada — design Midnight Deep Sea + aviso «em desenvolvimento».
class AffiliateShopMockup extends StatefulWidget {
  const AffiliateShopMockup({super.key});

  @override
  State<AffiliateShopMockup> createState() => _AffiliateShopMockupState();
}

class _AffiliateShopMockupState extends State<AffiliateShopMockup> {
  String _category = 'TODOS';

  @override
  Widget build(BuildContext context) {
    final items = AffiliateProductCatalog.forCategory(_category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _DevelopmentBanner(),
        const SizedBox(height: 12),
        const _AffiliateHero(),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'MATERIAL SELECCIONADO PARA PESCADORES IBÉRICOS',
            style: mono(10, ls: 1.2),
          ),
        ),
        const SizedBox(height: 10),
        _CategoryPills(
          selected: _category,
          onSelected: (c) => setState(() => _category = c),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (_, i) => _ProductCard(product: items[i]),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kHint.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.link_rounded, size: 18, color: kHint.withValues(alpha: 0.8)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Links de afiliado Decathlon e Amazon. Comissões revertem para manter o Oráculo e o Vision gratuitos para todos.',
                    style: ibm(11, c: kHint),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _DevelopmentBanner extends StatelessWidget {
  const _DevelopmentBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kAmber.withValues(alpha: 0.18),
            kAmber.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kAmber.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: kAmber.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kAmber.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.construction_rounded, color: kAmber, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ESTÁ EM DESENVOLVIMENTO', style: orb(11, c: kAmber, ls: 0.8)),
                const SizedBox(height: 2),
                Text(
                  'Pré-visualização da loja afiliada — compras indisponíveis por agora.',
                  style: ibm(11, c: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AffiliateHero extends StatelessWidget {
  const _AffiliateHero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 168,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                kAffiliateHeroAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0A1F3A)),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LOJA AFILIADA', style: mono(9, c: kCyan, ls: 1.4)),
                    const SizedBox(height: 4),
                    Text(
                      'Equipa-te como os pros',
                      style: orb(18, fw: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recomendações alinhadas ao teu alvo e condições do Oráculo.',
                      style: ibm(11, c: kHint),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kCyan.withValues(alpha: 0.35)),
                  ),
                  child: Text('BETA', style: mono(8, c: kCyan, ls: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPills extends StatelessWidget {
  const _CategoryPills({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AffiliateProductCatalog.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = AffiliateProductCatalog.categories[i];
          final active = cat == selected;
          return GestureDetector(
            onTap: () => onSelected(cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: active ? kCyan.withValues(alpha: 0.15) : kCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? kCyan.withValues(alpha: 0.6) : kCyan.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                cat,
                style: mono(9, c: active ? kCyan : kHint, ls: 0.6),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final AffiliateProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardBox,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _productImage(product.imageSource),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: kAmber.withValues(alpha: 0.4)),
                      ),
                      child: Text(product.tag, style: mono(7, c: kAmber, ls: 0.4)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand,
                  style: mono(8, c: kHint, ls: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product.name,
                  style: ibm(12, fw: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(product.priceLabel, style: orb(13, c: kCyan, fw: FontWeight.w700)),
                    const Spacer(),
                    Text('→ ${product.partner}', style: ibm(9, c: kAmber, fw: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: kHint.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kHint.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    'EM BREVE',
                    textAlign: TextAlign.center,
                    style: mono(9, c: kHint, ls: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productImage(String source) {
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(),
      );
    }
    return netImg(source, fit: BoxFit.cover);
  }

  Widget _imageFallback() => Container(
        color: const Color(0xFF0A1F3A),
        child: const Center(
          child: Icon(Icons.phishing_outlined, color: kHint, size: 28),
        ),
      );
}
