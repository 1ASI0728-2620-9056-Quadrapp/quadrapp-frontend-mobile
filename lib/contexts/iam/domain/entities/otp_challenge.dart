// US01
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/email_address.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// El código de un solo uso que el servidor envió al correo, con su vigencia
/// (US01 esc. 1). La vigencia se cuenta con el reloj monótono local, no con el
/// del teléfono.
class OtpChallenge extends Equatable {
  const OtpChallenge({
    required this.email,
    required this.expiresIn,
    required this.receivedAt,
  });

  final EmailAddress email;

  /// Vigencia del código desde que el servidor lo emitió.
  final Duration expiresIn;

  /// Lectura del reloj monótono al recibir la respuesta.
  final Duration receivedAt;

  /// Cuánto le queda al código; nunca negativo.
  Duration remaining(Clock clock) {
    final elapsed = clock.monotonic() - receivedAt;
    final left = expiresIn - (elapsed.isNegative ? Duration.zero : elapsed);
    return left.isNegative ? Duration.zero : left;
  }

  bool isExpired(Clock clock) => remaining(clock) == Duration.zero;

  @override
  List<Object?> get props => [email, expiresIn, receivedAt];
}
