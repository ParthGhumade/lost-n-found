import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app_theme.dart';
import 'package:frontend/input_sanitizer.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models.dart';
import 'package:frontend/screens/feed_screen.dart';
import 'package:frontend/screens/my_claims_screen.dart';
import 'package:frontend/screens/my_listings_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/report_item_screen.dart';
import 'package:frontend/widgets/mutual_contact_modal.dart';

void main() {
  testWidgets('App smoke test loads LoginPage with campus branding', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
    ));
    expect(find.text('Campus Lost & Found'), findsOneWidget);
    expect(find.text('New Student? Create Account (Signup)'), findsOneWidget);
    expect(find.text('Sign In to Campus Portal'), findsOneWidget);
  });

  testWidgets('ReportItemScreen renders category and form fields', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const ReportItemScreen(),
    ));

    expect(find.text('Report Found Item'), findsOneWidget);
    expect(find.text('Item Category'), findsOneWidget);
    expect(find.text('Where was it found?'), findsOneWidget);
    expect(find.text('Verification Photo'), findsOneWidget);
    expect(find.text('Publish Listing'), findsOneWidget);
  });

  group('Model Serialization Tests', () {
    test('LostItem serialization and deserialization', () {
      final json = {
        'item_id': '11111111-1111-1111-1111-111111111111',
        'item_type': 'Earphones',
        'location_found': 'Room 6504',
        'date_found': '2026-09-05',
        'status': 'open',
        'created_at': '2026-09-05T10:00:00Z',
        'claims': [
          {'count': 2}
        ]
      };

      final item = LostItem.fromJson(json);
      expect(item.itemId, '11111111-1111-1111-1111-111111111111');
      expect(item.itemType, 'Earphones');
      expect(item.locationFound, 'Room 6504');
      expect(item.status, ItemStatus.open);
      expect(item.claimsCount, 2);
    });

    test('ItemClaim status mapping', () {
      final json = {
        'claim_id': '22222222-2222-2222-2222-222222222222',
        'item_id': '11111111-1111-1111-1111-111111111111',
        'claimant_contact_id': '33333333-3333-3333-3333-333333333333',
        'claim_description': 'Black case with scratches',
        'status': 'claim_verified',
      };

      final claim = ItemClaim.fromJson(json);
      expect(claim.status, ClaimStatus.claimVerified);
      expect(claim.status.displayLabel, 'Verified (Photo Ready)');
      expect(claim.claimantAgreedPhoto, false);

      final jsonWithAgreed = {
        ...json,
        'claimant_agreed_photo': true,
      };
      final claimAgreed = ItemClaim.fromJson(jsonWithAgreed);
      expect(claimAgreed.claimantAgreedPhoto, true);
    });

    test('MutualContactExchange deserialization', () {
      final json = {
        'claimId': '22222222-2222-2222-2222-222222222222',
        'status': 'claim_verified',
        'finder': {
          'name': 'Alex Finder',
          'class': 'BE - Div A',
          'branch': 'Mechanical',
          'contactNumber': '+91 9123456780',
        },
        'claimant': {
          'name': 'Sam Claimant',
          'class': 'TE - Div B',
          'branch': 'Computer Science',
          'contactNumber': '+91 9988776655',
        },
      };

      final exchange = MutualContactExchange.fromJson(json);
      expect(exchange.finder.name, 'Alex Finder');
      expect(exchange.claimant.branch, 'Computer Science');
      expect(exchange.finder.contactNumber, '+91 9123456780');
    });
  });

  group('InputSanitizer Security & Uniqueness Tests', () {
    test('Sanitizes malicious file names with path traversal', () {
      final sanitized = InputSanitizer.sanitizeFileName('../../etc/passwd..//my photo #1.png');
      expect(sanitized, 'my_photo_1');
      expect(sanitized.contains('/'), isFalse);
      expect(sanitized.contains('\\'), isFalse);
      expect(sanitized.contains('..'), isFalse);
    });

    test('Sanitizes file extension', () {
      expect(InputSanitizer.sanitizeFileExtension('.JPEG'), 'jpg');
      expect(InputSanitizer.sanitizeFileExtension('png'), 'png');
      expect(InputSanitizer.sanitizeFileExtension('exe'), 'jpg'); // Unsupported defaults to jpg
    });

    test('buildUniqueStoragePath generates different paths for identical inputs', () {
      const uid = 'user-123';
      const commonName = 'photo.jpg';

      final path1 = InputSanitizer.buildUniqueStoragePath(
        userId: uid,
        originalFileName: commonName,
        rawExtension: 'jpg',
      );

      final path2 = InputSanitizer.buildUniqueStoragePath(
        userId: uid,
        originalFileName: commonName,
        rawExtension: 'jpg',
      );

      expect(path1.startsWith('user-123/'), isTrue);
      expect(path2.startsWith('user-123/'), isTrue);
      expect(path1, isNot(equals(path2))); // Guaranteed uniqueness
      expect(path1.endsWith('_photo.jpg'), isTrue);
    });

    test('Sanitizes phone numbers', () {
      expect(InputSanitizer.sanitizePhoneNumber('+91 (987) 654-3210'), '+919876543210');
    });
  });

  group('Responsiveness & Overflow Prevention Tests', () {
    testWidgets('ReportItemScreen renders without overflow on ultra-narrow screen (320x568)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ReportItemScreen(),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Report Found Item'), findsOneWidget);
    });

    testWidgets('LoginPage renders without overflow on small screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LoginPage(),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Campus Lost & Found'), findsOneWidget);
    });

    testWidgets('MyClaimsScreen renders without overflow on mobile screen (345x600)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(345, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MyClaimsScreen(),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('My Claims'), findsOneWidget);
    });

    testWidgets('FeedScreen renders Report Found button below header', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: FeedScreen(
            onRequestReportItem: () {},
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Campus Feed'), findsOneWidget);
      expect(find.text('Report Found'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders student profile details and sign out button', (WidgetTester tester) async {
      final mockProfile = ContactProfile(
        contactId: 'c1',
        name: 'Alex Student',
        studentClass: 'BE - Div A',
        branch: 'Computer Science',
        contactNumber: '+91 9876543210',
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProfileScreen(initialProfile: mockProfile),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Alex Student'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('MutualContactModal renders initial contact exchange header', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: MutualContactModal(
            claimId: 'test-claim-id',
            viewerRole: ContactViewerRole.finder,
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Contact Exchange'), findsOneWidget);
    });

    testWidgets('MyListingsScreen renders and mounts realtime channels safely', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MyListingsScreen(),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('My Reported Items'), findsOneWidget);
    });
  });
}
