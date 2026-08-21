import 'package:flutter_test/flutter_test.dart';
import 'package:dueit/features/communication/data/services/whatsapp_service.dart';

void main() {
  group('WhatsAppService Unit Tests', () {
    late WhatsAppService service;

    setUp(() {
      service = WhatsAppService();
    });

    test(
        '1. buildWhatsAppUri generates correct deep link with URL-encoded parameters',
        () {
      final uri = service.buildWhatsAppUri(
        normalizedPhone: '919876543210',
        message: 'Hi Rahul, ₹1,500 is due today!',
      );

      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('wa.me'));
      expect(uri.path, equals('/919876543210'));
      expect(uri.queryParameters['text'],
          equals('Hi Rahul, ₹1,500 is due today!'));
      expect(
          uri.toString(),
          contains(
              'https://wa.me/919876543210?text=Hi%20Rahul%2C%20%E2%82%B91%2C500%20is%20due%20today!'));
    });

    test(
        '2. canLaunchWhatsApp returns false for invalid phone numbers without throwing',
        () async {
      final result = await service.canLaunchWhatsApp(
        rawPhone: 'invalid_number',
        message: 'Hello',
      );
      expect(result, isFalse);
    });

    test(
        '3. launchWhatsApp returns false for invalid phone numbers without crashing',
        () async {
      final result = await service.launchWhatsApp(
        rawPhone: '123',
        message: 'Hello',
      );
      expect(result, isFalse);
    });
  });
}
