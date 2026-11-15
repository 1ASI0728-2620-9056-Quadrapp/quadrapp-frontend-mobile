import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Hora del servidor de referencia de las pruebas (UTC).
final DateTime serverTime = DateTime.utc(2026, 9, 28, 13, 42);

Device device(
  int id, {
  DeviceType type = DeviceType.spaceSensor,
  DeviceStatus status = DeviceStatus.operational,
  String? hardwareId,
  int? batteryPct = 80,
  Duration? seenAgo = const Duration(seconds: 20),
  String? spaceLabel,
  bool? directional,
}) => Device(
  id: DeviceId(id),
  lotId: const LotId(1),
  hardwareId: hardwareId ?? 'QS-L1-$id',
  type: type,
  status: status,
  expectedReportInterval: const Duration(seconds: 60),
  batteryPct: batteryPct,
  lastSeenAt: seenAgo == null ? null : serverTime.subtract(seenAgo),
  directional: directional,
  spaceLabel: spaceLabel,
);

DeviceInventory inventory(List<Device> devices, {Duration? receivedAt}) =>
    DeviceInventory(
      lotId: const LotId(1),
      devices: devices,
      serverTime: serverTime,
      receivedAt: receivedAt ?? Duration.zero,
    );

/// `GET /devices/health` con el formato de docs/07.
Map<String, dynamic> healthJson({List<Map<String, dynamic>>? devices}) => {
  'serverTime': '2026-09-28T13:42:00Z',
  'devices':
      devices ??
      [
        deviceJson(1, spaceLabel: 'A-01'),
        deviceJson(
          2,
          status: 'LOW_BATTERY',
          batteryPct: 9,
          spaceLabel: 'A-18',
        ),
        deviceJson(3, type: 'GATEWAY', batteryPct: null),
      ],
};

Map<String, dynamic> deviceJson(
  int id, {
  String type = 'SPACE_SENSOR',
  String status = 'OPERATIONAL',
  int? batteryPct = 80,
  String? lastSeenAt = '2026-09-28T13:41:40Z',
  String? spaceLabel,
}) => {
  'id': id,
  'hardwareId': 'QS-L1-$id',
  'type': type,
  'status': status,
  'batteryPct': ?batteryPct,
  'lastSeenAt': ?lastSeenAt,
  'expectedReportIntervalSec': 60,
  'spaceLabel': ?spaceLabel,
};
