import 'package:quadrapp_mobile/contexts/iam/domain/entities/session.dart';

/// La sesión que persiste en el dispositivo: el usuario con su rol e
/// institución (almacenamiento normal) y el token de refresco (almacén
/// seguro). El token de acceso nunca se guarda aquí.
abstract interface class SessionStore {
  /// La sesión guardada, o `null` si no hay (o si lo guardado está dañado).
  Future<StoredSession?> read();

  Future<void> save(StoredSession session);

  /// Borra el usuario y el token de refresco.
  Future<void> clear();
}
