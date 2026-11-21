import 'package:use_cases/use_cases.dart';

const serverUnreachableMessage = 'Nema veze sa serverom.';
const sessionExpiredMessage = 'Prijava je istekla. Prijavite se ponovo.';

/// What a screen says when the data did not arrive; the kind of failure comes from the port, never a stack trace.
String failureMessage(Object? cause) => switch (cause) {
  RepositoryException(failure: RepositoryFailure.unreachable) => serverUnreachableMessage,
  RepositoryException(failure: RepositoryFailure.serverError) => 'Greška na serveru.',
  RepositoryException(failure: RepositoryFailure.refused) => 'Server nije prihvatio zahtev.',
  RepositoryException(failure: RepositoryFailure.sessionExpired) => sessionExpiredMessage,
  _ => 'Podaci trenutno nisu dostupni.',
};
