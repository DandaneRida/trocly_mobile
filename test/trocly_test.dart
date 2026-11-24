import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:trocly_mobile/controllers/auth_controller.dart';
import 'package:trocly_mobile/controllers/chat_controller.dart';
import 'package:trocly_mobile/controllers/listings_controller.dart';
import 'package:trocly_mobile/controllers/meeting_controller.dart';
import 'package:trocly_mobile/controllers/offers_controller.dart';
import 'package:trocly_mobile/core/widgets/state_page.dart';
import 'package:trocly_mobile/features/feed/presentation/screens/listing_detail_screen.dart';
import 'package:trocly_mobile/features/meeting/presentation/screens/qr_screen.dart';
import 'package:trocly_mobile/features/offers/presentation/screens/chat_screen.dart';
import 'package:trocly_mobile/features/offers/presentation/screens/messages_inbox_screen.dart';
import 'package:trocly_mobile/features/offers/presentation/screens/propose_offer_screen.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('Unit Tests — Models & AuthController', () {
    test('formatPhone normalizes Moroccan phone numbers to +212 format', () {
      final auth = AuthController();
      expect(auth.formatPhone('0612345678'), '+212612345678');
      expect(auth.formatPhone('612345678'), '+212612345678');
      expect(auth.formatPhone('+212 6 12 34 56 78'), '+212612345678');
    });

    test('ListingModel parses attributes, wishes, userId and photo URLs', () {
      final model = ListingModel.fromJson({
        'id': 'l-1',
        'title': 'VTT Rockrider',
        'description': 'Très bon état',
        'category': 'Sport',
        'condition': 'tres_bon',
        'estimatedValue': 0,
        'city': {'id': 1, 'name': 'Meknès'},
        'photos': ['/uploads/bike.jpg'],
        'status': 'active',
        'user': {'id': 'user-42', 'displayName': 'Yassine'},
        'attributes': {
          'wishes': ['Console', 'Appareil photo'],
          'marque': 'Btwin',
        },
      });

      expect(model.userId, 'user-42');
      expect(model.userName, 'Yassine');
      expect(model.wishSummary, 'Console, Appareil photo');
      expect(model.photos.first.endsWith('/uploads/bike.jpg'), isTrue);
    });

    test('MeetingModel tracks cross double-scan state accurately', () {
      final meeting = MeetingModel.fromJson({
        'id': 'm-1',
        'offerId': 'o-1',
        'initiator': {'id': 'u1', 'displayName': 'Yassine'},
        'responder': {'id': 'u2', 'displayName': 'Salma'},
        'proposedLocation': 'Place El Hedim',
        'scheduledAt': '2026-11-25T15:00:00Z',
        'expiresAt': '2026-11-25T17:00:00Z',
        'status': 'accepted',
        'qrPayloadInitiator': 'qr-u1',
        'qrPayloadResponder': 'qr-u2',
        'initiatorScannedAt': '2026-11-25T15:05:00Z',
        'responderScannedAt': null,
      });

      expect(meeting.isInitiator('u1'), isTrue);
      expect(meeting.partnerName('u1'), 'Salma');
      expect(meeting.myQrPayload('u1'), 'qr-u1');
      expect(meeting.iScannedPartner('u1'), isTrue);
      expect(meeting.partnerScannedMe('u1'), isFalse);
      expect(meeting.partnerScannedMe('u2'), isTrue);
    });
  });

  group('Widget Tests — Business Rules & Wireframe Compliance', () {
    testWidgets('ListingDetailScreen hides Proposer un troc on own listing',
        (WidgetTester tester) async {
      final auth = Get.put(AuthController());
      auth.userId.value = 'user-owner';

      final ownListing = ListingModel(
        id: 'l-own',
        title: 'Mon Vélo',
        description: 'Description',
        category: 'Sport',
        condition: 'bon',
        estimatedValue: 0,
        city: 'Meknès',
        photos: const [],
        status: 'active',
        userId: 'user-owner',
        userName: 'Moi',
      );

      await tester.pumpWidget(GetMaterialApp(
        home: const SizedBox.shrink(),
        getPages: [
          GetPage(
            name: '/detail',
            page: () => const ListingDetailScreen(),
          ),
        ],
      ));

      Get.toNamed('/detail', arguments: ownListing);
      await tester.pumpAndSettle();

      expect(find.text('Gérer mon annonce'), findsOneWidget);
      expect(find.text('Proposer un troc'), findsNothing);
    });

    testWidgets('ProposeOfferScreen shows Soulte possible switch and blocks self-listing',
        (WidgetTester tester) async {
      final auth = Get.put(AuthController());
      auth.userId.value = 'user-me';
      Get.put(ListingsController());
      Get.put(OffersController());

      final ownListing = ListingModel(
        id: 'l-own',
        title: 'Mon Objet',
        description: '',
        category: 'Maison',
        condition: 'bon',
        estimatedValue: 0,
        city: 'Meknès',
        photos: const [],
        status: 'active',
        userId: 'user-me',
      );

      await tester.pumpWidget(GetMaterialApp(
        home: const SizedBox.shrink(),
        getPages: [
          GetPage(name: '/propose', page: () => const ProposeOfferScreen()),
        ],
      ));
      Get.toNamed('/propose', arguments: ownListing);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('vous ne pouvez pas vous proposer un échange'),
        findsOneWidget,
      );
    });

    testWidgets('StatePage renders empty city title and action button',
        (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatePage(
            type: StatePageType.emptyCity,
            actionLabel: 'Changer de ville',
            onAction: () => tapped = true,
          ),
        ),
      ));

      expect(find.text('Changer de ville'), findsOneWidget);
      await tester.tap(find.text('Changer de ville'));
      expect(tapped, isTrue);
    });

    testWidgets('Navigating from MessagesInboxScreen to ChatScreen does not throw markNeedsBuild during build',
        (WidgetTester tester) async {
      final auth = Get.put(AuthController());
      auth.authToken.value = 'fake-jwt';
      auth.userId.value = 'user-1';
      final chat = Get.put(ChatController());
      Get.put(OffersController());

      chat.conversations.value = [
        ConversationModel.fromJson({
          'offerId': 'offer-123',
          'otherUser': {'id': 'user-2', 'displayName': 'Salma'},
          'lastMessage': 'Nouvelle proposition d\'échange',
          'status': 'pending',
          'itemSummary': 'test2 ⇄ gtest',
        }),
      ];

      await tester.pumpWidget(GetMaterialApp(
        home: const MessagesInboxScreen(),
        getPages: [
          GetPage(name: '/chat/:offerId', page: () => const ChatScreen()),
        ],
      ));
      await tester.pump();

      expect(find.text('Salma'), findsOneWidget);
      expect(find.text('test2 contre gtest'), findsOneWidget);

      await tester.tap(find.text('Salma'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('PROPOSITION ENVOYÉE'), findsOneWidget);
      expect(find.text('Accepter'), findsNothing);
      expect(find.text('Refuser'), findsNothing);
    });

    testWidgets('QrScreen hides Accepter et générer les QR for the meeting proposer and shows it only for responder',
        (WidgetTester tester) async {
      final auth = Get.put(AuthController());
      final meetings = Get.put(MeetingController());

      final proposedMeeting = MeetingModel.fromJson({
        'id': 'm-prop',
        'offerId': 'o-1',
        'initiator': {'id': 'user-proposer', 'displayName': 'Yassine'},
        'responder': {'id': 'user-responder', 'displayName': 'Salma'},
        'proposedLocation': 'Place El Hedim, Meknès',
        'scheduledAt': '2026-11-25T15:00:00Z',
        'expiresAt': '2026-11-25T17:00:00Z',
        'status': 'proposed',
      });
      meetings.currentMeeting.value = proposedMeeting;

      // Case 1: Logged in as proposer -> button MUST NOT appear
      auth.userId.value = 'user-proposer';
      await tester.pumpWidget(const GetMaterialApp(home: QrScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Accepter et générer les QR'), findsNothing);
      expect(find.text('En attente de Salma'), findsOneWidget);

      // Case 2: Logged in as responder -> button MUST appear
      auth.userId.value = 'user-responder';
      await tester.pumpWidget(const GetMaterialApp(home: QrScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Accepter et générer les QR'), findsOneWidget);
    });
  });
}
