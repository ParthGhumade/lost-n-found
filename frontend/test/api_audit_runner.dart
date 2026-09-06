// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

const supabaseUrl = 'https://qmlzegacppfjsrgzacbi.supabase.co';
const anonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFtbHplZ2FjcHBmanNyZ3phY2JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg2ODQ3OTIsImV4cCI6MjEwNDI2MDc5Mn0._7DMfB7mSWefVUdVamPsb0yWuNLykXNmR2u6HZdxRAY';

void main() async {
  print('=== STARTING END-TO-END API AUDIT SUITE ===');
  int passed = 0;
  int failed = 0;

  Future<void> runTest(String name, Future<void> Function() testFn) async {
    try {
      await testFn();
      print('  [PASS] $name');
      passed++;
    } catch (e) {
      print('  [FAIL] $name: $e');
      failed++;
    }
  }

  // Helper: login user and get access token
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      throw Exception('Login failed for $email: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // 1. Authenticate Finder (test@campus.edu)
  String finderToken = '';
  String finderId = '';
  await runTest('1. Auth Finder (test@campus.edu / test@123)', () async {
    final data = await login('test@campus.edu', 'test@123');
    finderToken = data['access_token'];
    finderId = data['user']['id'];
    if (finderToken.isEmpty) throw Exception('No access token');
  });

  // 2. Authenticate Claimant (claimant@campus.edu / claimant@123)
  String claimantToken = '';
  String claimantId = '';
  await runTest('2. Auth Claimant (claimant@campus.edu / claimant@123)', () async {
    final data = await login('claimant@campus.edu', 'claimant@123');
    claimantToken = data['access_token'];
    claimantId = data['user']['id'];
    if (claimantToken.isEmpty) throw Exception('No access token');
  });

  // 3. Contacts API: Get Current User Profile (Finder)
  await runTest('3. Contacts API: Get Profile (Finder)', () async {
    final res = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/contacts?contact_id=eq.$finderId&select=*'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $finderToken',
      },
    );
    if (res.statusCode != 200) throw Exception('${res.statusCode} ${res.body}');
    final list = jsonDecode(res.body) as List;
    if (list.isEmpty) throw Exception('No contact profile found for finder');
    final p = list.first;
    if (p['name'] != 'Test Student') throw Exception('Unexpected name: ${p['name']}');
  });

  // 4. Contacts API: Update Profile
  await runTest('4. Contacts API: Update Profile', () async {
    final res = await http.patch(
      Uri.parse('$supabaseUrl/rest/v1/contacts?contact_id=eq.$finderId'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $finderToken',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      },
      body: jsonEncode({'contact_number': '+91 9876543210'}),
    );
    if (res.statusCode != 200) throw Exception('${res.statusCode} ${res.body}');
  });

  // 5. Storage API: Upload Private Image (Finder)
  String imagePath = '';
  await runTest('5. Storage API: Upload Item Image to Private Bucket', () async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    imagePath = '$finderId/${timestamp}_earbuds.jpg';
    final dummyBytes = Uint8List.fromList(utf8.encode('Fake JPEG Image Bytes for Audit Test'));

    final res = await http.post(
      Uri.parse('$supabaseUrl/storage/v1/object/item-images-private/$imagePath'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $finderToken',
        'Content-Type': 'image/jpeg',
      },
      body: dummyBytes,
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Upload failed: ${res.statusCode} ${res.body}');
    }
  });

  // 6. Items API: Create Item Listing (Finder)
  String createdItemId = '';
  await runTest('6. Items API: Create Item Listing', () async {
    final res = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/items'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $finderToken',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      },
      body: jsonEncode({
        'finder_contact_id': finderId,
        'item_type': 'Earphones',
        'location_found': 'Room 6504, 5th Floor Engineering Bldg',
        'date_found': '2026-09-06',
        'image_path': imagePath,
        'status': 'open',
      }),
    );
    if (res.statusCode != 201) throw Exception('${res.statusCode} ${res.body}');
    final list = jsonDecode(res.body) as List;
    createdItemId = list.first['item_id'];
    if (createdItemId.isEmpty) throw Exception('No item_id returned');
  });

  // 7. Items API: List Public Items Feed (Excludes Image)
  await runTest('7. Items API: Public Feed (Omits image_path)', () async {
    final res = await http.get(
      Uri.parse(
          '$supabaseUrl/rest/v1/items?item_id=eq.$createdItemId&select=item_id,item_type,location_found,date_found,created_at,status'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $claimantToken',
      },
    );
    if (res.statusCode != 200) throw Exception('${res.statusCode} ${res.body}');
    final list = jsonDecode(res.body) as List;
    if (list.isEmpty) throw Exception('Item not visible in public feed');
    if (list.first.containsKey('image_path')) {
      throw Exception('Security breach: image_path should not be selected in public feed');
    }
  });

  // 8. Claims API: Submit a Claim (Claimant)
  String claimId = '';
  await runTest('8. Claims API: Submit Claim (Claimant)', () async {
    final res = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/claims'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $claimantToken',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      },
      body: jsonEncode({
        'item_id': createdItemId,
        'claimant_contact_id': claimantId,
        'claim_description':
            'Black OnePlus Nord Buds 2 with a scratch on the left stem and blue sticker on case bottom.',
        'status': 'pending',
      }),
    );
    if (res.statusCode != 201) throw Exception('${res.statusCode} ${res.body}');
    final list = jsonDecode(res.body) as List;
    claimId = list.first['claim_id'];
    if (claimId.isEmpty) throw Exception('No claim_id returned');
  });

  // 9. Claims Anti-Duplicate Check: Duplicate Claim Must Fail (Unique Constraint)
  await runTest('9. Claims Anti-Spam Check: Duplicate active claim rejected', () async {
    final res = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/claims'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $claimantToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'item_id': createdItemId,
        'claimant_contact_id': claimantId,
        'claim_description': 'Duplicate attempt to claim same item.',
        'status': 'pending',
      }),
    );
    if (res.statusCode == 201) {
      throw Exception('Duplicate claim was allowed, unique constraint failed!');
    }
  });

  // 10. Privacy Check: Claimant cannot access image before verification
  await runTest('10. Security Check: Claimant blocked from image URL before verification', () async {
    final res = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/rpc/get_claim_image_path'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $claimantToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'p_claim_id': claimId}),
    );
    if (res.statusCode == 200) {
      throw Exception('Security violation: unverified claimant was allowed to fetch private image path!');
    }
  });

  // 11. Finder Reviews Claim: Set status to claim_verified
  await runTest('11. Claims API: Finder Verifies Claim (claim_verified)', () async {
    final res = await http.patch(
      Uri.parse('$supabaseUrl/rest/v1/claims?claim_id=eq.$claimId'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $finderToken',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      },
      body: jsonEncode({'status': 'claim_verified'}),
    );
    if (res.statusCode != 200) throw Exception('${res.statusCode} ${res.body}');
    final list = jsonDecode(res.body) as List;
    if (list.first['status'] != 'claim_verified') {
      throw Exception('Status is not claim_verified: ${list.first['status']}');
    }
  });

  // 12. Security Check: Claimant CAN now access image path after verification
  await runTest('12. Security Check: Verified Claimant gains image path access', () async {
    final res = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/rpc/get_claim_image_path'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $claimantToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'p_claim_id': claimId}),
    );
    if (res.statusCode != 200) throw Exception('${res.statusCode} ${res.body}');
    final data = jsonDecode(res.body);
    if (data['imagePath'] != imagePath) throw Exception('Mismatch in imagePath: ${data['imagePath']}');
  });

  // 13. Storage API: Create Signed URL for image as Claimant
  await runTest('13. Storage API: Generate Signed URL for Revealed Photo', () async {
    final res = await http.post(
      Uri.parse('$supabaseUrl/storage/v1/object/sign/item-images-private/$imagePath'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $claimantToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'expiresIn': 300}),
    );
    if (res.statusCode != 200) throw Exception('${res.statusCode} ${res.body}');
    final data = jsonDecode(res.body);
    final signedUrl = data['signedURL'] ?? data['signedUrl'];
    if (signedUrl == null) throw Exception('No signedURL in response: $data');
  });

  // 14. Contact Exchange RPC: get_mutual_contact
  await runTest('14. Contact Exchange RPC: get_mutual_contact', () async {
    final res = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/rpc/get_mutual_contact'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $claimantToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'p_claim_id': claimId}),
    );
    if (res.statusCode != 200) throw Exception('${res.statusCode} ${res.body}');
    final data = jsonDecode(res.body);
    if (data['finder'] == null || data['claimant'] == null) {
      throw Exception('Missing finder or claimant contact details: $data');
    }
    if (data['finder']['name'] != 'Test Student') {
      throw Exception('Finder name mismatch: ${data['finder']['name']}');
    }
    if (data['claimant']['name'] != 'Sam Claimant') {
      throw Exception('Claimant name mismatch: ${data['claimant']['name']}');
    }
  });

  // 15. Handover Completion RPC: mark_claim_collected
  await runTest('15. Handover Completion RPC: mark_claim_collected', () async {
    final res = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/rpc/mark_claim_collected'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $finderToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'p_claim_id': claimId}),
    );
    if (res.statusCode != 200) throw Exception('${res.statusCode} ${res.body}');
    final data = jsonDecode(res.body);
    if (data['success'] != true || data['status'] != 'returned') {
      throw Exception('Unexpected response from mark_claim_collected: $data');
    }
  });

  // 16. Verify Item and Claim Final State
  await runTest('16. Verify Final Lifecycle State: item=returned, claim=collected', () async {
    final itemRes = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/items?item_id=eq.$createdItemId&select=status'),
      headers: {'apikey': anonKey, 'Authorization': 'Bearer $finderToken'},
    );
    final claimRes = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/claims?claim_id=eq.$claimId&select=status'),
      headers: {'apikey': anonKey, 'Authorization': 'Bearer $finderToken'},
    );

    final itemList = jsonDecode(itemRes.body) as List;
    final claimList = jsonDecode(claimRes.body) as List;

    final item = itemList.first;
    final claim = claimList.first;

    if (item['status'] != 'returned') throw Exception('Item status is not returned: ${item['status']}');
    if (claim['status'] != 'collected') throw Exception('Claim status is not collected: ${claim['status']}');
  });

  print('=== AUDIT COMPLETE: $passed PASSED, $failed FAILED ===');
  if (failed > 0) {
    throw Exception('$failed tests failed!');
  }
}
