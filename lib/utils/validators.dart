import '../models/item.dart';
import '../models/report.dart';
import '../models/user_profile.dart';

/// Utility class for input validation throughout the app
class Validators {
  // Email validation patterns
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  static final RegExp _iitismEmailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@iitism\.ac\.in$',
    caseSensitive: false,
  );

  // Password validation
  static final RegExp _strongPasswordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  // Name validation (letters, spaces, hyphens, apostrophes only)
  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");

  // Price validation
  static final RegExp _priceRegex = RegExp(r'^\d+(\.\d{1,2})?$');

  // Image file extensions
  static final List<String> _validImageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'
  ];

  /// Email Validation
  static bool isValidEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  static bool isValidIITISMEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    return _iitismEmailRegex.hasMatch(email.trim());
  }

  /// Password Validation
  static bool isValidPassword(String? password) {
    if (password == null || password.isEmpty) return false;
    return password.length >= 6;
  }

  static bool isStrongPassword(String? password) {
    if (password == null || password.isEmpty) return false;
    return password.length >= 8 && _strongPasswordRegex.hasMatch(password);
  }

  /// Item Validation
  static bool isValidItemTitle(String? title) {
    if (title == null || title.trim().isEmpty) return false;
    final trimmed = title.trim();
    return trimmed.length >= 1 && trimmed.length <= 80;
  }

  static bool isValidItemDescription(String? description) {
    if (description == null || description.trim().isEmpty) return false;
    final trimmed = description.trim();
    return trimmed.length >= 1 && trimmed.length <= 600;
  }

  static bool isValidItemPrice(double? price) {
    if (price == null) return false;
    return price > 0;
  }

  static bool isValidPriceString(String? priceStr) {
    if (priceStr == null || priceStr.trim().isEmpty) return false;
    final trimmed = priceStr.trim();
    
    if (!_priceRegex.hasMatch(trimmed)) return false;
    
    final price = double.tryParse(trimmed);
    return price != null && price > 0;
  }

  static bool isValidImageCount(int? count) {
    if (count == null) return false;
    return count >= 1 && count <= 5;
  }

  /// User Profile Validation
  static bool isValidName(String? name) {
    if (name == null || name.trim().isEmpty) return false;
    final trimmed = name.trim();
    return trimmed.length >= 1 && 
           trimmed.length <= 50 && 
           _nameRegex.hasMatch(trimmed);
  }

  static bool isValidDepartment(String? department) {
    if (department == null || department.trim().isEmpty) return false;
    final trimmed = department.trim();
    return trimmed.length >= 1 && trimmed.length <= 100;
  }

  static bool isValidYear(int? year) {
    if (year == null) return false;
    return year >= 1 && year <= 5;
  }

  static bool isValidBio(String? bio) {
    if (bio == null) return true; // Bio is optional
    return bio.length <= 500;
  }

  /// Chat and Message Validation
  static bool isValidMessageText(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final trimmed = text.trim();
    return trimmed.length >= 1 && trimmed.length <= 1000;
  }

  static bool isValidChatParticipants(List<String>? participants) {
    if (participants == null || participants.length != 2) return false;
    return participants[0] != participants[1]; // No duplicates
  }

  /// Report Validation
  static bool isValidReportDescription(String? description) {
    if (description == null || description.trim().isEmpty) return false;
    final trimmed = description.trim();
    return trimmed.length >= 1 && trimmed.length <= 1000;
  }

  static bool isValidReportReason(ReportCategory? reason) {
    return reason != null;
  }

  /// File and Image Validation
  static bool isValidImageExtension(String? filename) {
    if (filename == null || filename.isEmpty) return false;
    final extension = filename.toLowerCase();
    return _validImageExtensions.any((ext) => extension.endsWith(ext));
  }

  static bool isValidFileSize(int? sizeInBytes) {
    if (sizeInBytes == null || sizeInBytes <= 0) return false;
    const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
    return sizeInBytes <= maxSizeInBytes;
  }

  /// Search and Filter Validation
  static bool isValidSearchQuery(String? query) {
    if (query == null || query.trim().isEmpty) return false;
    final trimmed = query.trim();
    return trimmed.length >= 3 && trimmed.length <= 100;
  }

  static bool isValidPriceRange(double? minPrice, double? maxPrice) {
    if (minPrice == null || maxPrice == null) return false;
    return minPrice > 0 && maxPrice > 0 && minPrice <= maxPrice;
  }

  /// Input Sanitization
  static String sanitizeInput(String? input) {
    if (input == null) return '';
    
    // Remove leading/trailing whitespace
    String sanitized = input.trim();
    
    // Replace multiple spaces with single space
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove control characters
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    
    return sanitized;
  }

  /// Comprehensive validation for complex objects
  static List<String> validateItem(Item item) {
    final errors = <String>[];

    if (!isValidItemTitle(item.title)) {
      errors.add('Title must be between 1 and 80 characters');
    }

    if (!isValidItemDescription(item.description)) {
      errors.add('Description must be between 1 and 600 characters');
    }

    if (!isValidItemPrice(item.price)) {
      errors.add('Price must be greater than 0');
    }

    if (!isValidImageCount(item.images.length)) {
      errors.add('Must have between 1 and 5 images');
    }

    if (item.sellerId.isEmpty) {
      errors.add('Seller ID is required');
    }

    return errors;
  }

  static List<String> validateUserProfile(UserProfile profile) {
    final errors = <String>[];

    if (!isValidName(profile.name)) {
      errors.add('Name must be between 1 and 50 characters and contain only letters, spaces, hyphens, and apostrophes');
    }

    if (!isValidIITISMEmail(profile.email)) {
      errors.add('Must use a valid @iitism.ac.in email address');
    }

    if (!isValidDepartment(profile.department)) {
      errors.add('Department must be between 1 and 100 characters');
    }

    if (!isValidYear(profile.year)) {
      errors.add('Year must be between 1 and 5');
    }

    if (!isValidBio(profile.bio)) {
      errors.add('Bio must be 500 characters or less');
    }

    return errors;
  }

  /// Security validation helpers
  static bool containsSqlInjection(String? input) {
    if (input == null) return false;
    
    final sqlPatterns = [
      RegExp(r"('|(\\')|(;)|(\\;)|(--)|(\s*or\s+))", caseSensitive: false),
      RegExp(r"(union\s+select)|(drop\s+table)|(insert\s+into)", caseSensitive: false),
      RegExp(r"(delete\s+from)|(update\s+set)|(create\s+table)", caseSensitive: false),
    ];

    return sqlPatterns.any((pattern) => pattern.hasMatch(input));
  }

  static bool containsXss(String? input) {
    if (input == null) return false;
    
    final xssPatterns = [
      RegExp(r"<script[^>]*>.*?</script>", caseSensitive: false),
      RegExp(r"javascript:", caseSensitive: false),
      RegExp(r"on\w+\s*=", caseSensitive: false),
      RegExp(r"data:\s*text/html", caseSensitive: false),
    ];

    return xssPatterns.any((pattern) => pattern.hasMatch(input));
  }

  /// Batch validation for performance
  static Map<String, bool> validateBatch(Map<String, dynamic> inputs) {
    final results = <String, bool>{};

    inputs.forEach((key, value) {
      switch (key) {
        case 'email':
          results[key] = isValidIITISMEmail(value as String?);
          break;
        case 'title':
          results[key] = isValidItemTitle(value as String?);
          break;
        case 'price':
          results[key] = isValidItemPrice(value as double?);
          break;
        case 'name':
          results[key] = isValidName(value as String?);
          break;
        default:
          results[key] = false;
      }
    });

    return results;
  }
}