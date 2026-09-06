// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/supabase_config.dart';

void main() {
  test('Live Signup Auto-Confirm and Auto Sign-in Verification', () async {
    final uniqueId = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'student_$uniqueId@campus.edu';
    const testPassword = 'Password123!';
    final testName = 'AutoConfirm Student $uniqueId';

    print('Testing account registration for: $testEmail');

    // 1. Sign up user via GoTrue API
    final signUpRes = await http.post(
      Uri.parse('${SupabaseConfig.supabaseUrl}/auth/v1/signup'),
      headers: {
        'apikey': SupabaseConfig.supabaseAnonKey,
        'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': testEmail,
        'password': testPassword,
        'data': {
          'name': testName,
          'class': 'SE - Div C',
          'branch': 'Information Technology',
          'contact_number': '+91 9876500000',
        },
      }),
    );

    expect(signUpRes.statusCode, isIn([200, 201]));
    final signUpData = jsonDecode(signUpRes.body) as Map<String, dynamic>;
    final userId = signUpData['id'] ?? signUpData['user']?['id'];
    expect(userId, isNotNull);
    print('User registered successfully in auth.users: ID $userId');

    // 2. Verify immediate sign-in with password without email confirmation barrier
    final loginRes = await http.post(
      Uri.parse('${SupabaseConfig.supabaseUrl}/auth/v1/token?grant_type=password'),
      headers: {
        'apikey': SupabaseConfig.supabaseAnonKey,
        'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': testEmail,
        'password': testPassword,
      }),
    );

    expect(loginRes.statusCode, 200,
        reason: 'Immediate login must succeed with 200 without email confirmation blocker: ${loginRes.body}');
    final loginData = jsonDecode(loginRes.body) as Map<String, dynamic>;
    final accessToken = loginData['access_token'] as String;
    expect(accessToken, isNotEmpty);
    print('Immediate sign-in succeeded! Active session obtained without email confirmation requirement.');

    // 3. Verify contacts profile was automatically created and can be queried with user access token
    final contactRes = await http.get(
      Uri.parse('${SupabaseConfig.supabaseUrl}/rest/v1/contacts?contact_id=eq.$userId'),
      headers: {
        'apikey': SupabaseConfig.supabaseAnonKey,
        'Authorization': 'Bearer $accessToken',
      },
    );

    expect(contactRes.statusCode, 200);
    final contacts = jsonDecode(contactRes.body) as List<dynamic>;
    expect(contacts, isNotEmpty);
    expect(contacts.first['name'], testName);
    print('Contact profile verified in database: ${contacts.first['name']} (${contacts.first['branch']})');
  });
}
