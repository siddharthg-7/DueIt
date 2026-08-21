import 'package:flutter_test/flutter_test.dart';
import 'package:dueit/features/communication/domain/services/phone_number_normalizer.dart';

void main() {
  group('PhoneNumberNormalizer Unit Tests', () {
    test('1. Standard 10-digit Indian number normalizes with 91 prefix', () {
      expect(PhoneNumberNormalizer.normalize('9876543210'),
          equals('919876543210'));
      expect(PhoneNumberNormalizer.normalize('8765432109'),
          equals('918765432109'));
      expect(PhoneNumberNormalizer.normalize('7654321098'),
          equals('917654321098'));
      expect(PhoneNumberNormalizer.normalize('6543210987'),
          equals('916543210987'));
    });

    test('2. 11-digit number with leading zero normalizes with 91 prefix', () {
      expect(PhoneNumberNormalizer.normalize('09876543210'),
          equals('919876543210'));
    });

    test('3. 12-digit number with existing 91 prefix is preserved', () {
      expect(PhoneNumberNormalizer.normalize('919876543210'),
          equals('919876543210'));
    });

    test('4. Number with +91 prefix normalizes without plus sign', () {
      expect(PhoneNumberNormalizer.normalize('+919876543210'),
          equals('919876543210'));
      expect(PhoneNumberNormalizer.normalize('+91 98765 43210'),
          equals('919876543210'));
    });

    test(
        '5. Number with spaces, dashes, and parentheses is sanitized correctly',
        () {
      expect(PhoneNumberNormalizer.normalize('(987) 654-3210'),
          equals('919876543210'));
      expect(PhoneNumberNormalizer.normalize('+91-98765-43210'),
          equals('919876543210'));
      expect(PhoneNumberNormalizer.normalize('98765 43210'),
          equals('919876543210'));
    });

    test('6. Invalid phone numbers return null', () {
      expect(PhoneNumberNormalizer.normalize('12345'), isNull); // Too short
      expect(PhoneNumberNormalizer.normalize('abcdefghij'), isNull); // Letters
      expect(PhoneNumberNormalizer.normalize('0123456789'),
          isNull); // Leading 0 with invalid Indian start
      expect(PhoneNumberNormalizer.normalize(''), isNull);
      expect(PhoneNumberNormalizer.normalize(null), isNull);
    });

    test('7. isValid helper accurately validates phone numbers', () {
      expect(PhoneNumberNormalizer.isValid('9876543210'), isTrue);
      expect(PhoneNumberNormalizer.isValid('+919876543210'), isTrue);
      expect(PhoneNumberNormalizer.isValid('1234'), isFalse);
      expect(PhoneNumberNormalizer.isValid(''), isFalse);
      expect(PhoneNumberNormalizer.isValid(null), isFalse);
    });

    test('8. formatDisplay formats Indian phone numbers cleanly for UI', () {
      expect(
        PhoneNumberNormalizer.formatDisplay('9876543210'),
        equals('+91 98765 43210'),
      );
      expect(
        PhoneNumberNormalizer.formatDisplay('+919876543210'),
        equals('+91 98765 43210'),
      );
    });
  });
}
