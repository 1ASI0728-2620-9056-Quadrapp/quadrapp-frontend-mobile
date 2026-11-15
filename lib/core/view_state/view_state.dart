import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';

/// Estado de una pantalla (docs/04, "Estado de pantalla"). Todos los Cubits
/// exponen un `ViewState` y los widgets lo recorren con un `switch`
/// exhaustivo, así ninguna pantalla se queda sin uno de los 5 estados.
///
/// Es Dart puro: no importa Flutter ni bloc.
sealed class ViewState<T> extends Equatable {
  const ViewState();

  @override
  List<Object?> get props => const [];
}

/// Antes de empezar a cargar.
final class ViewInitial<T> extends ViewState<T> {
  const ViewInitial();
}

/// Cargando: la pantalla muestra un skeleton (no un spinner de pantalla
/// completa). Si ya había datos que seguir mostrando (un formulario que se
/// envía, una lista que se refresca), vienen en [previous].
final class ViewLoading<T> extends ViewState<T> {
  const ViewLoading({this.previous});

  final T? previous;

  @override
  List<Object?> get props => [previous];
}

/// Sin datos: estado vacío que invita a actuar.
final class ViewEmpty<T> extends ViewState<T> {
  const ViewEmpty();
}

/// Éxito. [stale] indica que el dato superó su vigencia y [offline] que viene
/// de la caché por falta de conexión.
final class ViewData<T> extends ViewState<T> {
  const ViewData(this.data, {this.stale = false, this.offline = false});

  final T data;
  final bool stale;
  final bool offline;

  @override
  List<Object?> get props => [data, stale, offline];
}

/// El servidor respondió pero faltó una sección ([missing]), o la pantalla
/// solo puede usarse en parte (por ejemplo, un botón bloqueado por una cuenta
/// regresiva).
final class ViewPartial<T> extends ViewState<T> {
  const ViewPartial(this.data, {this.missing = const {}});

  final T data;
  final Set<String> missing;

  @override
  List<Object?> get props => [data, missing];
}

/// Error recuperable: la pantalla dice la causa según el tipo de [failure] y
/// ofrece una salida. El texto nunca sale de `failure.message`. [previous]
/// conserva lo que ya se mostraba (por ejemplo, el formulario).
final class ViewError<T> extends ViewState<T> {
  const ViewError(this.failure, {this.previous});

  final Failure failure;
  final T? previous;

  @override
  List<Object?> get props => [failure, previous];
}
