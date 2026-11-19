import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'controllers/auth_controller.dart';
import 'controllers/listings_controller.dart';
import 'controllers/offers_controller.dart';
import 'controllers/chat_controller.dart';
import 'controllers/meeting_controller.dart';
import 'controllers/reviews_controller.dart';
import 'controllers/notifications_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global GetX controllers
  final authController = Get.put<AuthController>(AuthController(), permanent: true);
  await authController.loadStoredToken();

  Get.put<ListingsController>(ListingsController(), permanent: true);
  Get.put<OffersController>(OffersController(), permanent: true);
  Get.put<ChatController>(ChatController(), permanent: true);
  Get.put<MeetingController>(MeetingController(), permanent: true);
  Get.put<ReviewsController>(ReviewsController(), permanent: true);
  Get.put<NotificationsController>(NotificationsController(), permanent: true);

  runApp(const TroclyApp());
}

class TroclyApp extends StatelessWidget {
  const TroclyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Trocly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRouter.splash,
      getPages: AppRouter.routes,
    );
  }
}
