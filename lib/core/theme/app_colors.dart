import 'package:flutter/material.dart';

/// Trocly Modern Design System — Warm Peach Cream, Crisp White Cards & Sunset Coral Pills
class AppColors {
  // ── Surfaces & Fond Crème Pêche ─────────────────────────
  static const Color paper            = Color(0xFFFAF2EC); // fond chaud pêche-crème
  static const Color background       = paper;
  static const Color surface          = Color(0xFFFFFFFF); // cartes & champs blanc pur
  static const Color card             = Color(0xFFFFFFFF);
  static const Color bubble           = Color(0xFFF3E7DF); // pastilles / bulles sable doux
  static const Color segmentedBg      = Color(0xFFF1E4DC);
  static const Color imagePlaceholder = Color(0xFFDCE5EC); // fond photo bleu-gris doux

  // ── Bannière Héro (bleu ciel doux qui fait ressortir le corail) ──
  static const Color bannerStart      = Color(0xFF7FA9C9);
  static const Color bannerEnd        = Color(0xFFA7C6DD);

  // ── Encre & Accent Corail ───────────────────────────────
  static const Color ink              = Color(0xFF1F1C1A); // charbon chaud
  static const Color primary          = Color(0xFFEB764E); // corail moderne
  static const Color accent           = Color(0xFFEB764E); // corail sunset (pilules & CTA)
  static const Color accentDark       = Color(0xFFD96139);
  static const Color accentLight      = Color(0xFFFDECE5); // pêche tendre

  // ── Texte (contraste renforcé pour une lecture nette) ────
  static const Color textPrimary      = ink;
  static const Color textSecondary    = Color(0xFF5A504B);
  static const Color textHint         = Color(0xFF837872);

  // ── Filets & Bordures ───────────────────────────────────
  static const Color line             = Color(0xFFEDE1D9);
  static const Color border           = line;
  static const Color borderLight      = Color(0xFFE5D7CD);
  static const Color borderStrong     = Color(0xFFCEBFB4);
  static const Color divider          = line;

  // ── États sémantiques ───────────────────────────────────
  static const Color success          = Color(0xFF2B7A57);
  static const Color successLight     = Color(0xFFE6F4ED);
  static const Color warning          = Color(0xFFD4831D);
  static const Color warningLight     = Color(0xFFFFF4E3);
  static const Color error            = Color(0xFFD14343);
  static const Color errorLight       = Color(0xFFFDECEC);

  // ── Chips & Badges ──────────────────────────────────────
  static const Color chipSelected     = accent;
  static const Color chipUnselected   = surface;
  static const Color chipBorder       = line;
  static const Color badge            = bubble;

  // ── Ombres douces modernes ──────────────────────────────
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0D2C1A12),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> pillShadow = [
    BoxShadow(
      color: Color(0x102C1A12),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> coralShadow = [
    BoxShadow(
      color: Color(0x3DEB764E),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> navShadow = [
    BoxShadow(
      color: Color(0x142C1A12),
      blurRadius: 24,
      offset: Offset(0, -6),
    ),
  ];
}
