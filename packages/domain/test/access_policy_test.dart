import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  const otherOrganizer = User(id: UserId('u-org-2'), name: 'Drugi organizator', role: Role.organizer);

  group('which app a user may sign in to', () {
    test('only visitors use the mobile app', () {
      expect(AccessPolicy.canUseMobileApp(ana), isTrue);
      expect(AccessPolicy.canUseMobileApp(organizer), isFalse);
      expect(AccessPolicy.canUseMobileApp(usher), isFalse);
    });

    test('only staff use the backoffice', () {
      expect(AccessPolicy.canUseBackoffice(organizer), isTrue);
      expect(AccessPolicy.canUseBackoffice(usher), isTrue);
      expect(AccessPolicy.canUseBackoffice(ana), isFalse);
    });
  });

  test('only staff see every ticket of an event', () {
    expect(AccessPolicy.canViewEventTickets(organizer), isTrue);
    expect(AccessPolicy.canViewEventTickets(usher), isTrue);
    expect(AccessPolicy.canViewEventTickets(ana), isFalse);
  });

  test('an organizer lists their own events and an usher every event', () {
    expect(AccessPolicy.canListEvent(organizer, event()), isTrue);
    expect(AccessPolicy.canListEvent(otherOrganizer, event()), isFalse);
    expect(AccessPolicy.canListEvent(usher, event()), isTrue);
    expect(AccessPolicy.canListEvent(ana, event()), isFalse);
  });
}
