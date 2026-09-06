// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/supabase_config.dart';

/// Debug test: verifies what PostgREST returns for listClaimsForItem
/// when called under an authenticated finder's JWT.
void main() {
  test('Debug: listClaimsForItem returns claims with contacts join', () async {
    // The earbuds item with 1 claim owned by Tanishk, claimed by Parth
    const testItemId = 'bc4f29ea-8277-43d5-840f-7478e48361ef';

    // Step 1: Auth as test user
    final authRes = await http.post(
      Uri.parse('${SupabaseConfig.supabaseUrl}/auth/v1/token?grant_type=password'),
      headers: {
        'apikey': SupabaseConfig.supabaseAnonKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': 'test@campus.edu', 'password': 'test@123'}),
    );

    expect(authRes.statusCode, 200, reason: 'Auth failed: ${authRes.body}');
    final authData = jsonDecode(authRes.body) as Map<String, dynamic>;
    final jwt = authData['access_token'] as String;
    final userId = (authData['user'] as Map)['id'] as String;
    print('\n✅ Authenticated as test@campus.edu (id: $userId)');

    // Step 2: Fetch my items (as test user finder)
    final myItemsRes = await http.get(
      Uri.parse(
          '${SupabaseConfig.supabaseUrl}/rest/v1/items?finder_contact_id=eq.$userId&select=item_id,item_type,location_found,claims(count)'),
      headers: {
        'apikey': SupabaseConfig.supabaseAnonKey,
        'Authorization': 'Bearer $jwt',
        'Accept': 'application/json',
      },
    );
    expect(myItemsRes.statusCode, 200, reason: 'Items fetch failed: ${myItemsRes.body}');
    final myItems = jsonDecode(myItemsRes.body) as List;
    print('📦 My items (${myItems.length} total):');
    for (final item in myItems) {
      final count = (item['claims'] as List?)?.firstOrNull?['count'] ?? 0;
      print('   ${item['item_id']} | ${item['item_type']} | claims=$count');
    }

    // Step 3: Fetch claims for each of my items with claims
    for (final item in myItems) {
      final itemId = item['item_id'] as String;
      final count = (item['claims'] as List?)?.firstOrNull?['count'] ?? 0;
      if (count == 0) continue;

      print('\n🔍 Fetching claims for item $itemId (expected $count claim(s))...');

      // EXACT query that listClaimsForItem uses in api_service.dart
      final claimsRes = await http.get(
        Uri.parse(
            '${SupabaseConfig.supabaseUrl}/rest/v1/claims?item_id=eq.$itemId&select=*,contacts(contact_id,name,class,branch)&order=created_at.desc'),
        headers: {
          'apikey': SupabaseConfig.supabaseAnonKey,
          'Authorization': 'Bearer $jwt',
          'Accept': 'application/json',
        },
      );

      print('   HTTP Status: ${claimsRes.statusCode}');
      print('   Response: ${claimsRes.body}');

      expect(claimsRes.statusCode, 200, reason: 'Claims fetch failed: ${claimsRes.body}');
      final claims = jsonDecode(claimsRes.body) as List;
      print('   ✅ Claims returned: ${claims.length}');

      for (final c in claims) {
        print('      claim_id: ${c['claim_id']}');
        print('      status: ${c['status']}');
        print('      contacts: ${c['contacts']}');
      }

      // KEY ASSERTION: must get back the same count
      expect(claims.length, greaterThan(0),
          reason:
              '‼️ count query says $count but claims fetch returned 0! RLS is blocking the SELECT.');
    }

    // Step 4: Cross-check - try to fetch Tanishk's item claims as test user (should return empty due to RLS)
    print('\n🔐 Cross-check: fetching a different finder\'s item claims (should be blocked by RLS)...');
    final wrongItemRes = await http.get(
      Uri.parse(
          '${SupabaseConfig.supabaseUrl}/rest/v1/claims?item_id=eq.$testItemId&select=*,contacts(contact_id,name,class,branch)'),
      headers: {
        'apikey': SupabaseConfig.supabaseAnonKey,
        'Authorization': 'Bearer $jwt',
        'Accept': 'application/json',
      },
    );
    final wrongClaims = jsonDecode(wrongItemRes.body) as List;
    print('   Returned ${wrongClaims.length} claim(s) for another finder\'s item (expected 0)');
    expect(wrongClaims.length, equals(0),
        reason: 'RLS should block finder from seeing another finder\'s item claims!');
    print('   ✅ RLS correctly blocked cross-finder access.');
  });
}
