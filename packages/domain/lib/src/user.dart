import 'package:meta/meta.dart';

import 'identifiers.dart';

enum Role {
  visitor,
  organizer,
  usher;

  bool get isStaff => this != Role.visitor;
}

@immutable
final class User {
  const User({required this.id, required this.name, required this.role});

  final UserId id;
  final String name;
  final Role role;

  @override
  bool operator ==(Object other) => other is User && other.id == id && other.name == name && other.role == role;

  @override
  int get hashCode => Object.hash(id, name, role);

  @override
  String toString() => 'User($name, ${role.name})';
}
