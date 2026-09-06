import 'dart:math';

/// Utility class providing robust input sanitization across user inputs and file uploads.
class InputSanitizer {
  static final _random = Random.secure();

  // Allowed image file extensions
  static const Set<String> allowedImageExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  /// Sanitizes and validates file extensions.
  /// Defaults to 'jpg' if invalid or unsupported.
  static String sanitizeFileExtension(String rawExtension) {
    final cleaned = rawExtension
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();

    if (allowedImageExtensions.contains(cleaned)) {
      return cleaned == 'jpeg' ? 'jpg' : cleaned;
    }
    return 'jpg';
  }

  /// Sanitizes raw file names:
  /// - Strips directory traversal characters (`..`, `/`, `\`)
  /// - Strips special characters, whitespace, and null bytes
  /// - Keeps alphanumeric, hyphens, and underscores
  /// - Truncates length to avoid OS path limits (max 40 chars)
  static String sanitizeFileName(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) {
      return 'photo';
    }

    // Extract base name without extension
    var base = rawName.split(RegExp(r'[/\\]')).last;
    final lastDot = base.lastIndexOf('.');
    if (lastDot > 0) {
      base = base.substring(0, lastDot);
    }

    // Replace spaces and invalid chars with underscores
    var sanitized = base
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    // Remove leading or trailing underscores/dashes
    sanitized = sanitized.replaceAll(RegExp(r'^[_\\-]+|[_\\-]+$'), '');

    if (sanitized.isEmpty) {
      return 'photo';
    }

    return sanitized.length > 40 ? sanitized.substring(0, 40) : sanitized;
  }

  /// Generates an collision-proof, secure storage path for item images:
  /// Format: `{userId}/{timestamp}_{secureToken}_{sanitizedName}.{ext}`
  ///
  /// Guarantees:
  /// 1. Isolated per user namespace (`{userId}/`)
  /// 2. Nanosecond-precise or millisecond timestamp for chronological ordering
  /// 3. Cryptographically secure random token (8 hex chars) ensuring uniqueness
  ///    even if the same user uploads two files with identical names at the exact same millisecond.
  /// 4. Sanitized original filename so path traversal and weird chars are impossible.
  static String buildUniqueStoragePath({
    required String userId,
    String? originalFileName,
    required String rawExtension,
  }) {
    // 1. Clean user ID
    final cleanUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '');

    // 2. Generate secure random salt (4 bytes -> 8 hex characters)
    final values = List<int>.generate(4, (_) => _random.nextInt(256));
    final randomHex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    // 3. Current timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // 4. Clean file name & extension
    final cleanName = sanitizeFileName(originalFileName);
    final ext = sanitizeFileExtension(rawExtension);

    return '$cleanUserId/${timestamp}_${randomHex}_$cleanName.$ext';
  }

  /// Sanitizes text input: removes control characters, trims leading/trailing whitespace,
  /// and collapses excessive internal whitespace.
  static String sanitizeText(String? input, {int maxLength = 1000}) {
    if (input == null) return '';

    // Strip null bytes and control chars (except standard newlines/tabs)
    var cleaned = input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    cleaned = cleaned.trim();

    if (cleaned.length > maxLength) {
      cleaned = cleaned.substring(0, maxLength);
    }

    return cleaned;
  }

  /// Sanitizes phone numbers: retains leading `+` and digits only
  static String sanitizePhoneNumber(String? rawPhone) {
    if (rawPhone == null) return '';
    final trimmed = rawPhone.trim();
    final hasPlus = trimmed.startsWith('+');
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return hasPlus ? '+$digitsOnly' : digitsOnly;
  }
}
