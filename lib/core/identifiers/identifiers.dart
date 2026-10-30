/// Identificadores tipados (`extension type` sobre `int`, BIGINT en docs/06)
/// para que no se mezcle, por ejemplo, un `LotId` con un `SpaceId`.
library;

/// Estacionamiento.
extension type const LotId(int value) {}

/// Zona de un estacionamiento (un pabellón o un área de la sede).
extension type const ZoneId(int value) {}

/// Nivel de una zona (un sótano o un piso).
extension type const LevelId(int value) {}

/// Espacio de un estacionamiento.
extension type const SpaceId(int value) {}

/// Usuario.
extension type const UserId(int value) {}

/// Institución (tenant).
extension type const InstitutionId(int value) {}

/// Suscripción a alertas por franja.
extension type const AlertSubscriptionId(int value) {}

/// Dispositivo del inventario (sensor o gateway).
extension type const DeviceId(int value) {}
