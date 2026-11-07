import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';

/// Resultado de una operación: éxito con un valor o error con una [Failure].
sealed class Result<T> extends Equatable {
  const Result();

  /// Atajo para un éxito.
  static Result<T> success<T>(T value) => Success(value);

  /// Atajo para un error.
  static Result<T> failure<T>(Failure failure) => Err(failure);

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Err<T>;

  /// El valor si es un éxito; `null` si es un error.
  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    Err<T>() => null,
  };

  /// La falla si es un error; `null` si es un éxito.
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    Err<T>(:final failure) => failure,
  };

  R fold<R>(
    R Function(T value) onSuccess,
    R Function(Failure failure) onFailure,
  ) {
    return switch (this) {
      Success<T>(:final value) => onSuccess(value),
      Err<T>(:final failure) => onFailure(failure),
    };
  }

  /// Transforma el valor de un éxito; un error pasa igual.
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T>(:final value) => Success(transform(value)),
      Err<T>(:final failure) => Err(failure),
    };
  }

  /// Encadena otra operación que también puede fallar.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    return switch (this) {
      Success<T>(:final value) => transform(value),
      Err<T>(:final failure) => Err(failure),
    };
  }
}

/// Éxito con un [value].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  List<Object?> get props => [value];
}

/// Error con una [failure].
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
