// US20, TS10
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Cubit de Dispositivos (`/ops/more/devices`): la salud del inventario del
/// estacionamiento elegido, en modo lectura, y el reporte de problemas.
///
/// Estados (`ViewState<DeviceInventory>`):
/// - `ViewLoading` (con `previous` al recargar);
/// - `ViewError` (403, sin red...), con `previous` si ya había algo;
/// - `ViewEmpty`: el estacionamiento no tiene dispositivos;
/// - `ViewData`: el inventario.
class DevicesCubit extends Cubit<ViewState<DeviceInventory>> {
  DevicesCubit({
    required this._getDeviceInventory,
    required this._reportDeviceProblem,
  }) : super(const ViewInitial());

  final GetDeviceInventory _getDeviceInventory;
  final ReportDeviceProblem _reportDeviceProblem;

  LotId? _lotId;
  int _request = 0;

  DeviceInventory? get _current => switch (state) {
    ViewData(:final data) => data,
    ViewLoading(:final previous) => previous,
    ViewError(:final previous) => previous,
    _ => null,
  };

  /// Carga [lotId]; otro estacionamiento no conserva lo anterior.
  Future<void> load(LotId lotId) {
    final sameLot = _lotId == lotId;
    _lotId = lotId;
    return _fetch(lotId, previous: sameLot ? _current : null);
  }

  Future<void> refresh() async {
    final lotId = _lotId;
    if (lotId == null) return;
    await _fetch(lotId, previous: _current);
  }

  /// Reporta un problema del estacionamiento actual a soporte.
  Future<Result<ProblemReceipt>> report({
    required ProblemCategory category,
    DeviceId? deviceId,
    String? detail,
  }) async {
    final lotId = _lotId;
    if (lotId == null) return const Err(UnknownFailure());
    final report = ProblemReport.create(
      lotId: lotId,
      category: category,
      deviceId: deviceId,
      detail: detail,
    );
    return switch (report) {
      Err(:final failure) => Err(failure),
      Success(:final value) => _reportDeviceProblem(value),
    };
  }

  Future<void> _fetch(LotId lotId, {DeviceInventory? previous}) async {
    final request = ++_request;
    emit(ViewLoading(previous: previous));
    final result = await _getDeviceInventory(lotId);
    if (isClosed || request != _request) return;
    switch (result) {
      case Err(:final failure):
        emit(ViewError(failure, previous: previous));
      case Success(:final value):
        emit(value.devices.isEmpty ? const ViewEmpty() : ViewData(value));
    }
  }
}
