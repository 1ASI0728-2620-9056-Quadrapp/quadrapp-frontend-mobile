import 'package:quadrapp_mobile/core/result/result.dart';

/// Un caso de uso: una clase, una intención, un solo método público (`call`).
// ignore: one_member_abstracts
abstract interface class UseCase<T, P> {
  Future<Result<T>> call(P params);
}

/// Parámetro de los casos de uso que no reciben nada.
final class NoParams {
  const NoParams();
}
