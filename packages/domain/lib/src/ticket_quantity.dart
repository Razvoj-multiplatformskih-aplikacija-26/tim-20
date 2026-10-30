import 'package:meta/meta.dart';

import 'result.dart';
import 'rules.dart';

@immutable
final class TicketQuantity {
  const TicketQuantity._(this.value);

  static const min = 1;
  static const max = maxTicketsPerEvent;

  final int value;

  /// From [min] to [max] tickets, and together with [alreadyHeld] active tickets at most [maxTicketsPerEvent].
  static Result<TicketQuantity> parse(int requested, {required int alreadyHeld}) {
    // D1
    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) => other is TicketQuantity && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'TicketQuantity($value)';
}
