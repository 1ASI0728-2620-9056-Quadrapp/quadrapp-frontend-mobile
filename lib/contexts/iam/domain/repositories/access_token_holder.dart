import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/access_token.dart';

/// El token de acceso, **solo en memoria**: nunca se escribe en disco. Al
/// cerrar la app desaparece y se renueva con el token de refresco.
abstract interface class AccessTokenHolder {
  /// El token actual, o `null` si no hay (se lee de forma síncrona en cada
  /// petición).
  AccessToken? get current;

  /// Guarda el token de acceso nuevo (reemplaza al anterior).
  void replace(AccessToken token);

  void clear();
}
