part of 'event_tickets_bloc.dart';

sealed class EventTicketsState extends Equatable {
  const EventTicketsState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class EventTicketsLoading extends EventTicketsState {
  const EventTicketsLoading();
}
