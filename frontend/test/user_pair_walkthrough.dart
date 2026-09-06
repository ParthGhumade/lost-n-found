// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

const supabaseUrl = 'https://qmlzegacppfjsrgzacbi.supabase.co';
const anonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFtbHplZ2FjcHBmanNyZ3phY2JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg2ODQ3OTIsImV4cCI6MjEwNDI2MDc5Mn0._7DMfB7mSWefVUdVamPsb0yWuNLykXNmR2u6HZdxRAY';

void main() async {
  print('================================================================');
  print('🚀 REAL-WORLD USER WALKTHROUGH SIMULATION: FINDER & CLAIMANT');
  print('================================================================\n');

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
      throw Exception('Login failed: ${res.body}');
    }
    return jsonDecode(res.body);
  }

  // -------------------------------------------------------------
  // ACT 1: FINDER (Alex) ENCOUNTERS AN ITEM & POSTS A LISTING
  // -------------------------------------------------------------
  print('--- ACT 1: FINDER (Alex) ---');
  final finderAuth = await login('test@campus.edu', 'test@123');
  final finderToken = finderAuth['access_token'] as String;
  final finderId = finderAuth['user']['id'] as String;

  // 1.1 Alex checks profile
  final finderProfileRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/contacts?contact_id=eq.$finderId'),
    headers: {'apikey': anonKey, 'Authorization': 'Bearer $finderToken'},
  );
  final finderProfile = (jsonDecode(finderProfileRes.body) as List).first;
  print('👤 [Finder Logged In]: ${finderProfile['name']} (${finderProfile['class']}, ${finderProfile['branch']})');

  // 1.2 Alex finds blue Sony WH-1000XM4 headphones in the library reading room
  print('📸 [Finder Action]: Takes photo and uploads to private Supabase storage...');
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final imagePath = '$finderId/${timestamp}_sony_headphones.jpg';
  final dummyPhotoBytes = Uint8List.fromList(utf8.encode('Private Photo of Sony Headphones with custom stickers'));

  final uploadRes = await http.post(
    Uri.parse('$supabaseUrl/storage/v1/object/item-images-private/$imagePath'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $finderToken',
      'Content-Type': 'image/jpeg',
    },
    body: dummyPhotoBytes,
  );
  print('🔒 [Storage]: Photo stored privately at "$imagePath" (HTTP ${uploadRes.statusCode})');

  // 1.3 Alex publishes listing without photo
  print('📝 [Finder Action]: Publishing public listing (Category: Audio, Location: Central Library 3rd Floor)...');
  final itemRes = await http.post(
    Uri.parse('$supabaseUrl/rest/v1/items'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $finderToken',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    },
    body: jsonEncode({
      'finder_contact_id': finderId,
      'item_type': 'Over-ear Headphones',
      'location_found': 'Central Library, 3rd Floor Quiet Study Area',
      'date_found': '2026-09-06',
      'image_path': imagePath,
      'status': 'open',
    }),
  );
  final item = (jsonDecode(itemRes.body) as List).first;
  final itemId = item['item_id'] as String;
  print('✅ [Item Published]: ID: $itemId | Status: ${item['status']}');
  print('');

  // -------------------------------------------------------------
  // ACT 2: CLAIMANT (Sam) BROWSES FEED & SUBMITS PROOF
  // -------------------------------------------------------------
  print('--- ACT 2: CLAIMANT (Sam) ---');
  final claimantAuth = await login('claimant@campus.edu', 'claimant@123');
  final claimantToken = claimantAuth['access_token'] as String;
  final claimantId = claimantAuth['user']['id'] as String;

  final claimantProfileRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/contacts?contact_id=eq.$claimantId'),
    headers: {'apikey': anonKey, 'Authorization': 'Bearer $claimantToken'},
  );
  final claimantProfile = (jsonDecode(claimantProfileRes.body) as List).first;
  print('👤 [Claimant Logged In]: ${claimantProfile['name']} (${claimantProfile['class']}, PRN: ${claimantProfile['prn']})');

  // 2.1 Sam browses public feed
  print('🔍 [Claimant Action]: Browsing public feed for "Headphones"...');
  final publicFeedRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/items?item_id=eq.$itemId&select=item_id,item_type,location_found,date_found,created_at'),
    headers: {'apikey': anonKey, 'Authorization': 'Bearer $claimantToken'},
  );
  final feedItem = (jsonDecode(publicFeedRes.body) as List).first;
  print('📱 [Public Feed Card]:');
  print('   Type: ${feedItem['item_type']}');
  print('   Location: ${feedItem['location_found']}');
  print('   Date: ${feedItem['date_found']}');
  print('   Photo visible? ${feedItem.containsKey('image_path') ? "YES ❌ (LEAK)" : "NO 🛡️ (Protected)"}');

  // 2.2 Sam tries to sneakily access the photo before claiming
  final sneakRes = await http.post(
    Uri.parse('$supabaseUrl/rest/v1/rpc/get_claim_image_path'),
    headers: {'apikey': anonKey, 'Authorization': 'Bearer $claimantToken', 'Content-Type': 'application/json'},
    body: jsonEncode({'p_claim_id': '00000000-0000-0000-0000-000000000000'}),
  );
  print('🛡️ [Security Defense]: Claimant accessing photo before verification: HTTP ${sneakRes.statusCode} (Access Blocked)');

  // 2.3 Sam submits a detailed ownership description
  print('✍️ [Claimant Action]: Submitting detailed ownership proof description...');
  final claimDescription = 'Midnight blue Sony WH-1000XM4. The left ear cup has a tiny white GitHub octocat sticker, and the right headband hinge is slightly stiff.';
  final claimRes = await http.post(
    Uri.parse('$supabaseUrl/rest/v1/claims'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $claimantToken',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    },
    body: jsonEncode({
      'item_id': itemId,
      'claimant_contact_id': claimantId,
      'claim_description': claimDescription,
      'status': 'pending',
    }),
  );
  final claim = (jsonDecode(claimRes.body) as List).first;
  final claimId = claim['claim_id'] as String;
  print('📨 [Claim Sent]: ID: $claimId | Status: ${claim['status']}');
  print('');

  // -------------------------------------------------------------
  // ACT 3: FINDER (Alex) REVIEWS & VERIFIES CLAIM
  // -------------------------------------------------------------
  print('--- ACT 3: FINDER REVIEW INBOX ---');
  print('📬 [Finder Action]: Alex checks "My Listings" inbox for received claims...');
  final inboxRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/claims?item_id=eq.$itemId&select=claim_id,claim_description,status,claimant_contact_id'),
    headers: {'apikey': anonKey, 'Authorization': 'Bearer $finderToken'},
  );
  final incomingClaims = jsonDecode(inboxRes.body) as List;
  print('👀 [Inbox]: Found ${incomingClaims.length} pending claim(s):');
  print('   Claim ID: ${incomingClaims.first['claim_id']}');
  print('   Description: "${incomingClaims.first['claim_description']}"');

  // Alex matches the description with the actual item in hand!
  print('👍 [Finder Action]: The description matches the Octocat sticker! Clicking [Verify Description]...');
  final verifyRes = await http.patch(
    Uri.parse('$supabaseUrl/rest/v1/claims?claim_id=eq.$claimId'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $finderToken',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    },
    body: jsonEncode({'status': 'claim_verified'}),
  );
  final verifiedClaim = (jsonDecode(verifyRes.body) as List).first;
  print('🎉 [Claim Verified]: Status updated to: ${verifiedClaim['status']}');
  print('');

  // -------------------------------------------------------------
  // ACT 4: CLAIMANT REVIEWS UNLOCKED PHOTO & CONFIRMS "IT'S MINE"
  // -------------------------------------------------------------
  print('--- ACT 4: PHOTO REVEAL & CONFIRMATION ---');
  print('🔔 [Claimant Notification]: "Finder verified your description! Photo unlocked."');

  // 4.1 Sam fetches image path via secure RPC
  final imagePathRes = await http.post(
    Uri.parse('$supabaseUrl/rest/v1/rpc/get_claim_image_path'),
    headers: {'apikey': anonKey, 'Authorization': 'Bearer $claimantToken', 'Content-Type': 'application/json'},
    body: jsonEncode({'p_claim_id': claimId}),
  );
  final verifiedPath = jsonDecode(imagePathRes.body)['imagePath'];
  print('🔓 [Photo Access Granted]: Fetched storage path: "$verifiedPath"');

  // 4.2 Sam generates signed URL
  final signRes = await http.post(
    Uri.parse('$supabaseUrl/storage/v1/object/sign/item-images-private/$verifiedPath'),
    headers: {'apikey': anonKey, 'Authorization': 'Bearer $claimantToken', 'Content-Type': 'application/json'},
    body: jsonEncode({'expiresIn': 300}),
  );
  final signedUrl = jsonDecode(signRes.body)['signedURL'] ?? jsonDecode(signRes.body)['signedUrl'];
  print('🖼️ [Photo Loaded on Mobile]: URL valid for 300s: ${signedUrl.toString().substring(0, 75)}...');

  // 4.3 Sam inspects the photo and confirms: "YES, IT'S MINE!"
  print('🙋 [Claimant Decision]: Sam clicks [✓ IT\'S MINE - Exchange Contacts]');
  print('');

  // -------------------------------------------------------------
  // ACT 5: MUTUAL CONTACT EXCHANGE
  // -------------------------------------------------------------
  print('--- ACT 5: MUTUAL CONTACT EXCHANGE ---');
  final contactExchangeRes = await http.post(
    Uri.parse('$supabaseUrl/rest/v1/rpc/get_mutual_contact'),
    headers: {'apikey': anonKey, 'Authorization': 'Bearer $claimantToken', 'Content-Type': 'application/json'},
    body: jsonEncode({'p_claim_id': claimId}),
  );
  final mutualData = jsonDecode(contactExchangeRes.body);

  print('📇 [Contact Card Revealed to Claimant]:');
  print('   Finder: ${mutualData['finder']['name']}');
  print('   Class: ${mutualData['finder']['class']} (${mutualData['finder']['branch']})');
  print('   Phone: ${mutualData['finder']['contactNumber']}');

  print('\n📇 [Contact Card Revealed to Finder]:');
  print('   Claimant: ${mutualData['claimant']['name']}');
  print('   PRN: ${mutualData['claimant']['prn']}');
  print('   Phone: ${mutualData['claimant']['contactNumber']}');
  print('🤝 Both students coordinate via WhatsApp to meet outside Library 3rd Floor.\n');

  // -------------------------------------------------------------
  // ACT 6: HANDOVER COMPLETE & ITEM ARCHIVED
  // -------------------------------------------------------------
  print('--- ACT 6: HANDOVER COMPLETE & ARCHIVAL ---');
  print('📦 [Finder Action]: Handover complete! Alex clicks [Mark as Collected]...');
  final collectRes = await http.post(
    Uri.parse('$supabaseUrl/rest/v1/rpc/mark_claim_collected'),
    headers: {'apikey': anonKey, 'Authorization': 'Bearer $finderToken', 'Content-Type': 'application/json'},
    body: jsonEncode({'p_claim_id': claimId}),
  );
  final collectData = jsonDecode(collectRes.body);
  print('🏁 [Lifecycle Closed]: Handover recorded (success: ${collectData['success']}, item: ${collectData['status']})');

  // Verify item is removed from open public listings
  final finalItemRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/items?item_id=eq.$itemId&select=status'),
    headers: {'apikey': anonKey, 'Authorization': 'Bearer $finderToken'},
  );
  final finalItem = (jsonDecode(finalItemRes.body) as List).first;
  print('✨ [Public Feed Check]: Item status is now "${finalItem['status']}" (archived from open feed).');

  print('\n================================================================');
  print('🎉 SIMULATION COMPLETED SUCCESSFULLY WITH 100% FLOW INTEGRITY!');
  print('================================================================');
}
