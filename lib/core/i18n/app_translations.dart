import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 2.3 — Mode Bilingue Français / Arabe (Darija-friendly) avec bascule RTL native
class LocaleController extends GetxController {
  final isArabic = false.obs;

  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('app_locale') ?? 'fr';
      isArabic.value = code == 'ar';
      if (isArabic.value) {
        Get.updateLocale(const Locale('ar', 'MA'));
      }
    } catch (_) {}
  }

  Future<void> toggleLanguage() async {
    isArabic.value = !isArabic.value;
    final next = isArabic.value
        ? const Locale('ar', 'MA')
        : const Locale('fr', 'MA');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_locale', isArabic.value ? 'ar' : 'fr');
    } catch (_) {}
    Get.updateLocale(next);
  }
}

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'fr_MA': {
          'nav_home': 'Accueil',
          'nav_explore': 'Explorer',
          'nav_publish': 'Publier',
          'nav_messages': 'Messages',
          'nav_profile': 'Profil',
          'login_btn': 'Connexion',
          'search_hint': 'Vêtements, vélo, console…',
          'change_city': 'changer',
          'hero_title': 'Échangez malin,\nzéro frais !',
          'hero_sub': 'Troc sécurisé par double QR',
          'publish_item': 'Publier un objet',
          'smart_matches': 'Échanges compatibles pour vous',
          'recent_nearby': 'Nouveautés près de vous',
          'favorites': 'Mes favoris',
          'admin_panel': 'Administration & Modération',
          'lang_switch': 'العربية (RTL)',
          'propose_swap': 'Proposer un troc',
          'counter_offer': 'Contre-proposer',
          'safe_zones': 'Lieux publics vérifiés (Safe Zones)',
          'share_meeting': 'Partager ce RDV à un proche',
        },
        'ar_MA': {
          'nav_home': 'الرئيسية',
          'nav_explore': 'استكشاف',
          'nav_publish': 'نشر',
          'nav_messages': 'الرسائل',
          'nav_profile': 'حسابي',
          'login_btn': 'تسجيل الدخول',
          'search_hint': 'ملابس، دراجة، إلكترونيات…',
          'change_city': 'تغيير المدينة',
          'hero_title': 'بادل بذكاء،\nبدون عمولة!',
          'hero_sub': 'تبادل آمن عبر مسح رمزي QR',
          'publish_item': 'أضف غرضاً للتبادل',
          'smart_matches': 'تبادلات متوافقة مع أغراضك',
          'recent_nearby': 'جديد بالقرب منك',
          'favorites': 'المفضلة',
          'admin_panel': 'لوحة الإدارة والإشراف',
          'lang_switch': 'Français (LTR)',
          'propose_swap': 'اقترح تبادلاً',
          'counter_offer': 'عرض مضاد',
          'safe_zones': 'أماكن عامة آمنة للقاء',
          'share_meeting': 'مشاركة تفاصيل الموعد مع قريب',
        },
      };
}
