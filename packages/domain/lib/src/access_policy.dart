import 'ticket.dart';
import 'user.dart';

abstract final class AccessPolicy {
  static bool canBuy(User user) => user.role == Role.visitor;

  static bool canView(User user, Ticket ticket) => user.role.isStaff || ticket.holderId == user.id;

  static bool canPay(User user, Ticket ticket) => ticket.holderId == user.id;

  static bool canCancel(User user, Ticket ticket) => ticket.holderId == user.id || user.role == Role.organizer;

  static bool canConfirm(User user) => user.role == Role.organizer;

  static bool canAdmit(User user) => user.role == Role.organizer || user.role == Role.usher;
}
