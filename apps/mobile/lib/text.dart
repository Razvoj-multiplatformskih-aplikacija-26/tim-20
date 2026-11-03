import 'package:ui/ui.dart';

/// Serbian plural: 1 karta, 2 karte, 5 karata, 21 karta.
String _plural(int count, String one, String few, String many) {
  final last = count % 10;
  final lastTwo = count % 100;
  if (last == 1 && lastTwo != 11) return one;
  if (last >= 2 && last <= 4 && (lastTwo < 12 || lastTwo > 14)) return few;
  return many;
}

String ticketsLabel(int count) => '$count ${_plural(count, 'karta', 'karte', 'karata')}';

String seatsLabel(int count) => '$count ${_plural(count, 'mesto', 'mesta', 'mesta')}';

String remainingLabel(int remaining) => remaining == 0 ? 'Rasprodato' : 'Još ${seatsLabel(remaining)}';

String priceLabel(int priceRsd) => priceRsd == 0 ? 'Besplatno' : formatRsd(priceRsd);
