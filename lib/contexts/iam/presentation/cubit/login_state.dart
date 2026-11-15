// US01 (esc. 1, 4, 5), TS01 (esc. 1, 2)
import 'package:equatable/equatable.dart';

/// Por qué el campo de correo no es válido (se valida al salir del campo).
enum EmailFieldError { empty, invalid }

/// Datos de `/login` mientras se puede editar. El estado de la pantalla es un
/// `ViewState<LoginForm>`:
///
/// - `ViewData`: formulario listo, con o sin [emailError].
/// - `ViewLoading`: se está pidiendo el código.
/// - `ViewPartial`: bloqueado por demasiadas solicitudes (429), con
///   [blockedFor] como cuenta regresiva.
/// - `ViewError`: el servidor o la red fallaron (403, 400, red, 5xx).
///
/// El correo escrito vive en el campo de texto, no aquí: así nunca pasa por un
/// estado que pueda registrarse.
class LoginForm extends Equatable {
  const LoginForm({this.emailError, this.blockedFor});

  final EmailFieldError? emailError;

  /// Cuánto falta para poder pedir otro código; `null` si no está bloqueado.
  final Duration? blockedFor;

  @override
  List<Object?> get props => [emailError, blockedFor];
}
