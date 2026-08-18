import 'package:intl/intl.dart';

abstract class CurrencyFormatter {
  static String format(num amount, {String symbol = '₹'}) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    );
    return formatter.format(amount);
  }
}
