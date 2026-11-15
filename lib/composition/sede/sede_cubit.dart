// US04 (la sede que ve el conductor)
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// La sede que ve el conductor, compartida por Inicio, Zonas y Predicción: el
/// shell lo crea una vez y cada pestaña lo lee.
///
/// Estados (`ViewState<SedeSelection>`): `ViewLoading` (con `previous` al
/// recargar), `ViewEmpty` (la institución no tiene sedes), `ViewError` y
/// `ViewData` (las sedes y la elegida, que puede faltar).
///
/// - La elegida se recuerda en el dispositivo (docs/05, regla 7) y se borra al
///   cerrar sesión. Si ya no existe, se trata como sin elegir.
/// - Con **una sola** sede, se elige sola.
/// - Elegir es de mejor esfuerzo: si no se puede guardar, la sede igual queda
///   elegida mientras la app esté abierta.
class SedeCubit extends Cubit<ViewState<SedeSelection>> {
  SedeCubit({
    required this._listParkingLots,
    required this._getSelectedLot,
    required this._selectLot,
  }) : super(const ViewInitial());

  final ListParkingLots _listParkingLots;
  final GetSelectedLot _getSelectedLot;
  final SelectLot _selectLot;

  SedeSelection? get _current => switch (state) {
    ViewData(:final data) => data,
    ViewLoading(:final previous) => previous,
    ViewError(:final previous) => previous,
    _ => null,
  };

  Future<void> load() async {
    emit(ViewLoading(previous: _current));
    final listed = await _listParkingLots(const NoParams());
    switch (listed) {
      case Err(:final failure):
        emit(ViewError(failure, previous: _current));
      case Success(:final value) when value.isEmpty:
        emit(const ViewEmpty());
      case Success(:final value):
        final savedId = (await _getSelectedLot(const NoParams())).valueOrNull;
        var selected = value.where((lot) => lot.id == savedId).firstOrNull;
        if (selected == null && value.length == 1) {
          selected = value.single;
          await _selectLot(selected.id);
        }
        if (isClosed) return;
        emit(ViewData(SedeSelection(lots: value, selected: selected)));
    }
  }

  /// Elige [lotId] como la sede del conductor. Una que no existe se ignora.
  Future<void> select(LotId lotId) async {
    final current = _current;
    final lot = current?.lots.where((l) => l.id == lotId).firstOrNull;
    if (current == null || lot == null) return;
    if (current.selected?.id == lotId) return;
    await _selectLot(lotId);
    if (isClosed) return;
    emit(ViewData(SedeSelection(lots: current.lots, selected: lot)));
  }
}
