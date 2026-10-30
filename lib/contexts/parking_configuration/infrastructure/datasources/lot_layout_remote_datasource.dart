import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/lot_layout_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Resultado de pedir la distribución con una versión conocida.
sealed class LayoutFetch {
  const LayoutFetch();
}

/// 304: la copia local sigue vigente.
final class LayoutNotModified extends LayoutFetch {
  const LayoutNotModified();
}

/// 200: distribución nueva (o la primera).
final class LayoutFetched extends LayoutFetch {
  const LayoutFetched(this.dto);

  final LotLayoutDto dto;
}

/// Origen remoto de la distribución (HTTP o mock).
// ignore: one_member_abstracts
abstract interface class LotLayoutRemoteDataSource {
  /// Con [knownVersion] pide `If-None-Match: "v<version>"`.
  Future<LayoutFetch> fetch(LotId lotId, {int? knownVersion});
}
