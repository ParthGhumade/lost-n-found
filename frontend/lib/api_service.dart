import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'input_sanitizer.dart';
import 'models.dart';
import 'supabase_config.dart';

/// Service class encapsulating all Lost & Found API operations.
/// Implements the contracts specified in docs/apis.md
class ApiService {
  final SupabaseClient _client;

  ApiService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // ==========================================
  // 1. CONTACTS & ONBOARDING APIS
  // ==========================================

  /// 2.1 Get Current User Profile
  Future<ContactProfile?> getCurrentUserProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;

    final data = await _client
        .from(SupabaseConfig.tableContacts)
        .select()
        .eq('contact_id', uid)
        .maybeSingle();

    if (data == null) return null;
    return ContactProfile.fromJson(data);
  }

  /// 2.2 Create / Onboard Contact Profile
  Future<ContactProfile> createContactProfile({
    required String name,
    required String studentClass,
    required String branch,
    required String prn,
    required String contactNumber,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw const AuthException('User is not authenticated');

    final data = await _client
        .from(SupabaseConfig.tableContacts)
        .insert({
          'contact_id': uid,
          'name': name.trim(),
          'class': studentClass.trim(),
          'branch': branch.trim(),
          'prn': prn.trim(),
          'contact_number': contactNumber.trim(),
        })
        .select()
        .single();

    return ContactProfile.fromJson(data);
  }

  /// 2.3 Update Contact Profile
  Future<ContactProfile> updateContactProfile({
    String? name,
    String? studentClass,
    String? branch,
    String? contactNumber,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw const AuthException('User is not authenticated');

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name.trim();
    if (studentClass != null) updates['class'] = studentClass.trim();
    if (branch != null) updates['branch'] = branch.trim();
    if (contactNumber != null) updates['contact_number'] = contactNumber.trim();

    final data = await _client
        .from(SupabaseConfig.tableContacts)
        .update(updates)
        .eq('contact_id', uid)
        .select()
        .single();

    return ContactProfile.fromJson(data);
  }

  // ==========================================
  // 2. ITEMS APIS (PUBLIC FEED & FINDER)
  // ==========================================

  /// 3.1 List Public Lost & Found Items
  /// Note: image_path is strictly excluded for public privacy protection.
  Future<List<LostItem>> listPublicItems({
    String? categoryFilter,
    String? searchQuery,
    int limit = 30,
    int offset = 0,
  }) async {
    var query = _client
        .from(SupabaseConfig.tableItems)
        .select('item_id, item_type, location_found, date_found, created_at, status')
        .eq('status', 'open');

    if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'All') {
      query = query.eq('item_type', categoryFilter);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query = query.or('item_type.ilike.%$searchQuery%,location_found.ilike.%$searchQuery%');
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List).map((e) => LostItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 3.2 Get Single Item Details
  Future<LostItem> getItemDetails(String itemId) async {
    final data = await _client
        .from(SupabaseConfig.tableItems)
        .select()
        .eq('item_id', itemId)
        .single();

    return LostItem.fromJson(data);
  }

  /// 3.3 Create Item Listing (Finder)
  Future<LostItem> createItemListing({
    required String itemType,
    required String locationFound,
    required DateTime dateFound,
    required String imagePath,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw const AuthException('User is not authenticated');

    final data = await _client
        .from(SupabaseConfig.tableItems)
        .insert({
          'finder_contact_id': uid,
          'item_type': itemType.trim(),
          'location_found': locationFound.trim(),
          'date_found': dateFound.toIso8601String().split('T').first,
          'image_path': imagePath,
          'status': 'open',
        })
        .select()
        .single();

    return LostItem.fromJson(data);
  }

  /// 3.4 List My Listings (Finder's Dashboard) with received claims count
  Future<List<LostItem>> listMyListings() async {
    final uid = currentUserId;
    if (uid == null) throw const AuthException('User is not authenticated');

    final data = await _client
        .from(SupabaseConfig.tableItems)
        .select('*, claims(count)')
        .eq('finder_contact_id', uid)
        .order('created_at', ascending: false);

    return (data as List).map((e) => LostItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ==========================================
  // 3. CLAIMS APIS (CLAIMANT & FINDER)
  // ==========================================

  /// 4.1 Submit a Claim (Claimant)
  Future<ItemClaim> submitClaim({
    required String itemId,
    required String description,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw const AuthException('User is not authenticated');

    if (description.trim().length < 10) {
      throw const FormatException('Claim description must be at least 10 characters.');
    }

    final data = await _client
        .from(SupabaseConfig.tableClaims)
        .insert({
          'item_id': itemId,
          'claimant_contact_id': uid,
          'claim_description': description.trim(),
          'status': 'pending',
        })
        .select()
        .single();

    return ItemClaim.fromJson(data);
  }

  /// 4.2 List My Claims (Claimant's Dashboard)
  Future<List<ItemClaim>> listMyClaims() async {
    final uid = currentUserId;
    if (uid == null) throw const AuthException('User is not authenticated');

    final data = await _client
        .from(SupabaseConfig.tableClaims)
        .select('*, items(item_id, item_type, location_found, date_found, status)')
        .eq('claimant_contact_id', uid)
        .order('created_at', ascending: false);

    return (data as List).map((e) => ItemClaim.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 4.3 List Received Claims for an Item (Finder's View)
  Future<List<ItemClaim>> listClaimsForItem(String itemId) async {
    final data = await _client
        .from(SupabaseConfig.tableClaims)
        // Use explicit FK hint to ensure PostgREST resolves the correct
        // relationship between claims.claimant_contact_id -> contacts.contact_id
        .select('*, contacts!claims_claimant_contact_id_fkey(contact_id, name, class, branch)')
        .eq('item_id', itemId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => ItemClaim.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 4.3b Get Single Claim Details (with claimant contacts)
  Future<ItemClaim> getClaim(String claimId) async {
    final data = await _client
        .from(SupabaseConfig.tableClaims)
        .select('*, contacts!claims_claimant_contact_id_fkey(contact_id, name, class, branch)')
        .eq('claim_id', claimId)
        .single();

    return ItemClaim.fromJson(data);
  }

  /// 4.4 Review Claim: Verify or Reject (Finder Action)
  Future<ItemClaim> reviewClaim({
    required String claimId,
    required bool isVerified,
  }) async {
    final targetStatus = isVerified ? 'claim_verified' : 'claim_rejected';

    final data = await _client
        .from(SupabaseConfig.tableClaims)
        .update({
          'status': targetStatus,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('claim_id', claimId)
        .select()
        .single();

    return ItemClaim.fromJson(data);
  }

  /// 4.5 Claimant Decision on Revealed Photo
  Future<ItemClaim> decideClaimPhoto({
    required String claimId,
    required bool isMine,
  }) async {
    if (!isMine) {
      final data = await _client
          .from(SupabaseConfig.tableClaims)
          .update({
            'status': 'closed_by_claimant',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('claim_id', claimId)
          .select()
          .single();
      return ItemClaim.fromJson(data);
    } else {
      // If confirmed "IT'S MINE", fetch current claim representation and set claimant_agreed_photo
      final data = await _client
          .from(SupabaseConfig.tableClaims)
          .update({
            'claimant_agreed_photo': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('claim_id', claimId)
          .select()
          .single();
      return ItemClaim.fromJson(data);
    }
  }

  /// 4.6 Mark Item as Collected (Atomic RPC)
  Future<Map<String, dynamic>> markClaimCollected(String claimId) async {
    final response = await _client.rpc(
      'mark_claim_collected',
      params: {'p_claim_id': claimId},
    );
    return response as Map<String, dynamic>;
  }

  // ==========================================
  // 4. STORAGE & SIGNED PHOTO REVEAL
  // ==========================================

  /// 5.1 Upload Item Image to Private Bucket (Finder)
  /// Sanitizes filename and enforces cryptographic uniqueness to prevent collisions.
  Future<String> uploadItemImage({
    required Uint8List bytes,
    required String fileExtension,
    String? originalFileName,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw const AuthException('User is not authenticated');

    final cleanExt = InputSanitizer.sanitizeFileExtension(fileExtension);
    final path = InputSanitizer.buildUniqueStoragePath(
      userId: uid,
      originalFileName: originalFileName,
      rawExtension: cleanExt,
    );

    await _client.storage.from(SupabaseConfig.storageBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$cleanExt',
            upsert: false,
          ),
        );

    return path;
  }

  /// 5.2 Get Image Signed URL for Revealed Photo
  Future<String> getClaimImageSignedUrl(String claimId, {int expiresInSeconds = 300}) async {
    // 1. Fetch authorized path via RPC
    final rpcResult = await _client.rpc(
      'get_claim_image_path',
      params: {'p_claim_id': claimId},
    );

    final imagePath = (rpcResult as Map)['imagePath'] as String?;
    if (imagePath == null) {
      throw const FormatException('Image path not found in claim.');
    }

    // 2. Generate signed URL for private bucket
    final signedUrl = await _client.storage
        .from(SupabaseConfig.storageBucket)
        .createSignedUrl(imagePath, expiresInSeconds);

    return signedUrl;
  }

  // ==========================================
  // 5. MUTUAL CONTACT EXCHANGE
  // ==========================================

  /// 6.1 Get Mutual Contact Information (RPC)
  Future<MutualContactExchange> getMutualContact(String claimId) async {
    final response = await _client.rpc(
      'get_mutual_contact',
      params: {'p_claim_id': claimId},
    );

    return MutualContactExchange.fromJson(response as Map<String, dynamic>);
  }
}

final apiService = ApiService();
