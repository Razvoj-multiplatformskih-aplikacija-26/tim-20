part of 'my_tickets_bloc.dart';

sealed class MyTicketsState extends Equatable {
  const MyTicketsState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class MyTicketsLoading extends MyTicketsState {
  const MyTicketsLoading();
}
