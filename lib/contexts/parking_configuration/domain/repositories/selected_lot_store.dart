import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// El estacionamiento elegido, que persiste entre aperturas de la app y se
/// borra al cerrar sesión ("reconocer antes que recordar", docs/05).
abstract interface class SelectedLotStore {
  Future<LotId?> read();

  Future<void> save(LotId lotId);

  Future<void> clear();
}
