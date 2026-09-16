import 'package:flutter_test/flutter_test.dart';
import 'package:sba_gas_scale/core/utils/phone_validator.dart';

void main() {
  group('PhoneValidator', () {
    test('accepts valid E.164 phone numbers with + country code', () {
      expect(PhoneValidator.validate('+2348012345678').isValid, isTrue);
      expect(PhoneValidator.validate('+14155552671').isValid, isTrue);
      expect(PhoneValidator.validate('+447911123456').isValid, isTrue);
    });

    test('rejects numbers missing leading + symbol', () {
      final result = PhoneValidator.validate('08012345678');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains("Missing '+'"));
    });

    test('rejects numbers with non-digit characters', () {
      final result = PhoneValidator.validate('+234-801-ABC');
      expect(result.isValid, isFalse);
    });

    test('rejects numbers that are too short or empty', () {
      expect(PhoneValidator.validate('').isValid, isFalse);
      expect(PhoneValidator.validate('+23').isValid, isFalse);
    });
  });
}
