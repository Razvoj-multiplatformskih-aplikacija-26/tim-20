import 'package:intl/intl.dart';

final _rsd = NumberFormat.decimalPattern('sr');
final _dateTime = DateFormat('d. M. yyyy. HH:mm');

/// '1.200 RSD'
String formatRsd(int amount) => '${_rsd.format(amount)} RSD';

/// Local time of [utc], for example '4. 11. 2026. 20:00'.
String formatDateTime(DateTime utc) => _dateTime.format(utc.toLocal());
