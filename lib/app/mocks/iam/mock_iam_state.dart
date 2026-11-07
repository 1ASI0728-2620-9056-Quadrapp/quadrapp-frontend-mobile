import 'package:quadrapp_mobile/app/mocks/mock_seed.dart';

/// Estado de autenticación del "servidor": códigos emitidos, usuarios y
/// sesiones vigentes. Vive en `MockWorld`.
///
/// La institución, los usuarios de prueba y el código OTP salen de la semilla
/// (`assets/mocks/seed.json`, docs/07): "Universidad de prueba" con dominio
/// `upc.edu.pe`, `conductor@upc.edu.pe` (DRIVER, el segmento de esta app) y
/// `administrador@upc.edu.pe` (ADMIN, para comprobar que la app acepta
/// cualquier rol), ambos con el código `123456`.
class MockIamState {
  MockIamState(MockSeed seed)
    : institutionId = seed.institutionId,
      institutionName = seed.institutionName,
      domain = seed.domain,
      validCode = seed.otpCode,
      _users = {for (final user in seed.users) user.email: user};

  /// El rol con el que se emitió cada token (así el servidor de prueba puede
  /// responder 403 a un conductor en las rutas de consola, TS17 esc. 2).
  final Map<String, String> _accessRoles = {};
  final Map<String, String> _refreshRoles = {};

  final int institutionId;
  final String institutionName;
  final String domain;

  /// El código que acepta el servidor de prueba.
  final String validCode;

  /// Vigencia del código, desde que se pide.
  static const Duration otpValidity = Duration(minutes: 5);

  /// Intentos fallidos tras los cuales el código deja de servir (TS01 esc. 4).
  static const int maxAttempts = 5;

  /// Cuánto debe esperar para pedir otro código tras un 429.
  static const int retryAfterSec = 45;

  final Map<String, MockSeedUser> _users;

  /// Cuándo se emitió el código vigente de cada correo.
  final Map<String, DateTime> otpIssuedAt = {};
  final Map<String, int> failedAttempts = {};

  /// Los refresh tokens vigentes (no se rotan).
  final Set<String> refreshTokens = {};

  /// Los access tokens emitidos (solo sirven para comprobar en las pruebas que
  /// la app usó el correcto).
  final List<String> issuedAccessTokens = [];

  int _tokenCounter = 0;

  /// El id de usuario de cada correo: los de prueba tienen id fijo.
  int userIdFor(String email) =>
      _users[email]?.id ?? 100 + email.hashCode.abs() % 900;

  /// El nombre completo del usuario de prueba (`null` si no tiene).
  String? fullNameFor(String email) => _users[email]?.fullName;

  /// El rol con el que se emitió [token], o `null` si no se conoce.
  String? roleForAccessToken(String? token) => _accessRoles[token];

  /// El rol de la sesión de ese refresh token, o `null` si no se conoce.
  String? roleForRefreshToken(String token) => _refreshRoles[token];

  /// El rol del usuario de prueba; `DRIVER` para cualquier otro correo de la
  /// institución.
  String roleFor(String email) => _users[email]?.role ?? 'DRIVER';

  String newAccessToken({String role = 'DRIVER'}) {
    final token = 'mock-access-${++_tokenCounter}';
    issuedAccessTokens.add(token);
    _accessRoles[token] = role;
    return token;
  }

  String newRefreshToken({String role = 'DRIVER'}) {
    final token = 'mock-refresh-${++_tokenCounter}';
    refreshTokens.add(token);
    _refreshRoles[token] = role;
    return token;
  }

  /// Olvida los códigos pedidos y los intentos fallidos. Las sesiones
  /// vigentes (refresh tokens) se conservan: restablecer los datos de prueba
  /// no debe cerrar la sesión de quien los está mirando.
  void resetCodes() {
    otpIssuedAt.clear();
    failedAttempts.clear();
  }
}
