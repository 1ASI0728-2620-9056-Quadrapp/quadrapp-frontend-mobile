import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Un nombre de dominio de correo («alumnos.universidad.edu»), en minúsculas
/// y sin `@` (docs/06: `institution_domains.domain`).
class DomainName extends Equatable {
  const DomainName._(this.value);

  /// Longitud máxima de la columna (docs/06).
  static const int maxLength = 120;

  // Etiquetas de letras, dígitos y guiones separadas por puntos; al menos dos.
  static final RegExp _shape = RegExp(
    r'^(?!-)[a-z0-9-]{1,63}(?<!-)(\.(?!-)[a-z0-9-]{1,63}(?<!-))+$',
  );

  /// El dominio, o `ValidationFailure` (`errors.domain`) si no tiene forma
  /// de dominio. Acepta que se escriba con `@` delante y en mayúsculas.
  static Result<DomainName> create(String raw) {
    var value = raw.trim().toLowerCase();
    if (value.startsWith('@')) value = value.substring(1);
    if (value.isEmpty || value.length > maxLength || !_shape.hasMatch(value)) {
      return const Err(
        ValidationFailure('El dominio no tiene un formato válido.', {
          'domain': ['invalid'],
        }),
      );
    }
    return Success(DomainName._(value));
  }

  final String value;

  /// ¿[email] es de este dominio (exactamente, no de un subdominio)?
  bool owns(String email) => email.toLowerCase().endsWith('@$value');

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

/// Un dominio de correo habilitado para la institución (US30). Queda
/// **pendiente** hasta que la plataforma lo verifique: mientras tanto nadie
/// entra con él.
class InstitutionDomain extends Equatable {
  const InstitutionDomain({
    required this.id,
    required this.name,
    this.verifiedAt,
  });

  final InstitutionDomainId id;
  final DomainName name;

  /// Cuándo lo verificó la plataforma (UTC); `null` si está pendiente.
  final DateTime? verifiedAt;

  bool get isVerified => verifiedAt != null;

  @override
  List<Object?> get props => [id.value, name, verifiedAt];
}
