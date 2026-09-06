// Data Models and Typed Contracts for Campus Lost & Found APIs
// Corresponds to docs/apis.md

enum ClaimStatus {
  pending,
  claimVerified,
  claimRejected,
  closedByClaimant,
  collected;

  static ClaimStatus fromString(String value) {
    switch (value) {
      case 'claim_verified':
        return ClaimStatus.claimVerified;
      case 'claim_rejected':
        return ClaimStatus.claimRejected;
      case 'closed_by_claimant':
        return ClaimStatus.closedByClaimant;
      case 'collected':
        return ClaimStatus.collected;
      case 'pending':
      default:
        return ClaimStatus.pending;
    }
  }

  String toDbString() {
    switch (this) {
      case ClaimStatus.claimVerified:
        return 'claim_verified';
      case ClaimStatus.claimRejected:
        return 'claim_rejected';
      case ClaimStatus.closedByClaimant:
        return 'closed_by_claimant';
      case ClaimStatus.collected:
        return 'collected';
      case ClaimStatus.pending:
        return 'pending';
    }
  }

  String get displayLabel {
    switch (this) {
      case ClaimStatus.pending:
        return 'Under Review';
      case ClaimStatus.claimVerified:
        return 'Verified (Photo Ready)';
      case ClaimStatus.claimRejected:
        return 'Claim Rejected';
      case ClaimStatus.closedByClaimant:
        return 'Closed by You';
      case ClaimStatus.collected:
        return 'Item Returned';
    }
  }
}

enum ItemStatus {
  open,
  returned;

  static ItemStatus fromString(String value) {
    return value == 'returned' ? ItemStatus.returned : ItemStatus.open;
  }

  String toDbString() => this == ItemStatus.returned ? 'returned' : 'open';
}

/// 1. Student / Contact Profile Contract
class ContactProfile {
  final String contactId;
  final String name;
  final String studentClass;
  final String branch;
  final String contactNumber;
  final DateTime? createdAt;

  const ContactProfile({
    required this.contactId,
    required this.name,
    required this.studentClass,
    required this.branch,
    required this.contactNumber,
    this.createdAt,
  });

  factory ContactProfile.fromJson(Map<String, dynamic> json) {
    return ContactProfile(
      contactId: json['contact_id'] as String? ?? json['contactId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      studentClass: json['class'] as String? ?? json['studentClass'] as String? ?? '',
      branch: json['branch'] as String? ?? '',
      contactNumber: json['contact_number'] as String? ?? json['contactNumber'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contact_id': contactId,
      'name': name,
      'class': studentClass,
      'branch': branch,
      'contact_number': contactNumber,
    };
  }
}

/// 2. Lost & Found Item Listing Contract
class LostItem {
  final String itemId;
  final String? finderContactId;
  final String itemType;
  final String locationFound;
  final DateTime dateFound;
  final String? imagePath;
  final ItemStatus status;
  final DateTime createdAt;
  final int? claimsCount;

  const LostItem({
    required this.itemId,
    this.finderContactId,
    required this.itemType,
    required this.locationFound,
    required this.dateFound,
    this.imagePath,
    required this.status,
    required this.createdAt,
    this.claimsCount,
  });

  factory LostItem.fromJson(Map<String, dynamic> json) {
    int? count;
    if (json['claims'] is List && (json['claims'] as List).isNotEmpty) {
      final first = (json['claims'] as List).first;
      if (first is Map && first.containsKey('count')) {
        count = first['count'] as int?;
      }
    }

    return LostItem(
      itemId: json['item_id'] as String? ?? json['itemId'] as String? ?? '',
      finderContactId: json['finder_contact_id'] as String? ?? json['finderContactId'] as String?,
      itemType: json['item_type'] as String? ?? json['itemType'] as String? ?? 'General Item',
      locationFound: json['location_found'] as String? ?? json['locationFound'] as String? ?? '',
      dateFound: json['date_found'] != null
          ? DateTime.tryParse(json['date_found'] as String) ?? DateTime.now()
          : DateTime.now(),
      imagePath: json['image_path'] as String? ?? json['imagePath'] as String?,
      status: ItemStatus.fromString(json['status'] as String? ?? 'open'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      claimsCount: count,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      if (finderContactId != null) 'finder_contact_id': finderContactId,
      'item_type': itemType,
      'location_found': locationFound,
      'date_found': dateFound.toIso8601String().split('T').first,
      if (imagePath != null) 'image_path': imagePath,
      'status': status.toDbString(),
    };
  }
}

/// 3. Claim Contract
class ItemClaim {
  final String claimId;
  final String itemId;
  final String claimantContactId;
  final String claimDescription;
  final ClaimStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool claimantAgreedPhoto;
  final LostItem? item;
  final ContactProfile? claimant;

  const ItemClaim({
    required this.claimId,
    required this.itemId,
    required this.claimantContactId,
    required this.claimDescription,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.claimantAgreedPhoto = false,
    this.item,
    this.claimant,
  });

  factory ItemClaim.fromJson(Map<String, dynamic> json) {
    return ItemClaim(
      claimId: json['claim_id'] as String? ?? json['claimId'] as String? ?? '',
      itemId: json['item_id'] as String? ?? json['itemId'] as String? ?? '',
      claimantContactId: json['claimant_contact_id'] as String? ?? json['claimantContactId'] as String? ?? '',
      claimDescription: json['claim_description'] as String? ?? json['claimDescription'] as String? ?? '',
      status: ClaimStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      claimantAgreedPhoto: json['claimant_agreed_photo'] as bool? ?? false,
      item: json['items'] is Map<String, dynamic>
          ? LostItem.fromJson(json['items'] as Map<String, dynamic>)
          : null,
      claimant: json['contacts'] is Map<String, dynamic>
          ? ContactProfile.fromJson(json['contacts'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'claim_id': claimId,
      'item_id': itemId,
      'claimant_contact_id': claimantContactId,
      'claim_description': claimDescription,
      'status': status.toDbString(),
      'claimant_agreed_photo': claimantAgreedPhoto,
    };
  }
}

/// 4. Mutual Contact Exchange Contract
class MutualContactExchange {
  final String claimId;
  final ClaimStatus status;
  final ContactProfile finder;
  final ContactProfile claimant;

  const MutualContactExchange({
    required this.claimId,
    required this.status,
    required this.finder,
    required this.claimant,
  });

  factory MutualContactExchange.fromJson(Map<String, dynamic> json) {
    return MutualContactExchange(
      claimId: json['claimId'] as String? ?? json['claim_id'] as String? ?? '',
      status: ClaimStatus.fromString(json['status'] as String? ?? 'claim_verified'),
      finder: ContactProfile.fromJson(json['finder'] as Map<String, dynamic>? ?? {}),
      claimant: ContactProfile.fromJson(json['claimant'] as Map<String, dynamic>? ?? {}),
    );
  }
}
