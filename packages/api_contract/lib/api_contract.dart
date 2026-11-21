/// The shape of requests, answers and errors between the clients and the server.
///
/// It does not know the domain: a change of a rule does not change the shape on the wire.
library;

export 'src/error_codes.dart';
export 'src/event_dto.dart';
export 'src/json.dart';
export 'src/paths.dart';
export 'src/problem_dto.dart';
export 'src/session_dto.dart';
export 'src/ticket_dto.dart';
