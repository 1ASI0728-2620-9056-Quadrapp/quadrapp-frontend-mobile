// US29, TS17, US20
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/shift/get_shift_overview.dart';
import 'package:quadrapp_mobile/composition/shift/shift_console.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Cubit de la consola de turno (`/ops/shift`): el estado de operación del
/// estacionamiento elegido y la salud de sus dispositivos, pedidos a la vez.
///
/// Estados (`ViewState<ShiftConsole>`):
/// - `ViewLoading` (con `previous` al recargar);
/// - `ViewError`: no llegó el estado de operación (403, 404 sin distribución
///   publicada, sin red...), con `previous` si ya había algo;
/// - `ViewPartial`: falta el pronóstico, el flujo o los dispositivos
///   (`missing`: `saturation`, `flow`, `devices`);
/// - `ViewData`: llegó todo.
///
/// La antigüedad del dato no vive aquí: la pantalla la recalcula cada segundo
/// con `Freshness`.
class ShiftCubit extends Cubit<ViewState<ShiftConsole>> {
  ShiftCubit({
    required this._getShiftOverview,
    required this._getDeviceInventory,
  }) : super(const ViewInitial());

  final GetShiftOverview _getShiftOverview;
  final GetDeviceInventory _getDeviceInventory;

  LotId? _lotId;

  /// Cada carga lleva un número: si cambia el estacionamiento a mitad de una,
  /// la respuesta vieja se descarta.
  int _request = 0;

  ShiftConsole? get _current => switch (state) {
    ViewData(:final data) => data,
    ViewPartial(:final data) => data,
    ViewLoading(:final previous) => previous,
    ViewError(:final previous) => previous,
    _ => null,
  };

  /// Carga la consola de [lotId]. Al cambiar de estacionamiento no se
  /// conserva lo anterior (sería de otro lugar).
  Future<void> load(LotId lotId) {
    final sameLot = _lotId == lotId;
    _lotId = lotId;
    return _fetch(lotId, previous: sameLot ? _current : null);
  }

  /// Vuelve a leer el estacionamiento actual, mostrando lo que ya hay.
  Future<void> refresh() async {
    final lotId = _lotId;
    if (lotId == null) return;
    await _fetch(lotId, previous: _current);
  }

  Future<void> _fetch(LotId lotId, {ShiftConsole? previous}) async {
    final request = ++_request;
    emit(ViewLoading(previous: previous));
    final (overview, devices) = await (
      _getShiftOverview(lotId),
      _getDeviceInventory(lotId),
    ).wait;
    if (isClosed || request != _request) return;
    switch (overview) {
      case Err(:final failure):
        emit(ViewError(failure, previous: previous));
      case Success(:final value):
        final console = ShiftConsole(
          overview: value,
          devices: devices.valueOrNull,
        );
        if (!console.isPartial) {
          emit(ViewData(console));
          return;
        }
        emit(
          ViewPartial(
            console,
            missing: {
              for (final section in value.unavailable) section.name,
              if (console.devicesUnavailable) 'devices',
            },
          ),
        );
    }
  }
}
