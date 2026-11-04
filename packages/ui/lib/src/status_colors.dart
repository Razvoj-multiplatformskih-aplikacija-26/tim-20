import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// A background and a foreground color for every ticket status, one set per brightness.
@immutable
class TicketStatusColors extends ThemeExtension<TicketStatusColors> {
  const TicketStatusColors({
    required this.reserved,
    required this.onReserved,
    required this.paid,
    required this.onPaid,
    required this.used,
    required this.onUsed,
    required this.cancelled,
    required this.onCancelled,
    required this.expired,
    required this.onExpired,
  });

  static const light = TicketStatusColors(
    reserved: Color(0xFFFFE4B8),
    onReserved: Color(0xFF5C3B00),
    paid: Color(0xFFC9F2D2),
    onPaid: Color(0xFF0B4D22),
    used: Color(0xFFD9D4FF),
    onUsed: Color(0xFF2A1A80),
    cancelled: Color(0xFFFFD6D3),
    onCancelled: Color(0xFF7A1C15),
    expired: Color(0xFFE4E2E8),
    onExpired: Color(0xFF4A4753),
  );

  static const dark = TicketStatusColors(
    reserved: Color(0xFF5C3B00),
    onReserved: Color(0xFFFFE4B8),
    paid: Color(0xFF0B4D22),
    onPaid: Color(0xFFC9F2D2),
    used: Color(0xFF2A1A80),
    onUsed: Color(0xFFD9D4FF),
    cancelled: Color(0xFF7A1C15),
    onCancelled: Color(0xFFFFD6D3),
    expired: Color(0xFF3B3845),
    onExpired: Color(0xFFCAC7D2),
  );

  final Color reserved;
  final Color onReserved;
  final Color paid;
  final Color onPaid;
  final Color used;
  final Color onUsed;
  final Color cancelled;
  final Color onCancelled;
  final Color expired;
  final Color onExpired;

  /// (background, foreground) of [status].
  (Color, Color) of(TicketStatus status) => switch (status) {
    Reserved() => (reserved, onReserved),
    Paid() => (paid, onPaid),
    Used() => (used, onUsed),
    Cancelled() => (cancelled, onCancelled),
    Expired() => (expired, onExpired),
  };

  @override
  TicketStatusColors copyWith({
    Color? reserved,
    Color? onReserved,
    Color? paid,
    Color? onPaid,
    Color? used,
    Color? onUsed,
    Color? cancelled,
    Color? onCancelled,
    Color? expired,
    Color? onExpired,
  }) {
    return TicketStatusColors(
      reserved: reserved ?? this.reserved,
      onReserved: onReserved ?? this.onReserved,
      paid: paid ?? this.paid,
      onPaid: onPaid ?? this.onPaid,
      used: used ?? this.used,
      onUsed: onUsed ?? this.onUsed,
      cancelled: cancelled ?? this.cancelled,
      onCancelled: onCancelled ?? this.onCancelled,
      expired: expired ?? this.expired,
      onExpired: onExpired ?? this.onExpired,
    );
  }

  @override
  TicketStatusColors lerp(TicketStatusColors? other, double t) {
    if (other == null) return this;
    return TicketStatusColors(
      reserved: Color.lerp(reserved, other.reserved, t)!,
      onReserved: Color.lerp(onReserved, other.onReserved, t)!,
      paid: Color.lerp(paid, other.paid, t)!,
      onPaid: Color.lerp(onPaid, other.onPaid, t)!,
      used: Color.lerp(used, other.used, t)!,
      onUsed: Color.lerp(onUsed, other.onUsed, t)!,
      cancelled: Color.lerp(cancelled, other.cancelled, t)!,
      onCancelled: Color.lerp(onCancelled, other.onCancelled, t)!,
      expired: Color.lerp(expired, other.expired, t)!,
      onExpired: Color.lerp(onExpired, other.onExpired, t)!,
    );
  }
}

extension TicketStatusColorsX on ThemeData {
  TicketStatusColors get statusColors => extension<TicketStatusColors>() ?? TicketStatusColors.light;
}
