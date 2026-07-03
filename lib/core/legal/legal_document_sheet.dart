import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/aqx_l10n.dart';
import 'aqx_legal_urls.dart';

/// Resumo legal in-app + link para política completa na web.
class LegalDocumentSheet extends StatelessWidget {
  const LegalDocumentSheet({
    super.key,
    required this.title,
    required this.body,
    required this.fullUrl,
    required this.t,
  });

  final String title;
  final String body;
  final String fullUrl;
  final AqxL10n t;

  static Future<void> showPrivacy(BuildContext context, AqxL10n t) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1628),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LegalDocumentSheet(
        title: t.legalPrivacyTitle,
        body: t.legalPrivacySummary,
        fullUrl: AqxLegalUrls.privacyPolicy,
        t: t,
      ),
    );
  }

  static Future<void> showTerms(BuildContext context, AqxL10n t) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1628),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LegalDocumentSheet(
        title: t.legalTermsTitle,
        body: t.legalTermsSummary,
        fullUrl: AqxLegalUrls.termsOfService,
        t: t,
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.legalLinkError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF00F5FF);
    const hint = Color(0xFF8AADBE);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cyan,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    body,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13,
                      height: 1.55,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _openUrl(context, fullUrl),
                  child: Text(
                    t.legalOpenFullVersion,
                    style: const TextStyle(color: cyan, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => _openUrl(context, AqxLegalUrls.supportEmail),
                  child: Text(
                    t.legalContact,
                    style: const TextStyle(color: hint, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Linha compacta Privacidade · Termos para login e perfil.
class LegalLinksRow extends StatelessWidget {
  const LegalLinksRow({super.key, required this.t});

  final AqxL10n t;

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF00F5FF);
    const hint = Color(0xFF8AADBE);

    Widget link(String label, VoidCallback onTap) => TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            label,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              color: cyan,
              fontWeight: FontWeight.w500,
            ),
          ),
        );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        link(t.legalPrivacyLink, () => LegalDocumentSheet.showPrivacy(context, t)),
        Text('·', style: TextStyle(color: hint.withValues(alpha: 0.6), fontSize: 11)),
        link(t.legalTermsLink, () => LegalDocumentSheet.showTerms(context, t)),
      ],
    );
  }
}
