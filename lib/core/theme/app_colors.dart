import 'package:flutter/material.dart';

/// Trocly Design System — Direction éditoriale « Papier, encre, terre cuite »
class AppColors {
  // ── Surfaces & Papier ───────────────────────────────────
  static const Color paper        = Color(0xFFF5F3EE);
  static const Color background   = paper;
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color card         = Color(0xFFFFFFFF);
  static const Color bubble       = Color(0xFFEEEBE4);
  static const Color segmentedBg  = Color(0xFFE9E5DC);
  static const Color imagePlaceholder = Color(0xFFDDD8CE);

  // ── Encre & Marque ──────────────────────────────────────
  static const Color ink          = Color(0xFF15140F);
  static const Color primary      = ink;
  static const Color accent       = Color(0xFFD4532B); // terre cuite
  static const Color accentLight  = Color(0xFFFBEDE6);

  // ── Texte ───────────────────────────────────────────────
  static const Color textPrimary   = ink;
  static const Color textSecondary = Color(0xFF5E5B53);
  static const Color textHint      = Color(0xFF9A968C);

  // ── Filets & Bordures ───────────────────────────────────
  static const Color line         = Color(0xFFE6E2D9);
  static const Color border       = line;
  static const Color borderLight  = Color(0xFFD9D5CB);
  static const Color borderStrong = Color(0xFFBDB8AC);
  static const Color divider      = line;

  // ── États sémantiques ───────────────────────────────────
  static const Color success      = Color(0xFF2E6B4E);
  static const Color successLight = Color(0xFFE7F0EA);
  static const Color warning      = Color(0xFFB86B14);
  static const Color warningLight = Color(0xFFFBF2E3);
  static const Color error        = Color(0xFF9E2A2B);
  static const Color errorLight   = Color(0xFFFCECEC);

  // ── Chips & Badges ──────────────────────────────────────
  static const Color chipSelected   = ink;
  static const Color chipUnselected = surface;
  static const Color chipBorder     = line;
  static const Color badge          = bubble;
}
