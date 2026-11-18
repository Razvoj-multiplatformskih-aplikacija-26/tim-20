import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

import 'ticketing_store.dart';

const _ana = User(id: UserId('u-ana'), name: 'Ana Anić', role: Role.visitor);
const _marko = User(id: UserId('u-marko'), name: 'Marko Marković', role: Role.visitor);
const _organizer = User(id: UserId('u-org'), name: 'Jovana Organizator', role: Role.organizer);
const _usher = User(id: UserId('u-usher'), name: 'Petar Redar', role: Role.usher);
const _jelena = User(id: UserId('u-jelena'), name: 'Jelena Nikolić', role: Role.visitor);
const _nikola = User(id: UserId('u-nikola'), name: 'Nikola Đorđević', role: Role.visitor);
const _milica = User(id: UserId('u-milica'), name: 'Milica Stojanović', role: Role.visitor);
const _stefan = User(id: UserId('u-stefan'), name: 'Stefan Ilić', role: Role.visitor);

const _logins = {'u-ana': 'ana', 'u-marko': 'marko', 'u-org': 'organizator', 'u-usher': 'redar'};

/// Fills an empty database with demo data whose times are relative to [now], so the demo works on any day.
Future<void> seedDemoData(Pool<void> database, {required DateTime now, required String? demoPassword}) async {
  if (!await TicketingStore(database).isEmpty()) return;
  await database.runTx((session) => _seed(TicketingStore(session), now: now.toUtc()));
}

Future<void> _seed(TicketingStore store, {required DateTime now}) async {
  for (final user in [_ana, _marko, _organizer, _usher, _jelena, _nikola, _milica, _stefan]) {
    await store.insertUser(user, login: _logins[user.id.value]);
  }

  DateTime day(int days, int hour) => DateTime.utc(now.year, now.month, now.day + days, hour);
  Event event(String id, String name, String venue, DateTime startsAt, {required int price, required int capacity}) =>
      Event(
        id: EventId(id),
        name: name,
        venue: venue,
        startsAt: startsAt,
        priceRsd: price,
        capacity: capacity,
        organizerId: _organizer.id,
      );

  final welcome = event('e-1', 'Žurka dobrodošlice', 'Klub Studentskog grada', day(3, 19), price: 800, capacity: 50);
  final standUp = event(
    'e-2',
    'Stand-up veče',
    'Studentski kulturni centar',
    DateTime.utc(now.year, now.month, now.day, now.hour + 12),
    price: 500,
    capacity: 30,
  );
  final concert = event('e-3', 'Koncert benda Ritam', 'Dom omladine', day(10, 20), price: 1200, capacity: 5);
  final quiz = event('e-4', 'Kviz znanja', 'RAF, sala 1', day(7, 18), price: 300, capacity: 40);
  final freshers = event('e-5', 'Brucoško veče', 'Klub Fest', day(-2, 21), price: 600, capacity: 100);
  for (final event in [welcome, standUp, concert, quiz, freshers]) {
    await store.insertEvent(event);
  }

  final ago = now.subtract;
  final admitted = freshers.startsAt.add(const Duration(minutes: 20));
  Reserved holdsFor(int minutes) => Reserved(expiresAt: now.add(Duration(minutes: minutes)));
  Paid paid(Duration before, {User? confirmedBy}) => Paid(paidAt: ago(before), confirmedBy: confirmedBy?.id);
  Cancelled cancelled(User by, {String reason = ''}) =>
      Cancelled(at: ago(const Duration(hours: 30)), by: by.id, reason: reason);
  Expired expired() => Expired(at: ago(const Duration(days: 1)));

  final tickets = <(String, Event, User, TicketStatus)>[
    ('t-01', welcome, _ana, holdsFor(10)),
    ('t-02', welcome, _ana, paid(const Duration(days: 1))),
    ('t-03', welcome, _marko, paid(const Duration(hours: 20), confirmedBy: _organizer)),
    ('t-04', standUp, _ana, paid(const Duration(days: 2))),
    ('t-05', welcome, _marko, holdsFor(-30)),
    ('t-06', welcome, _jelena, expired()),
    ('t-07', welcome, _nikola, cancelled(_nikola, reason: 'Ne mogu da dođem.')),
    ('t-08', freshers, _milica, Used(scannedAt: admitted, scannedBy: _usher.id)),
    ('t-09', concert, _jelena, paid(const Duration(days: 4))),
    ('t-10', concert, _nikola, paid(const Duration(days: 3))),
    ('t-11', concert, _milica, paid(const Duration(days: 3), confirmedBy: _organizer)),
    ('t-12', concert, _stefan, paid(const Duration(days: 2))),
    ('t-13', freshers, _stefan, Used(scannedAt: admitted, scannedBy: _usher.id)),
    ('t-14', freshers, _ana, Used(scannedAt: admitted, scannedBy: _organizer.id)),
    ('t-15', freshers, _jelena, cancelled(_organizer, reason: 'Duplikat.')),
    ('t-16', freshers, _nikola, expired()),
    ('t-17', standUp, _marko, holdsFor(8)),
    ('t-18', standUp, _milica, paid(const Duration(days: 1))),
    ('t-19', standUp, _stefan, cancelled(_stefan)),
    ('t-20', welcome, _stefan, paid(const Duration(hours: 30))),
    ('t-21', welcome, _milica, holdsFor(5)),
    ('t-22', welcome, _jelena, paid(const Duration(hours: 26), confirmedBy: _organizer)),
    ('t-23', welcome, _nikola, paid(const Duration(hours: 12))),
    ('t-24', welcome, _milica, expired()),
    ('t-25', welcome, _stefan, holdsFor(14)),
    ('t-26', welcome, _jelena, cancelled(_jelena)),
    ('t-27', welcome, _nikola, holdsFor(-5)),
    ('t-28', welcome, _marko, paid(const Duration(hours: 6))),
    ('t-29', welcome, _jelena, paid(const Duration(hours: 3))),
    ('t-30', freshers, _marko, Used(scannedAt: admitted, scannedBy: _usher.id)),
  ];
  for (final (id, event, holder, status) in tickets) {
    await store.insertTicket(
      Ticket(
        id: TicketId(id),
        eventId: event.id,
        holderId: holder.id,
        holderName: holder.name,
        status: status,
        createdAt: _createdBefore(status, now: now),
        code: 'T20-$id',
      ),
    );
  }
}

DateTime _createdBefore(TicketStatus status, {required DateTime now}) => switch (status) {
  Reserved(:final expiresAt) => expiresAt.subtract(reservationHold),
  Paid(:final paidAt) => paidAt.subtract(const Duration(minutes: 10)),
  Used(:final scannedAt) => scannedAt.subtract(const Duration(days: 5)),
  Cancelled(:final at) || Expired(:final at) => at.subtract(const Duration(days: 1)),
};
