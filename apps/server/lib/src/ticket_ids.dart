import 'dart:math';

import 'package:domain/domain.dart';

final _random = Random.secure();

/// Ids are made by the server; an id the client sent is never stored.
TicketId newTicketId() =>
    TicketId('t-${[for (var i = 0; i < 6; i++) _random.nextInt(256).toRadixString(16).padLeft(2, '0')].join()}');
