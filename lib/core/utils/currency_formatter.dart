import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _smallAmountFormatter = NumberFormat.currency(
    locale: 'en_KE',
    symbol: 'KES ',
    decimalDigits: 2,
  );

  static final NumberFormat _largeAmountFormatter = NumberFormat.currency(
    locale: 'en_KE',
    symbol: 'KES ',
    decimalDigits: 0,
  );

  static String format(num amount) {
    if (amount.abs() < 1000) {
      return _smallAmountFormatter.format(amount);
    }

    return _largeAmountFormatter.format(amount);
  }
}
