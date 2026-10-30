/// A visitor holds at most this many active tickets for one event.
const maxTicketsPerEvent = 4;

/// A visitor cancels at the latest this long before the event starts.
const cancellationNotice = Duration(hours: 24);

/// A reservation that is not paid within this time expires.
const reservationHold = Duration(minutes: 15);
