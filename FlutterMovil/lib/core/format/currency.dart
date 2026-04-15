import 'package:intl/intl.dart';

final _cop = NumberFormat.currency(
  locale: 'es_CO',
  symbol: r'$',
  decimalDigits: 0,
);

String formatCop(num amount) => _cop.format(amount);

