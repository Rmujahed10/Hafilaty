// File: lib/utils/validators.dart

class Validators {
  // Check if a string is exactly 10 digits (for ID, Phone, License)
  static String? validateTenDigitNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName مطلوب'; // Field is required
    }
    
    // Check if it contains only digits (0-9)
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return '$fieldName يجب أن يحتوي على أرقام فقط';
    }
    
    // Check exact length
    if (value.length != 10) {
      return 'يجب أن يكون $fieldName مكوناً من 10 خانات';
    }
    
    return null; // Null means validation passed (Success)
  }

  // Basic Email Check
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    // Simple regex for email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'بريد إلكتروني غير صحيح';
    }
    return null;
  }
}