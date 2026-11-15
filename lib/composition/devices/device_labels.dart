// US20, TS10
import 'package:quadrapp_mobile/composition/arrival/lot_age_text.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Debajo de este porcentaje la batería se muestra como baja (el diseño:
/// «batería por debajo del 20 %»).
const int lowBatteryPct = 20;

/// El tono de cada estado (con su ícono y su texto, nunca solo color).
QaTone deviceTone(DeviceStatus status) => switch (status) {
  DeviceStatus.operational => QaTone.free,
  DeviceStatus.lowBattery => QaTone.limited,
  DeviceStatus.unreachable => QaTone.full,
  DeviceStatus.decommissioned => QaTone.unknown,
};

String deviceStatusLabel(AppLocalizations l10n, DeviceStatus status) =>
    switch (status) {
      DeviceStatus.operational => l10n.devices_statusOperational,
      DeviceStatus.lowBattery => l10n.devices_statusLowBattery,
      DeviceStatus.unreachable => l10n.devices_statusUnreachable,
      DeviceStatus.decommissioned => l10n.devices_statusDecommissioned,
    };

String deviceTypeLabel(AppLocalizations l10n, DeviceType type) =>
    switch (type) {
      DeviceType.spaceSensor => l10n.devices_typeSpaceSensor,
      DeviceType.passSensor => l10n.devices_typePassSensor,
      DeviceType.gateway => l10n.devices_typeGateway,
    };

/// «C-023 · Sensor de espacio» o «G-03 · Gateway».
String deviceTitle(AppLocalizations l10n, Device device) {
  final place = device.spaceLabel;
  return place == null
      ? '${device.hardwareId} · ${deviceTypeLabel(l10n, device.type)}'
      : '${device.hardwareId} · ${l10n.devices_space(place)}';
}

/// «Batería 18 % · comunicación hace 4 min»; sin batería, «alimentación de
/// red»; sin reporte, «nunca reportó».
String deviceDetail(
  AppLocalizations l10n,
  DeviceInventory inventory,
  Device device,
  Clock clock,
) {
  final battery = device.batteryPct;
  final power = battery == null
      ? l10n.devices_mainsPower
      : l10n.devices_battery(battery);
  final age = inventory.lastSeenAge(device, clock);
  final seen = age == null
      ? l10n.devices_neverReported
      : l10n.devices_lastSeen(lotAgeText(l10n, age));
  return '$power · $seen';
}
