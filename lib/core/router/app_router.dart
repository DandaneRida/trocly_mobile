import 'package:get/get.dart';
import '../../features/feed/presentation/screens/splash_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/feed/presentation/screens/listing_detail_screen.dart';
import '../../features/feed/presentation/screens/search_screen.dart';
import '../../features/feed/presentation/screens/notifications_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/complete_profile_screen.dart';
import '../../features/listings/presentation/screens/create_listing_screen.dart';
import '../../features/listings/presentation/screens/my_listings_screen.dart';
import '../../features/offers/presentation/screens/propose_offer_screen.dart';
import '../../features/offers/presentation/screens/messages_inbox_screen.dart';
import '../../features/offers/presentation/screens/chat_screen.dart';
import '../../features/meeting/presentation/screens/propose_meeting_screen.dart';
import '../../features/meeting/presentation/screens/qr_screen.dart';
import '../../features/meeting/presentation/screens/scan_qr_screen.dart';
import '../../features/meeting/presentation/screens/review_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/report_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String feed = '/feed';
  static const String listingDetail = '/listing/:id';
  static const String search = '/search';
  static const String notifications = '/notifications';

  static const String login = '/login';
  static const String otp = '/otp';
  static const String completeProfile = '/complete-profile';

  static const String publish = '/publish';
  static const String myListings = '/my-listings';

  static const String proposeOffer = '/propose-offer/:id';
  static const String messages = '/messages';
  static const String chat = '/chat/:offerId';

  static const String planMeeting = '/plan-meeting/:id';
  static const String myQr = '/my-qr/:meetingId';
  static const String scanQr = '/scan-qr/:meetingId';
  static const String review = '/review/:meetingId';

  static const String profile = '/profile';
  static const String report = '/report';

  static final List<GetPage> routes = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: feed, page: () => const FeedScreen()),
    GetPage(name: listingDetail, page: () => const ListingDetailScreen()),
    GetPage(name: search, page: () => const SearchScreen()),
    GetPage(name: notifications, page: () => const NotificationsScreen()),

    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: otp, page: () => const OtpScreen()),
    GetPage(name: completeProfile, page: () => const CompleteProfileScreen()),

    GetPage(name: publish, page: () => const CreateListingScreen()),
    GetPage(name: myListings, page: () => const MyListingsScreen()),

    GetPage(name: proposeOffer, page: () => const ProposeOfferScreen()),
    GetPage(name: messages, page: () => const MessagesInboxScreen()),
    GetPage(name: chat, page: () => const ChatScreen()),

    GetPage(name: planMeeting, page: () => const ProposeMeetingScreen()),
    GetPage(name: myQr, page: () => const QrScreen()),
    GetPage(name: scanQr, page: () => const ScanQrScreen()),
    GetPage(name: review, page: () => const ReviewScreen()),

    GetPage(name: profile, page: () => const ProfileScreen()),
    GetPage(name: report, page: () => const ReportScreen()),
  ];
}
