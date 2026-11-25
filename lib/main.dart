import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/i18n/app_translations.dart';
import 'core/services/fcm_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/listings_controller.dart';
import 'controllers/offers_controller.dart';
import 'controllers/chat_controller.dart';
import 'controllers/meeting_controller.dart';
import 'controllers/reviews_controller.dart';
import 'controllers/notifications_controller.dart';
import 'controllers/favorites_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localeController =
      Get.put<LocaleController>(LocaleController(), permanent: true);
  await localeController.loadSavedLocale();

  final authController =
      Get.put<AuthController>(AuthController(), permanent: true);
  await authController.loadStoredToken();

  Get.put<ListingsController>(ListingsController(), permanent: true);
  Get.put<OffersController>(OffersController(), permanent: true);
  Get.put<ChatController>(ChatController(), permanent: true);
  Get.put<MeetingController>(MeetingController(), permanent: true);
  Get.put<ReviewsController>(ReviewsController(), permanent: true);
  Get.put<NotificationsController>(NotificationsController(), permanent: true);
  final favs =
      Get.put<FavoritesController>(FavoritesController(), permanent: true);
  favs.loadFavorites();

  if (authController.authToken.value.isNotEmpty) {
    FcmService.initAndSyncToken();
  }

  runApp(const TroclyApp());
}

class TroclyApp extends StatelessWidget {
  const TroclyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeCtrl = Get.find<LocaleController>();
    return GetMaterialApp(
      title: 'Trocly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      translations: AppTranslations(),
      locale: localeCtrl.isArabic.value
          ? const Locale('ar', 'MA')
          : const Locale('fr', 'MA'),
      fallbackLocale: const Locale('fr', 'MA'),
      initialRoute: AppRouter.splash,
      getPages: AppRouter.routes,
    );
  }
}
