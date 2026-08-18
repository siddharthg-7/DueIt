import 'package:intl/intl.dart';

abstract class DateFormatter {
  static String formatDisplayDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  static String formatIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('d MMM yyyy, h:mm a').format(date);
  }

  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(date);
  }

  static DateTime parseLocalDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return DateTime.now();
    }
  }
}
