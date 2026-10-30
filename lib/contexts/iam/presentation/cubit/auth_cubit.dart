// US01 (esc. 6), US02, US03
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/restore_session.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/session.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Si hay una sesión en este dispositivo. No es el estado de una pantalla
/// (no usa `ViewState`): lo lee el router para decidir adónde ir.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

/// Todavía se está leyendo la sesión guardada (la app muestra un skeleton).
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

/// Hay una sesión vigente (con cualquier rol: la app siempre muestra la
/// experiencia de conductor).
final class Authenticated extends AuthState {
  const Authenticated(this.session);

  final Session session;

  @override
  List<Object?> get props => [session];
}

/// No hay sesión: el router manda a `/login`.
final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Estado de sesión de la app. Restaura la sesión guardada al arrancar (sin
/// pedir un código nuevo ni llamar al servidor, US01 esc. 6) y la cambia
/// cuando alguien inicia o termina la sesión.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required this._restoreSession}) : super(const AuthUnknown());

  final RestoreSession _restoreSession;

  /// Lee la sesión guardada. Un error de lectura se trata como "sin sesión":
  /// es lo seguro (pide iniciar sesión de nuevo).
  Future<void> restore() async {
    final session = (await _restoreSession(const NoParams())).valueOrNull;
    if (isClosed) return;
    emit(session == null ? const Unauthenticated() : Authenticated(session));
  }

  /// El usuario inició sesión con un código válido.
  void sessionStarted(Session session) => emit(Authenticated(session));

  /// La sesión terminó (cierre pedido o expiración); el dispositivo ya está
  /// limpio.
  void sessionEnded() => emit(const Unauthenticated());
}
