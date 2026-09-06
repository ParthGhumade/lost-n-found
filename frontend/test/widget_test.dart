import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/input_sanitizer.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models.dart';

void main() {
  testWidgets('App smoke test loads LoginPage', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    expect(find.text('Campus Lost & Found'), findsOneWidget);
    expect(find.text('Quick Test Login (test / test@123)'), findsOneWidget);
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
          'prn': 'PRN998877',
          'contactNumber': '+91 9988776655',
        },
      };

      final exchange = MutualContactExchange.fromJson(json);
      expect(exchange.finder.name, 'Alex Finder');
      expect(exchange.claimant.prn, 'PRN998877');
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

    test('Sanitizes phone numbers and PRNs', () {
      expect(InputSanitizer.sanitizePhoneNumber('+91 (987) 654-3210'), '+919876543210');
      expect(InputSanitizer.sanitizePrn('  prn-1234-ab '), 'PRN-1234-AB');
    });
  });
}
