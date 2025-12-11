import 'package:flutter_test/flutter_test.dart';
import 'package:hafilaty/utils/validators.dart'; 

void main() {
  group('Registration Validation Logic', () {
    
    // --- Test 10-Digit Validation ---
    test('Returns error for 9 digits', () {
      final result = Validators.validateTenDigitNumber('123456789', 'ID');
      expect(result, 'يجب أن يكون ID مكوناً من 10 خانات');
    });

    test('Returns error for 11 digits', () {
      final result = Validators.validateTenDigitNumber('12345678901', 'ID');
      expect(result, 'يجب أن يكون ID مكوناً من 10 خانات');
    });

    test('Returns null (Success) for 10 digits', () {
      final result = Validators.validateTenDigitNumber('1234567890', 'ID');
      expect(result, null);
    });

    test('Returns error for non-numbers', () {
      final result = Validators.validateTenDigitNumber('12345abcde', 'ID');
      expect(result, 'ID يجب أن يحتوي على أرقام فقط');
    });

    // --- Test Email Validation ---
    test('Returns error for bad email', () {
      final result = Validators.validateEmail('bad-email');
      expect(result, 'بريد إلكتروني غير صحيح');
    });

    test('Returns success for good email', () {
      final result = Validators.validateEmail('good@email.com');
      expect(result, null);
    });
  });
}