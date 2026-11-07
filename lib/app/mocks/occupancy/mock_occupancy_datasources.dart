import 'dart:async';

import 'package:quadrapp_mobile/app/mocks/mock_errors.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/occupancy/mock_occupancy_json.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_realtime_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/dto/lot_occupancy_dto.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/dto/space_change_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Ocupación desde [MockWorld]. Arma el JSON con el formato de docs/07 y lo
/// lee con el mismo DTO que el datasource HTTP: los mocks respetan el
/// contrato al pie de la letra.
class MockOccupancyRemoteDataSource implements OccupancyRemoteDataSource {
  const MockOccupancyRemoteDataSource(this._world);

  final MockWorld _world;

  @override
  Future<LotOccupancyDto> fetch(LotId lotId) async {
    await _world.gate();
    final lot = _world.lot(lotId.value);
    // Sin distribución publicada no hay datos de ocupación vigentes (US04).
    if (lot == null || !lot.hasLayout) {
      throw mockHttpError(404, title: 'Not Found');
    }
    return LotOccupancyDto.fromJson(mockOccupancyJson(_world, lot));
  }
}

/// Cambios en tiempo real desde el simulador de [MockWorld]. Con
/// `controls.realtimeOutage` el socket se cae (`RealtimeDisconnected`) y deja
/// de entregar cambios hasta que se apaga (`RealtimeConnected`), como una
/// reconexión real.
class MockOccupancyRealtimeDataSource implements OccupancyRealtimeDataSource {
  const MockOccupancyRealtimeDataSource(this._world);

  final MockWorld _world;

  @override
  Stream<OccupancyRealtimeEvent> connect(LotId lotId) {
    final outage = _world.controls.realtimeOutage;
    StreamSubscription<MockSpaceEvent>? subscription;
    late final StreamController<OccupancyRealtimeEvent> controller;
    var down = outage.value;

    void onOutageChanged() {
      if (outage.value == down || controller.isClosed) return;
      down = outage.value;
      controller.add(
        down ? const RealtimeDisconnected() : const RealtimeConnected(),
      );
    }

    controller = StreamController<OccupancyRealtimeEvent>(
      onListen: () {
        controller.add(
          down ? const RealtimeDisconnected() : const RealtimeConnected(),
        );
        outage.addListener(onOutageChanged);
        subscription = _world.events
            .where((event) => event.lotId == lotId.value && !down)
            .listen(
              (event) => controller.add(
                RealtimeChange(SpaceChangeDto.fromJson(event.toJson())),
              ),
            );
      },
      onCancel: () async {
        outage.removeListener(onOutageChanged);
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }
}
