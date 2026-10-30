import 'dart:collection';

import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/space_change.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/space_state.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/services/occupancy_counter.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/value_objects/freshness.dart';

/// Aplica cambios en tiempo real sobre una ocupación (US07, TS06, TS09):
/// - descarta un evento con un `eventId` ya aplicado (idempotencia);
/// - descarta un evento anterior al último aplicado a ese espacio o al dato
///   consolidado que ya se tiene (fuera de orden);
/// - descarta un cambio de un espacio que no está en la ocupación.
///
/// Es un objeto con estado: hay uno por estacionamiento observado.
class OccupancyReducer {
  OccupancyReducer(
    LotOccupancy initial, {
    this.maxRememberedEvents = 500,
    this._counter = const OccupancyCounter(),
  }) : _current = initial,
       _baseline = initial.consolidatedAt;

  /// Cuántos `eventId` se recuerdan (los más antiguos se olvidan).
  final int maxRememberedEvents;
  final OccupancyCounter _counter;

  /// Dato consolidado con el que se empezó: todo evento anterior ya está
  /// reflejado en el estado inicial.
  final DateTime _baseline;

  LotOccupancy _current;
  final Queue<String> _seenOrder = Queue<String>();
  final Set<String> _seen = <String>{};
  final Map<int, DateTime> _lastAt = {};

  LotOccupancy get current => _current;

  /// Devuelve la nueva ocupación, o `null` si el evento se descartó.
  /// [receivedAt] es la lectura del reloj monótono al recibirlo.
  LotOccupancy? apply(SpaceChange change, {required Duration receivedAt}) {
    if (_seen.contains(change.eventId)) return null;

    final index = _current.spaces.indexWhere((s) => s.id == change.spaceId);
    if (index < 0) return null;

    final floor = _lastAt[change.spaceId.value] ?? _baseline;
    if (change.at.isBefore(floor)) return null;

    _remember(change.eventId);
    _lastAt[change.spaceId.value] = change.at;

    final spaces = [..._current.spaces];
    spaces[index] = SpaceState(id: change.spaceId, status: change.status);
    final counts = _counter.count(spaces);
    final consolidatedAt = change.at.isAfter(_current.consolidatedAt)
        ? change.at
        : _current.consolidatedAt;

    return _current = _current.copyWith(
      free: counts.free,
      occupied: counts.occupied,
      unknown: counts.unknown,
      spaces: spaces,
      source: OccupancySource.network,
      freshness: Freshness(
        consolidatedAt: consolidatedAt,
        serverTime: consolidatedAt,
        staleAfter: _current.freshness.staleAfter,
        receivedAt: receivedAt,
      ),
    );
  }

  void _remember(String eventId) {
    _seen.add(eventId);
    _seenOrder.add(eventId);
    while (_seenOrder.length > maxRememberedEvents) {
      _seen.remove(_seenOrder.removeFirst());
    }
  }
}
