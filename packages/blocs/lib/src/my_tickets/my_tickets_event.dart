part of 'my_tickets_bloc.dart';

sealed class MyTicketsEvent {
  const MyTicketsEvent();
}

final class MyTicketsRequested extends MyTicketsEvent {
  const MyTicketsRequested();
}
