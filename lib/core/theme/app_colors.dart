import 'package:flutter/material.dart';

/// Trocly Design System — Couleurs extraites des wireframes
class AppColors {
  // ── Marque ──────────────────────────────────────────────
  static const Color primary      = Color(0xFF1B4F72); // bleu ENSAM
  static const Color accent       = Color(0xFFE67E22); // orange CTA
  static const Color accentLight  = Color(0xFFFFF3E0);

  // ── Surfaces ───────────────────────────────────────────
  static const Color background   = Color(0xFFF4F6F8);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color card         = Color(0xFFFFFFFF);

  // ── Texte ──────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF3D4650);
  static const Color textHint      = Color(0xFF7B858F);

  // ── Bordures ───────────────────────────────────────────
  static const Color border       = Color(0xFFC5CCD3);
  static const Color borderLight  = Color(0xFFAAB2BA);
  static const Color divider      = Color(0xFFD5DBE0);

  // ── État ───────────────────────────────────────────────
  static const Color error        = Color(0xFF8A1C1C);
  static const Color errorLight   = Color(0xFFFDE8E8);
  static const Color success      = Color(0xFF27AE60);
  static const Color successLight = Color(0xFFD6E6F2);
  static const Color warning      = Color(0xFFF39C12);

  // ── Chips ──────────────────────────────────────────────
  static const Color chipSelected     = primary;
  static const Color chipUnselected   = surface;
  static const Color chipBorder       = primary;

  // ── Badges ─────────────────────────────────────────────
  static const Color badge            = Color(0xFFD5DBE0);
}
