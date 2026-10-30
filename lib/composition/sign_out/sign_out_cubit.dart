// US02
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/sign_out/sign_out.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Cierra la sesión llamando a `composition/sign_out` (US02).
///
/// Estados: `ViewInitial` (sin hacer nada), `ViewLoading` (cerrando),
/// `ViewData(report)` (cerrada; `onSignedOut` ya avisó al router) y
/// `ViewError` (no debería ocurrir: `SignOut` nunca falla, pero la pantalla
/// no se queda sin salida si algo inesperado pasa).
class SignOutCubit extends Cubit<ViewState<SignOutReport>> {
  SignOutCubit({required this._signOut, required this._onSignedOut})
    : super(const ViewInitial());

  final SignOut _signOut;

  /// Avisa que la sesión terminó y el dispositivo quedó limpio (la app lleva a
  /// `/login`).
  final void Function() _onSignedOut;

  Future<void> signOut() async {
    if (state is ViewLoading) return;
    emit(const ViewLoading());
    final result = await _signOut(const SignOutParams());
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(ViewData(value));
        _onSignedOut();
      case Err(:final failure):
        emit(ViewError(failure));
    }
  }
}
