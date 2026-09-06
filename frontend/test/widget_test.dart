import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
