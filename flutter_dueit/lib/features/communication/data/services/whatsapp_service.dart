import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/services/phone_number_normalizer.dart';

/// Service responsible for launching WhatsApp and handling clipboard copying.
class WhatsAppService {
  /// Builds the deep link URL for WhatsApp.
  Uri buildWhatsAppUri({
    required String normalizedPhone,
    required String message,
  }) {
    final encodedMessage = Uri.encodeComponent(message);
    return Uri.parse('https://wa.me/$normalizedPhone?text=$encodedMessage');
  }

  /// Checks if the WhatsApp URL can be launched on this device.
  Future<bool> canLaunchWhatsApp({
    required String rawPhone,
    required String message,
  }) async {
    final normalized = PhoneNumberNormalizer.normalize(rawPhone);
    if (normalized == null) return false;
    final uri = buildWhatsAppUri(normalizedPhone: normalized, message: message);
    try {
      return await canLaunchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  /// Launches the native WhatsApp app with pre-filled message.
  /// Returns true if successfully launched, false if unavailable.
  Future<bool> launchWhatsApp({
    required String rawPhone,
    required String message,
  }) async {
    final normalized = PhoneNumberNormalizer.normalize(rawPhone);
    if (normalized == null) return false;

    final uri = buildWhatsAppUri(normalizedPhone: normalized, message: message);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return launched;
    } catch (_) {
      return false;
    }
  }

  /// Copies the message to the device clipboard.
  Future<void> copyMessageToClipboard(String message) async {
    await Clipboard.setData(ClipboardData(text: message));
  }
}

/// Global provider for WhatsAppService
final whatsAppServiceProvider = Provider<WhatsAppService>((ref) {
  return WhatsAppService();
});
