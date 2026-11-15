// US19, US29
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/accesses/accesses_overview.dart';
import 'package:quadrapp_mobile/composition/accesses/get_accesses_overview.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Cubit de Accesos vehiculares (`/ops/accesses`).
///
/// Estados (`ViewState<AccessesOverview>`):
/// - `ViewLoading` (con `previous` al recargar);
/// - `ViewError`: no llegaron los accesos (403, 404, sin red...), con
///   `previous` si ya había algo;
/// - `ViewPartial`: el servidor no pudo obtener el flujo (`missing: {flow}`);
/// - `ViewData`: llegó todo (incluido un estacionamiento sin accesos: la
///   pantalla lo dice).
///
/// La antigüedad del dato no vive aquí: la pantalla la recalcula cada segundo.
class AccessesCubit extends Cubit<ViewState<AccessesOverview>> {
  AccessesCubit({
    required this._getAccessesOverview,
    required this._updateLotSettings,
  }) : super(const ViewInitial());

  final GetAccessesOverview _getAccessesOverview;
  final UpdateLotSettings _updateLotSettings;

  LotId? _lotId;

  /// Si cambia el estacionamiento a mitad de una carga, la respuesta vieja se
  /// descarta.
  int _request = 0;

  AccessesOverview? get _current => switch (state) {
    ViewData(:final data) => data,
    ViewPartial(:final data) => data,
    ViewLoading(:final previous) => previous,
    ViewError(:final previous) => previous,
    _ => null,
  };

  /// Carga los accesos de [lotId]. Al cambiar de estacionamiento no se
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

  /// Guarda la configuración propia del estacionamiento actual. Devuelve
  /// `null` si se guardó (y la pantalla ya muestra lo que quedó en el
  /// servidor) o la falla, para que la ventana la diga sin cerrarse.
  Future<Failure?> saveSettings(LotSettings settings) async {
    final lotId = _lotId;
    if (lotId == null) return const UnknownFailure();
    final saved = await _updateLotSettings((lotId: lotId, settings: settings));
    if (isClosed) return null;
    switch (saved) {
      case Err(:final failure):
        return failure;
      case Success(:final value):
        final current = _current;
        if (current != null && current.lotId == lotId) {
          _emitOverview(current.copyWith(settings: value));
        }
        return null;
    }
  }

  Future<void> _fetch(LotId lotId, {AccessesOverview? previous}) async {
    final request = ++_request;
    emit(ViewLoading(previous: previous));
    final result = await _getAccessesOverview(lotId);
    if (isClosed || request != _request) return;
    switch (result) {
      case Err(:final failure):
        emit(ViewError(failure, previous: previous));
      case Success(:final value):
        _emitOverview(value);
    }
  }

  void _emitOverview(AccessesOverview overview) {
    emit(
      overview.flowUnavailable
          ? ViewPartial(overview, missing: const {'flow'})
          : ViewData(overview),
    );
  }
}
