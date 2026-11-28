import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mode Bilingue complet Français / Arabe (RTL automatique via GetX)
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
          // Navigation
          'nav_home': 'Accueil',
          'nav_explore': 'Explorer',
          'nav_publish': 'Publier',
          'nav_messages': 'Messages',
          'nav_profile': 'Profil',
          // Common
          'login_btn': 'Connexion',
          'logout': 'Se déconnecter',
          'cancel': 'Annuler',
          'confirm': 'Confirmer',
          'save': 'Enregistrer',
          'loading': 'Chargement…',
          'error': 'Erreur',
          'success': 'Succès',
          'all_cities': 'Toutes les villes',
          'change_city': 'changer',
          // Feed & Categories
          'search_hint': 'Vêtements, vélo, console…',
          'hero_title': 'Échangez malin,\nzéro frais !',
          'hero_sub': 'Troc sécurisé par double QR',
          'publish_item': 'Publier un objet',
          'smart_matches': 'Échanges compatibles pour vous',
          'recent_nearby': 'Nouveautés près de vous',
          'categories': 'Catégories',
          'cat_all': 'Tout',
          'cat_vetements': 'Vêtements',
          'cat_electronique': 'Électronique',
          'cat_maison': 'Maison',
          'cat_sport': 'Sport',
          'cat_livres': 'Livres',
          'cat_bricolage': 'Bricolage',
          'cat_autre': 'Autre',
          // Profile
          'profile_title': 'Profil',
          'favorites': 'Mes favoris',
          'manage_listings': 'Gérer toutes mes annonces',
          'admin_panel': 'Administration & Modération',
          'lang_switch': 'العربية (RTL)',
          'trust_label': 'Confiance',
          'exchanges_label': 'Échanges',
          'reviews_label': 'avis',
          'tab_listings': 'Annonces',
          'tab_meetings': 'RDV',
          'tab_reviews': 'Avis',
          'no_listings_title': 'Aucune annonce publiée',
          'no_listings_sub': 'Ajoutez un objet pour commencer à proposer des échanges.',
          'login_profile_title': 'Connectez-vous à votre profil',
          'login_profile_sub': 'Consultez vos annonces, votre score de confiance, vos RDV QR et vos avis.',
          'sign_in': 'Se connecter',
          // Listing detail
          'details_title': 'Détails',
          'wishes_label': 'RECHERCHE EN ÉCHANGE',
          'open_swap': 'Échange ouvert',
          'description_label': 'Description',
          'no_description': 'Aucune description supplémentaire.',
          'report_listing': 'Signaler cette annonce',
          'propose_swap': 'Proposer un troc',
          'edit_listing': 'Modifier l\'annonce',
          'my_listings': 'Mes annonces',
          // Chat & Offers
          'offer_accepted': 'OFFRE ACCEPTÉE',
          'offer_rejected': 'OFFRE REFUSÉE',
          'offer_cancelled': 'OFFRE ANNULÉE',
          'offer_countered': 'CONTRE-PROPOSITION',
          'offer_received': 'PROPOSITION REÇUE',
          'offer_sent': 'PROPOSITION ENVOYÉE',
          'soulte_possible': 'Soulte possible',
          'view_offer_details': 'Voir les détails de l\'offre',
          'offer_details_title': 'Détails de la proposition',
          'offered_items': 'Objets proposés',
          'target_items': 'En échange de',
          'tap_to_inspect': 'Appuyez sur un objet pour voir sa fiche complète',
          'accept': 'Accepter',
          'reject': 'Refuser',
          'counter_offer': 'Contre-proposer',
          'plan_qr_meeting': 'Planifier le rendez-vous QR',
          'waiting_partner': 'En attente de la réponse…',
          'online_realtime': 'En ligne · temps réel',
          'connecting': 'Connexion…',
          'message_hint': 'Écrire un message…',
          'inbox_title': 'Messages',
          // Meetings & Safe zones
          'safe_zones': 'Lieux publics vérifiés (Safe Zones)',
          'share_meeting': 'Partager ce RDV à un proche',
          // Reports
          'report_title': 'Signaler',
          'report_heading': 'Quel est le problème ?',
          'report_confidential': 'Votre signalement est confidentiel et examiné par la modération.',
          'report_reason_fraud': 'Suspicion de fraude ou arnaque',
          'report_reason_spam': 'Annonce trompeuse, doublon ou spam',
          'report_reason_images': 'Photos ou contenu inapproprié',
          'report_reason_abusive': 'Comportement abusif ou harcèlement',
          'report_reason_other': 'Autre raison (ex. absence au RDV)',
          'report_details_label': 'Précisions (facultatif)',
          'report_details_hint': 'Décrivez brièvement la situation…',
          'report_submit': 'Envoyer le signalement',
          'report_sent_title': 'Signalement envoyé',
          'report_sent_body': 'Merci, l\'équipe de modération va l\'examiner.',
        },
        'ar_MA': {
          // Navigation
          'nav_home': 'الرئيسية',
          'nav_explore': 'استكشاف',
          'nav_publish': 'نشر',
          'nav_messages': 'الرسائل',
          'nav_profile': 'حسابي',
          // Common
          'login_btn': 'تسجيل الدخول',
          'logout': 'تسجيل الخروج',
          'cancel': 'إلغاء',
          'confirm': 'تأكيد',
          'save': 'حفظ',
          'loading': 'جاري التحميل…',
          'error': 'خطأ',
          'success': 'تم بنجاح',
          'all_cities': 'كل المدن',
          'change_city': 'تغيير المدينة',
          // Feed & Categories
          'search_hint': 'ملابس، دراجة، إلكترونيات…',
          'hero_title': 'بادل بذكاء،\nبدون عمولة!',
          'hero_sub': 'تبادل آمن عبر مسح رمزي QR',
          'publish_item': 'أضف غرضاً للتبادل',
          'smart_matches': 'تبادلات متوافقة مع أغراضك',
          'recent_nearby': 'جديد بالقرب منك',
          'categories': 'الفئات',
          'cat_all': 'الكل',
          'cat_vetements': 'ملابس',
          'cat_electronique': 'إلكترونيات',
          'cat_maison': 'المنزل',
          'cat_sport': 'رياضة',
          'cat_livres': 'كتب',
          'cat_bricolage': 'أدوات',
          'cat_autre': 'أخرى',
          // Profile
          'profile_title': 'حسابي',
          'favorites': 'المفضلة',
          'manage_listings': 'إدارة جميع إعلاناتي',
          'admin_panel': 'لوحة الإدارة والإشراف',
          'lang_switch': 'Français (LTR)',
          'trust_label': 'الثقة',
          'exchanges_label': 'التبادلات',
          'reviews_label': 'تقييمات',
          'tab_listings': 'إعلاناتي',
          'tab_meetings': 'المواعيد',
          'tab_reviews': 'التقييمات',
          'no_listings_title': 'لا توجد إعلانات منشورة',
          'no_listings_sub': 'أضف غرضاً للبدء في اقتراح التبادلات.',
          'login_profile_title': 'سجّل الدخول إلى حسابك',
          'login_profile_sub': 'تصفح إعلاناتك، نسبة الثقة، مواعيد QR والتقييمات.',
          'sign_in': 'تسجيل الدخول',
          // Listing detail
          'details_title': 'التفاصيل',
          'wishes_label': 'يبحث مقابل ذلك عن',
          'open_swap': 'مفتوح لأي تبادل',
          'description_label': 'الوصف',
          'no_description': 'لا يوجد وصف إضافي.',
          'report_listing': 'الإبلاغ عن هذا الإعلان',
          'propose_swap': 'اقترح تبادلاً',
          'edit_listing': 'تعديل الإعلان',
          'my_listings': 'إعلاناتي',
          // Chat & Offers
          'offer_accepted': 'تم قبول العرض',
          'offer_rejected': 'تم رفض العرض',
          'offer_cancelled': 'تم إلغاء العرض',
          'offer_countered': 'عرض مضاد',
          'offer_received': 'عرض وارد',
          'offer_sent': 'عرض مُرسَل',
          'soulte_possible': 'فارق مالي ممكن',
          'view_offer_details': 'عرض تفاصيل الاقتراح',
          'offer_details_title': 'تفاصيل عرض التبادل',
          'offered_items': 'الأغراض المقترحة',
          'target_items': 'مقابل الغرض',
          'tap_to_inspect': 'اضغط على أي غرض لعرض بطاقته الكاملة',
          'accept': 'قبول',
          'reject': 'رفض',
          'counter_offer': 'عرض مضاد',
          'plan_qr_meeting': 'تحديد موعد QR',
          'waiting_partner': 'في انتظار رد الطرف الآخر…',
          'online_realtime': 'متصل · مباشر',
          'connecting': 'جاري الاتصال…',
          'message_hint': 'اكتب رسالة…',
          'inbox_title': 'الرسائل',
          // Meetings & Safe zones
          'safe_zones': 'أماكن عامة آمنة للقاء',
          'share_meeting': 'مشاركة تفاصيل الموعد مع قريب',
          // Reports
          'report_title': 'إبلاغ',
          'report_heading': 'ما هي المشكلة؟',
          'report_confidential': 'بلاغك سري وسيتم فحصه من طرف فريق الإشراف.',
          'report_reason_fraud': 'اشتباه في احتيال أو نصب',
          'report_reason_spam': 'إعلان مضلل أو مكرر',
          'report_reason_images': 'صور أو محتوى غير لائق',
          'report_reason_abusive': 'سلوك مسيء أو تحرش',
          'report_reason_other': 'سبب آخر (مثل عدم الحضور للموعد)',
          'report_details_label': 'تفاصيل إضافية (اختياري)',
          'report_details_hint': 'اشرح المشكلة بإيجاز…',
          'report_submit': 'إرسال البلاغ',
          'report_sent_title': 'تم إرسال البلاغ',
          'report_sent_body': 'شكراً، سيقوم فريق الإشراف بمراجعته قريباً.',
        },
      };
}
