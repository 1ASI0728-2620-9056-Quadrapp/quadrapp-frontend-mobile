/// Rol del usuario en su institución. Decide la experiencia de la app: `driver`
/// ve la de Conductor; `admin` y `operator` ven la de Operación (el informe los
/// define como un solo segmento: administradores de estacionamientos).
enum UserRole {
  driver,
  operator,
  admin;

  /// ¿Es de la experiencia de Operación? (`admin` y `operator`.)
  bool get isOperations => this == operator || this == admin;
}
