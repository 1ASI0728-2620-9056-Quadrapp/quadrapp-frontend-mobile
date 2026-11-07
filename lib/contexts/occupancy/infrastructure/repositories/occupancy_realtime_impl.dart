import 'dart:async';

import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/occupancy_feed.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/repositories/occupancy_reader.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/repositories/occupancy_realtime.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/services/occupancy_reducer.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_realtime_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/mappers/occupancy_mapper.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Une el estado completo con los cambios en tiempo real:
/// - emite primero el estado completo;
/// - aplica cada cambio con un [OccupancyReducer] (idempotencia por `eventId`
///   y descarte de eventos fuera de orden);
/// - al reconectar vuelve a pedir el estado completo;
/// - avisa el estado real de la conexión ([RealtimeLink]) en [feed].
class OccupancyRealtimeImpl implements OccupancyRealtime {
  const OccupancyRealtimeImpl({
    required this._dataSource,
    required this._reader,
    required this._mapper,
    required this._clock,
  });

  final OccupancyRealtimeDataSource _dataSource;
  final OccupancyReader _reader;
  final OccupancyMapper _mapper;
  final Clock _clock;

  @override
  Stream<Result<LotOccupancy>> watch(LotId lotId) => feed(lotId)
      .where((event) => event is OccupancyReceived)
      .map((event) => (event as OccupancyReceived).result);

  @override
  Stream<OccupancyFeedEvent> feed(LotId lotId) {
    OccupancyReducer? reducer;
    StreamSubscription<OccupancyRealtimeEvent>? subscription;
    var connectedBefore = false;
    var cancelled = false;
    RealtimeLink? link;
    late final StreamController<OccupancyFeedEvent> controller;

    void setLink(RealtimeLink next) {
      if (link == next) return;
      link = next;
      controller.add(LinkChanged(next));
    }

    Future<void> loadSnapshot() async {
      final result = await _reader.read(lotId);
      if (cancelled) return;
      final value = result.valueOrNull;
      if (value != null) reducer = OccupancyReducer(value);
      controller.add(OccupancyReceived(result));
    }

    Future<void> onEvent(OccupancyRealtimeEvent event) async {
      switch (event) {
        case RealtimeConnected():
          setLink(RealtimeLink.live);
          // El primer aviso no repite la consulta si el estado inicial llegó.
          final needsSnapshot = connectedBefore || reducer == null;
          connectedBefore = true;
          if (needsSnapshot) await loadSnapshot();
        case RealtimeChange(:final change):
          final current = reducer;
          if (current == null) return;
          final next = current.apply(
            _mapper.toChange(change),
            receivedAt: _clock.monotonic(),
          );
          if (next != null && !cancelled) {
            controller.add(OccupancyReceived(Success(next)));
          }
        case RealtimeDisconnected():
          setLink(RealtimeLink.reconnecting);
      }
    }

    controller = StreamController<OccupancyFeedEvent>(
      onListen: () {
        setLink(RealtimeLink.connecting);
        unawaited(loadSnapshot());
        subscription = _dataSource
            .connect(lotId)
            .listen(
              (event) => unawaited(onEvent(event)),
            );
      },
      onCancel: () async {
        cancelled = true;
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }
}
