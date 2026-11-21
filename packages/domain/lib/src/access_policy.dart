import 'event.dart';
import 'ticket.dart';
import 'user.dart';

abstract final class AccessPolicy {
  static bool canBuy(User user) => user.role == Role.visitor;

  static bool canView(User user, Ticket ticket) => user.role.isStaff || ticket.holderId == user.id;

  static bool canPay(User user, Ticket ticket) => ticket.holderId == user.id;

  static bool canCancel(User user, Ticket ticket) => ticket.holderId == user.id || user.role == Role.organizer;

  static bool canConfirm(User user) => user.role == Role.organizer;

  static bool canAdmit(User user) => user.role == Role.organizer || user.role == Role.usher;

  static bool canUseMobileApp(User user) => user.role == Role.visitor;

  static bool canUseBackoffice(User user) => user.role.isStaff;

  /// Visitors only see how many seats are left, never the tickets of others.
  static bool canViewEventTickets(User user) => user.role.isStaff;

  /// An organizer works their own events; an usher works the entrance of every event.
  static bool canListEvent(User user, Event event) =>
      user.role == Role.usher || (user.role == Role.organizer && event.organizerId == user.id);
}
