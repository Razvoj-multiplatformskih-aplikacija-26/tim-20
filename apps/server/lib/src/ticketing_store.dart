import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

/// Rows of the database as domain values. The rules are not here; they stay in the domain.
final class TicketingStore {
  const TicketingStore(this._database);

  final Session _database;

  Future<bool> isEmpty() async {
    final rows = await _database.execute('SELECT count(*) FROM users');
    return rows.single[0] == 0;
  }

  Future<void> insertUser(User user, {String? login, String? passwordHash}) => _database.execute(
    Sql.named('INSERT INTO users (id, name, role, login, password_hash) VALUES (@id, @name, @role, @login, @hash)'),
    parameters: {'id': user.id.value, 'name': user.name, 'role': user.role.name, 'login': login, 'hash': passwordHash},
  );

  Future<User?> user(UserId id) async {
    final rows = await _database.execute(
      Sql.named('SELECT id, name, role FROM users WHERE id = @id'),
      parameters: {'id': id.value},
    );
    if (rows.isEmpty) return null;
    final [userId, name, role] = rows.single;
    return User(id: UserId(userId! as String), name: name! as String, role: Role.values.byName(role! as String));
  }

  Future<void> insertEvent(Event event) => _database.execute(
    Sql.named('''
      INSERT INTO events (id, name, venue, starts_at, price_rsd, capacity, organizer_id)
      VALUES (@id, @name, @venue, @startsAt, @price, @capacity, @organizer)
    '''),
    parameters: {
      'id': event.id.value,
      'name': event.name,
      'venue': event.venue,
      'startsAt': event.startsAt.toUtc(),
      'price': event.priceRsd,
      'capacity': event.capacity,
      'organizer': event.organizerId.value,
    },
  );

  Future<List<Event>> events() => _events('TRUE', const {});

  Future<Event?> event(EventId id) async {
    final found = await _events('id = @id', {'id': id.value});
    return found.isEmpty ? null : found.single;
  }

  /// Locks the row of the event until the transaction ends, so a second reservation for it waits and then sees
  /// the tickets the first one stored.
  Future<Event?> lockEvent(EventId id) async {
    final found = await _events('id = @id', {'id': id.value}, lock: true);
    return found.isEmpty ? null : found.single;
  }

  Future<void> insertTicket(Ticket ticket) {
    final columns = _statusColumns(ticket.status);
    return _database.execute(
      Sql.named('''
        INSERT INTO tickets
          (id, event_id, holder_id, holder_name, status, expires_at, status_at, status_by, cancel_reason, created_at, code)
        VALUES
          (@id, @event, @holder, @holderName, @status, @expiresAt, @statusAt, @statusBy, @reason, @createdAt, @code)
      '''),
      parameters: {
        'id': ticket.id.value,
        'event': ticket.eventId.value,
        'holder': ticket.holderId.value,
        'holderName': ticket.holderName,
        'status': columns.kind,
        'expiresAt': columns.expiresAt,
        'statusAt': columns.at,
        'statusBy': columns.by,
        'reason': columns.reason,
        'createdAt': ticket.createdAt.toUtc(),
        'code': ticket.code,
      },
    );
  }

  /// Stores the new status only if the stored one is still [from]; false when another call changed it first.
  Future<bool> changeStatus(Ticket changed, {required TicketStatus from}) async {
    final columns = _statusColumns(changed.status);
    final result = await _database.execute(
      Sql.named('''
        UPDATE tickets
        SET status = @status, expires_at = @expiresAt, status_at = @statusAt, status_by = @statusBy,
            cancel_reason = @reason
        WHERE id = @id AND status = @previous
      '''),
      parameters: {
        'id': changed.id.value,
        'status': columns.kind,
        'expiresAt': columns.expiresAt,
        'statusAt': columns.at,
        'statusBy': columns.by,
        'reason': columns.reason,
        'previous': _statusColumns(from).kind,
      },
    );
    return result.affectedRows == 1;
  }

  Future<List<Ticket>> ticketsOfEvent(EventId id) => _tickets('event_id = @id', {'id': id.value});

  Future<List<Ticket>> ticketsOf(UserId holder) => _tickets('holder_id = @holder', {'holder': holder.value});

  Future<Ticket?> ticket(TicketId id) async {
    final found = await _tickets('id = @id', {'id': id.value});
    return found.isEmpty ? null : found.single;
  }

  Future<List<Event>> _events(String where, Map<String, Object?> parameters, {bool lock = false}) async {
    final rows = await _database.execute(
      Sql.named('''
        SELECT id, name, venue, starts_at, price_rsd, capacity, organizer_id
        FROM events
        WHERE $where
        ORDER BY starts_at, id
        ${lock ? 'FOR UPDATE' : ''}
      '''),
      parameters: parameters,
    );
    return [
      for (final [id, name, venue, startsAt, price, capacity, organizer] in rows)
        Event(
          id: EventId(id! as String),
          name: name! as String,
          venue: venue! as String,
          startsAt: (startsAt! as DateTime).toUtc(),
          priceRsd: price! as int,
          capacity: capacity! as int,
          organizerId: UserId(organizer! as String),
        ),
    ];
  }

  Future<List<Ticket>> _tickets(String where, Map<String, Object?> parameters) async {
    final rows = await _database.execute(
      Sql.named('''
        SELECT id, event_id, holder_id, holder_name, status, expires_at, status_at, status_by, cancel_reason, created_at, code
        FROM tickets
        WHERE $where
        ORDER BY created_at, id
      '''),
      parameters: parameters,
    );
    return [for (final row in rows) _ticket(row.toColumnMap())];
  }
}

typedef _StatusColumns = ({String kind, DateTime? expiresAt, DateTime? at, String? by, String? reason});

_StatusColumns _statusColumns(TicketStatus status) => switch (status) {
  Reserved(:final expiresAt) => (kind: 'reserved', expiresAt: expiresAt.toUtc(), at: null, by: null, reason: null),
  Paid(:final paidAt, :final confirmedBy) => (
    kind: 'paid',
    expiresAt: null,
    at: paidAt.toUtc(),
    by: confirmedBy?.value,
    reason: null,
  ),
  Used(:final scannedAt, :final scannedBy) => (
    kind: 'used',
    expiresAt: null,
    at: scannedAt.toUtc(),
    by: scannedBy.value,
    reason: null,
  ),
  Cancelled(:final at, :final by, :final reason) => (
    kind: 'cancelled',
    expiresAt: null,
    at: at.toUtc(),
    by: by.value,
    reason: reason,
  ),
  Expired(:final at) => (kind: 'expired', expiresAt: null, at: at.toUtc(), by: null, reason: null),
};

Ticket _ticket(Map<String, dynamic> row) => Ticket(
  id: TicketId(row['id'] as String),
  eventId: EventId(row['event_id'] as String),
  holderId: UserId(row['holder_id'] as String),
  holderName: row['holder_name'] as String,
  status: _status(row),
  createdAt: (row['created_at'] as DateTime).toUtc(),
  code: row['code'] as String,
);

/// The status column is text, so a value the code does not know is a broken row, not a missing case.
TicketStatus _status(Map<String, dynamic> row) {
  DateTime instant(String column) => (row[column] as DateTime).toUtc();
  UserId user(String column) => UserId(row[column] as String);
  return switch (row['status']) {
    'reserved' => Reserved(expiresAt: instant('expires_at')),
    'paid' => Paid(paidAt: instant('status_at'), confirmedBy: row['status_by'] == null ? null : user('status_by')),
    'used' => Used(scannedAt: instant('status_at'), scannedBy: user('status_by')),
    'cancelled' => Cancelled(
      at: instant('status_at'),
      by: user('status_by'),
      reason: row['cancel_reason'] as String? ?? '',
    ),
    'expired' => Expired(at: instant('status_at')),
    final unknown => throw StateError('Unknown ticket status $unknown'),
  };
}
